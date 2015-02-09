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


%% set paths

data_dir = fullfile('/Users/yenne/mnt/scratch/scychan/SAFARI/11_MVPA_regression/data',args.subjID); % XX
% data_dir = fullfile('/home/scychan/mnt/scratch/scychan/SAFARI/11_MVPA_regression/data',args.subjID); % XX

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
load(fullfile(data_dir,runsname))

selsname = 'runs';
subj = init_object(subj,'selector',selsname);
subj = set_mat(subj,'selector',selsname,runs); 
clear runs

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

%% make cross-validation indices
%     => xvalnames{isector} = selector group selsname_xvalcond$isector
% OR  => xvalname = selector selsname_xval

subj = create_xvalid_indices(subj,selsname,...
    'actives_selname',actives_selname);
%     'actives_selname',{actives_selname,blocker_selsname});
xvalname = [selsname '_xval'];

%% separate regressors
% necessary for some things

if strcmp(args.featsel_type,'corr')
    subj = separate_regressors(subj,regsname);
    for isector = 1:4
        regsnames_separated{isector} = sprintf('%s_%i',regsname,isector);
    end
end

%% feature selection
% use the same selectors that will be used in cross-validation
% => featselname OR featselnames{isector}

switch args.featsel_type
    case 'none'
        %== No feature selection ==%
        featselname = maskname;
        
    case 'corr'
        %== Correlation-based feature selection ==%
        for isector = 1:4
            subj = feature_select(subj,epiname, ...
                regsnames_separated{isector}, xvalname, ...
                'statmap_funct','statmap_xcorr', ...
                'statmap_arg', [], ...
                'new_map_patname', sprintf('stat_sector%i',isector), ...
                'thresh', []);
            featselnames{isector} = sprintf('featselmask_sector%i',isector);
            subj = create_sorted_mask(subj, sprintf('stat_sector%i',isector), featselnames{isector}, args.featsel_thresh,'descending',1);
        end
        
    case 'anova'
        %== ANOVA-based feature selection ==%
        subj = feature_select(subj,epiname,regsname,xvalname,...
            'thresh',args.featsel_thresh);
        featselname = [epiname '_thresh' num2str(args.anovathresh)];
end

%% classification

switch(args.classifier)
    
    case 'gnb'
        class_args.train_funct_name = 'train_gnb';
        class_args.test_funct_name = 'test_gnb';
        
    case 'bp'
        class_args.train_funct_name = 'train_bp';
        class_args.test_funct_name = 'test_bp';
        class_args.nHidden = 0;
        
    case 'L2logreg'
        class_args.train_funct_name = 'train_L2_RLR';
        class_args.test_funct_name = 'test_L2_RLR';
        class_args.penalty = args.penalty;
        class_args.lambda = 'crossvalidation'; % XX-- peeking??
        
    case 'logreg'
        class_args.train_funct_name = 'train_logreg';
        class_args.test_funct_name = 'test_logreg';
        class_args.penalty = args.penalty;
        
    case 'ridge'
        class_args.train_funct_name = 'train_ridge';
        class_args.test_funct_name = 'test_ridge';
        class_args.penalty = args.penalty;
        
    otherwise
        disp('(-) unknown classifier type!');
        return
        
end

if strcmp(args.classifier,'ridge')
    if strcmp(args.featsel_type,'corr')
        for isector = 1:4
            [subj results{isector}] = cross_validation(subj,epiname,regsnames_separated{isector},...
                xvalname,featselnames{isector},class_args,...
                'perfmet_functs','perfmet_xcorr');
        end
    else
        [subj results] = cross_validation(subj,epiname,regsname,...
            xvalname,featselname,class_args,...
            'perfmet_functs','perfmet_xcorr');
    end
else
    [subj results] = cross_validation(subj,epiname,regsname,...
                     xvalname,featselname,class_args);
end

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
if ~exist('results_name','var')
    results_name = 'results';
end
full_results_name = sprintf('%s_%s',datestr(now,'mmddyy_HHSS'),results_name);

% results_dir
results_dir = fullfile('../results/mvpa_results/',args.subjID,full_results_name)
mkdir_ifnotexist(results_dir)

% % clear the mask and the functional patterns, which are large
% subj = remove_mat(subj,'pattern',epiname);
% subj = remove_mat(subj,'mask',maskname);

save(fullfile(results_dir,'args'),'args')
% save(fullfile(results_dir,'subj'),'subj')
save(fullfile(results_dir,'results'),'results')

% saveas(fig1,fullfile(results_dir,'confusion_matrix.eps'))
% saveas(fig2,fullfile(results_dir,'timeplot.eps'))
