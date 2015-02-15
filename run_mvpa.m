function [] = run_mvpa(args,results_name)
% INPUTS:
% args.subjID
% args.runs         - which runs file to use? 
% args.regs         - which regs file to use?
% args.anovathresh - threshold for feature selection
% args.shiftTRs    - # TRs to shift (to account for hemodynamic lag)
% args.zscore       - whether or not to use z-scoring (0|1)
% args.fwhm         - FWHM for spatially smoothing the EPI
% args.mask         - mask should be named 'mask_maskname.nii'
% 
% ARGS FOR CLASSIFIER:
% args.classifier   - 'L2logreg','logreg','bp','gnb', or 'ridge'
% args.penalty      - only for some classifiers
% 
% OPTIONAL INPUTS:
% results_name      - name of directory storing MVPA results


%% basics

% path to data
data_dir = fullfile('../data',args.subjID);

% nsectors
nsectors = 4;

%% initialize the 'subj' structure

subj = init_subj(args.analysis,args.subjID);

%% load a mask 

maskname = ['mask_' args.mask];
switch args.mask
    case {'special_maskXX'}
        load(fullfile(data_dir,maskname));
        subj = init_object(subj,'mask',maskname);
        subj = set_mat(subj,'mask',maskname,mask);
        clear mask
    otherwise
        subj = load_spm_mask(subj,maskname,...
            fullfile(data_dir,[maskname '.nii']));
end

% wholevol = ones(64,64,36);
% subj = init_object(subj,'mask',maskname);
% subj = set_mat(subj,'mask',maskname,wholevol);
%% load selectors (run 1, run 2, etc)

if isempty(args.runs)
    runsname = 'runs';
else
    runsname = ['runs_' args.runs];
end 
load(fullfile(data_dir,runsname)) % load 'runs'

selsname = 'runs';
subj = init_object(subj,'selector',selsname);
subj = set_mat(subj,'selector',selsname,runs); 

% % for blocking out unwanted TRs, e.g. CT for FRonly
% blocker_selsname = 'blocker';
% blocker = zeros(size(runs));
% blocker(runs~=100) = 1;
% subj = init_object(subj,'selector',blocker_selsname);
% subj = set_mat(subj,'selector',blocker_selsname,blocker);

%% load regressors
% posteriors for the 4 sectors

load(fullfile(data_dir,args.regs))
regsname = 'posteriors';
subj = init_object(subj,'regressors',regsname);
subj = set_mat(subj,'regressors',regsname,regs);
clear regs

%% shift or convolve regressors
% to account for hemodynamic lag
% ( regsname => regsname_convolved OR regsname_shX )

if strcmp(args.shiftTRs,'convolve')
    HRF = spm_hrf(args.info.TR);
    curr_regs = get_mat(subj,'regressors',regsname);
    [ncond nTR] = size(curr_regs);
    for isector = 1:ncond
        convolved(isector,:) = conv(curr_regs(isector,:),HRF);
    end
    convolved = convolved(:,1:nTR);
    
    regsname = sprintf('%s_convolved',regsname);
    subj = initset_object(subj,'regressors',regsname,convolved);
    
    clear curr_regs convolved
else
    subj = shift_regressors(subj,regsname,selsname,args.shiftTRs);
    regsname = sprintf('%s_sh%i',regsname,args.shiftTRs);
end

%% create no_rest selector
% => actives_selsname  ( a separate selector from 'runs' )

subj = create_norest_sel(subj,regsname);
actives_selname = [regsname '_norest'];

%% load the EPI data

epiname = 'epi';
subj = load_spm_pattern(subj,epiname,maskname,...
    fullfile(data_dir,'big4D_mc_fmu_runs.nii'));

%% (spatially) smooth the functional data
% with Gaussian filter
% epiname => epiname_smXX

if args.fwhm~=0
    subj = smooth_pattern(subj,epiname,args.fwhm,1);
    subj = remove_mat(subj,'pattern',epiname); % remove the unsmoothed pattern from memory
    %subj = move_pattern_to_hd(subj, epiname);
    epiname = sprintf('%s_sm%d',epiname,args.fwhm);
end

%% z-score the functional data
% for each voxel: normalize timecourse to mean 0 and variance 1
% epiname => epiname_z

if args.zscore == 1
    subj = zscore_runs(subj,epiname,selsname);
    subj = remove_mat(subj,'pattern',epiname); % remove the un-zscored pattern from memory
    %subj = move_pattern_to_hd(subj, epiname);
    epiname = [epiname '_z'];
end

%% make cross-validation indices for inner loops
%     => xvalnames{isector} = selector group selsname_xvalcond$isector
% OR  => xvalname = selector selsname_nested_xval

subj = create_nested_xvalid_indices(subj,selsname,...
    'actives_selname',actives_selname);
innerxvalname = [selsname '_nested_xval'];

%% make cross-validation indices for outer loop
%     => xvalnames{isector} = selector group selsname_xvalcond$isector
% OR  => xvalname = selector selsname_xval

subj = create_xvalid_indices(subj,selsname,...
    'actives_selname',actives_selname);
%     'actives_selname',{actives_selname,blocker_selsname});
outerxvalname = [selsname '_xval'];

% ungroup 
% (so that can be entered separately to feature_select and cross_validation)
for iter = unique(runs)
    subj = set_objfield(subj,...
        'selector',sprintf('%s_%i',outerxvalname,iter),...
        'group_name',sprintf('%s_%i',outerxvalname,iter),...
        'ignore_absence',true);
end

%% separate regressors
% necessary for some things

if ismember('corr',args.featsel_types)
    subj = separate_regressors(subj,regsname);
    for isector = 1:nsectors
        regsnames_separated{isector} = sprintf('%s_%i',regsname,isector);
    end
end

%% model-selection (find best parameters) on inner xvalidation loops

% for each inner loop
results_inner = nan(length(unique(runs)),...
    length(args.penalty_multipliers),...
    length(args.featsel_types),...
    length(args.featsel_threshes));
best_setting = nan(1,max(unique(runs)));
for r_outer = unique(runs)
    setting.xvalname = sprintf('%s_%i',innerxvalname,r_outer);
    
    % iterate parameter settings and run xvalidation on each setting
    for i_pm = 1:length(args.penalty_multipliers) % penalty multiplier
        setting.penalty_multiplier = args.penalty_multipliers(i_pm);
        
        for i_ftype = 1:length(args.featsel_types) % feature selection type
            setting.featsel_type = args.featsel_types{i_ftype};
            
            if strcmp(setting.featsel_type,'none')
                error('no need to iterate over thresholds -- write this code')
            else
                for i_fthresh = 1:length(args.featsel_threshes) % feature selection threshold
                    setting.featsel_thresh = args.featsel_threshes(i_fthresh); 
                    
                    % run xvalidation on the settings
                    disp(setting)
                    run_xvalidation;
                    
                    % save the mean performance for this setting
                    tempresults = nan(1,nsectors);
                    for isector = 1:nsectors
                        tempresults(isector) = results{isector}.total_perf;
                    end
                    results_inner(r_outer,i_pm,i_ftype,i_fthresh) = mean(tempresults);
                    
                    % clean up subj and other variables
                    for isector = 1:nsectors
                        subj = remove_group(subj,'pattern',sprintf('stat_sector%i',isector));
                        subj = remove_group(subj,'mask',sprintf('featselmask_sector%i',isector));
                    end
                    clear featselname featselnames nvox results
                end
            end
        end
    end
    
    % find the best setting
    [~, best_setting(r_outer)] = max(vert(results_inner(r_outer,:,:,:)));
end

%% do cross-validation on the outer loop, using the best settings from the inner loop

% get the best setting for each r_outer
clear setting
for r_outer = unique(runs)
    [i_pm, i_ftype, i_fthresh] = ind2sub([length(args.penalty_multipliers),...
        length(args.featsel_types),...
        length(args.featsel_threshes)],...
        best_setting(r_outer));
    
    setting(r_outer).penalty_multiplier = args.penalty_multipliers(i_pm);
    setting(r_outer).featsel_type = args.featsel_types{i_ftype};
    setting(r_outer).featsel_thresh = args.featsel_threshes(i_fthresh);
    
    setting(r_outer).xvalname = sprintf('%s_%i',outerxvalname,r_outer);
end

% run xvalidation
run_xvalidation

% save the results
results_outer = results;
clear results

%% make plots for results

makefigs = 0;
if makefigs
    fig1 = mvpa_confusion_matrix(results,condnames);
    fig2 = mvpa_plot_v_time(results,condnames);
    
    saveas(fig1,fullfile(results_dir,'confusion_matrix.fig'))
    saveas(fig2,fullfile(results_dir,'timeplot.fig'))
end

%% save results

% results_name
full_results_name = sprintf('%s_%s',datestr(now,'mmddyy_HHSS'),results_name);

% results_dir
results_dir = sprintf('../results/mvpa_results/%s/%s',args.subjID, full_results_name);
mkdir_ifnotexist(results_dir)

% remove the functional pattern, which is large
subj = remove_mat(subj,'pattern',epiname);

% save args, subj, results_inner, results_outer
save(fullfile(results_dir,'args'),'args')
save(fullfile(results_dir,'subj'),'subj')
save(fullfile(results_dir,'results_inner'),'results_inner')
save(fullfile(results_dir,'results_outer'),'results_outer')

% save figures
if makefigs
    saveas(fig1,fullfile(results_dir,'confusion_matrix.eps'))
    saveas(fig2,fullfile(results_dir,'timeplot.eps'))
end