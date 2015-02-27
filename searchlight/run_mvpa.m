function [] = run_mvpa(args)

%% set paths

data_dir = sprintf('../data/CLO%i',args.subjID);

%% initialize the 'subj' structure

subj = init_subj(args.analysis,args.subjID);

%% load a mask 

maskname = ['mask_searchlight%i' args.groupnum];

subj = init_object(subj,'mask',maskname);
subj = set_mat(subj,'mask',maskname,args.mask);

%% load selectors (run 1, run 2, etc)

runsname = ['runs_' args.runs];
load(fullfile(data_dir,runsname))

selsname = 'runs';
subj = init_object(subj,'selector',selsname);
subj = set_mat(subj,'selector',selsname,runs); 
clear runs

%% load conditions (regressors)
% 3 conditions: C,L,O  

load(fullfile(data_dir,args.regs))
regsname = 'conds';
subj = init_object(subj,'regressors',regsname);
subj = set_mat(subj,'regressors',regsname,regs);
clear regs

condnames = {'celebrities','locations','objects'};
subj = set_objfield(subj,'regressors',regsname,'condnames',condnames);

%% shift or convolve regressors
% to account for hemodynamic lag
% ( regsname => regsname_convolved OR regsname_shX )

subj = shift_regressors(subj,regsname,selsname,args.shiftTRs);
regsname = sprintf('%s_sh%i',regsname,args.shiftTRs);

%% create no_rest selector
% => actives_selsname  ( a separate selector from 'runs' )

subj = create_norest_sel(subj,regsname);
actives_selname = [regsname '_norest'];

%% load the EPI data

epiname = 'epi';
subj = load_spm_pattern(subj,epiname,maskname,...
    fullfile(data_dir,'filtered_func_data.nii'));

%% no spatial smoothing

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
%     => xvalnames{icond} = selector group selsname_xvalcond$icond
% OR  => xvalname = selector selsname_xval

subj = create_xvalid_indices(subj,selsname,...
    'actives_selname',actives_selname);
xvalname = [selsname '_xval'];

%% no feature selection

featselname = maskname;

%% classification

class_args.train_funct_name = 'train_logreg';
class_args.test_funct_name = 'test_logreg';
class_args.penalty = args.penalty;

[subj results] = cross_validation(subj,epiname,regsname,...
    xvalname,featselname,class_args);

%% save results

results_name = sprintf('vox%i_%s',args.ivox,datestr(now,'mmddyy_HHSS'));
results_dir = sprintf('../results/radius%i/penalty%g/CLO%i/%s/searchlights/%s',...
    args.searchlight_radius,args.penalty,args.subjID,args.analysis,results_name);
mkdir_ifnotexist(results_dir);

save(fullfile(results_dir,'args'),'args')
save(fullfile(results_dir,'results'),'results')
