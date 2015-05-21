function logregMAPoutputs_vs_posterior(subjnum,multinomial,varargin)

%% parse inputs

% optional arguments
pairs = {'searchlight_radius'    3   % radius of sphere (smallest = radius 1 = one voxel)
         'penalty'               1   % regularization penalty
         'dozscore'              1}; % whether to zscore
parseargs(varargin,pairs);

%% set path

addpath('../searchlight')

%% load the results

% results directory
if multinomial
    analysis = 'logregMAPmulti';
else
    analysis = 'logregMAP';
end
basedir = get_basedir(analysis,searchlight_radius,penalty,dozscore,subjnum);

% load transformed results
logreg_outputs = load_nifti(fullfile(basedir,'transformed.nii.gz'));

%% load the posteriors

% load corrected behavioral data
behav_data_file = sprintf('../../../5_analyze_behavioral_data/results/rescore/subj%i',subjnum);
load(behav_data_file)

% load the posteriors
posteriors = [stimlist.trials.posteriors_new{episess}];
posteriors = vertcat(posteriors{:});

%% look at correlation between logreg 

% Spearman correlation (only care about rank-order)
Scorr = diag(corr(posteriors',logreg_outputs','type','Spearman'));

% Pearson correlation
Pcorr = diag(corr(posteriors',logreg_outputs','type','Pearson'));