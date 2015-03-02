function [] = run_mvpa(args)

%% set paths

data_dir = sprintf('../../data/SFR%i',args.subjID);

%% initialize the 'subj' structure

subj = init_subj(args.analysis,args.subjID);

%% load a mask 

maskname = ['mask_searchlight%i' args.groupnum];

subj = init_object(subj,'mask',maskname);
subj = set_mat(subj,'mask',maskname,args.mask);

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

%% load conditions (regressors)

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

%% spatial smoothing

if args.fwhm~=0
    subj = smooth_pattern(subj,epiname,args.fwhm,1);
    subj = remove_mat(subj,'pattern',epiname); % remove the unsmoothed pattern from memory
    epiname = sprintf('%s_sm%d',epiname,args.fwhm);
end

%% z-score the functional data
% for each voxel: normalize timecourse to mean 0 and variance 1
% epiname => epiname_z

if args.zscore == 1
    subj = zscore_runs(subj,epiname,selsname);
    subj = remove_mat(subj,'pattern',epiname); % remove the un-zscored pattern from memory
    epiname = [epiname '_z'];
end

%% make cross-validation indices
%     => xvalnames{icond} = selector group selsname_xvalcond$icond
% OR  => xvalname = selector selsname_xval

subj = create_xvalid_indices(subj,selsname,...
    'actives_selname',actives_selname);
xvalname = [selsname '_xval'];

%% no feature selection

featselname = maskname;

%% classification

% get class_args
switch(args.classifier)
    case 'gnb'
        class_args.train_funct_name = 'train_gnb';
        class_args.test_funct_name = 'test_gnb';
        perfmet_func = 'perfmet_maxclass';
    case 'bp'
        class_args.train_funct_name = 'train_bp';
        class_args.test_funct_name = 'test_bp';
        class_args.nHidden = 0;
        perfmet_func = 'perfmet_maxclass';
    case 'L2logreg'
        class_args.train_funct_name = 'train_L2_RLR';
        class_args.test_funct_name = 'test_L2_RLR';
        class_args.penalty = args.penalty;
        class_args.lambda = 'crossvalidation'; % XX-- peeking??
        perfmet_func = 'perfmet_maxclass';
    case 'logreg'
        class_args.train_funct_name = 'train_logreg';
        class_args.test_funct_name = 'test_logreg';
        class_args.penalty = args.penalty;
        perfmet_func = 'perfmet_maxclass';
    case 'ridge'
        class_args.train_funct_name = 'train_ridge';
        class_args.test_funct_name = 'test_ridge';
        class_args.penalty = args.penalty;
        perfmet_func = 'perfmet_xcorr';
    otherwise
        disp('(-) unknown classifier type!');
        return
end

[subj results] = cross_validation(subj,epiname,regsname,...
    xvalname,featselname,class_args,...
    'perfmet_functs',perfmet_func);

%% save results

results_name = sprintf('vox%i_%s',args.ivox,datestr(now,'mmddyy_HHSS'));
results_dir = sprintf('../../results/searchlights/radius%i/penalty%g/SFR%i/searchlights/%s',...
    args.searchlight_radius,args.penalty,args.subjID,results_name);
mkdir_ifnotexist(results_dir);

save(fullfile(results_dir,'args'),'args')
save(fullfile(results_dir,'results'),'results')
