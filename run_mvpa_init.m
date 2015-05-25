function [] = run_mvpa_init(args,results_name)
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

% path to tempdata dir
tempdata_dir = fullfile('../tempdata',args.subjID);
mkdir_ifnotexist(tempdata_dir);

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

%% save necessary info for next steps 

% save the workspace
save(fullfile(tempdata_dir,'init_workspace'))

% save n_inner_loops
n_inner_loops = prod([length(unique(runs)),...
    length(args.penalty_multipliers),...
    length(args.featsel_types),...
    length(args.featsel_threshes)]);
fid = fopen(fullfile(tempdata_dir,'n_inner_loops.txt'),'w');
fprintf(fid,'%i',n_inner_loops)
fclose('all');