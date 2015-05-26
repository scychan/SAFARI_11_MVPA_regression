function logregMAPoutputs_vs_posterior(subjnum,multinomial,varargin)

%% parse inputs

% optional arguments
pairs = {'searchlight_radius'    3   % radius of sphere (smallest = radius 1 = one voxel)
         'penalty'               1   % regularization penalty
         'dozscore'              1   % whether to zscore
         'mask'             'wholebrain'};
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
basedir = get_basedir(analysis,searchlight_radius,penalty,dozscore,mask,subjnum);

% get nvox
groupinfo = load(fullfile(basedir,'precomputations','groupinfo.mat'));
nvox = groupinfo.groups.ends(end);

% load results for all voxels
logreg_outputs = cell(1,nvox);
for v = 1:nvox
    voxdir = dir_filenames(sprintf('%s/searchlights/vox%i_*',basedir,v),1,1);
    voxresults = load(fullfile(voxdir,'results.mat'));
    logreg_outputs{v} = horzcat(voxresults.results.iterations.acts);
end

%% load the posteriors

% load corrected behavioral data
behav_data_file = sprintf('../../../5_analyze_behavioral_data/results/rescore/subj%i',subjnum);
load(behav_data_file)

% load the posteriors
episess = 10:13;
posteriors = [stimlist.trials.posteriors_new{episess}];
posteriors = vertcat(posteriors{:});

%% look at correlation between logreg 

% Spearman correlation (only care about rank-order)
meanScorr = nan(nvox,2);
for v = 1:nvox
    disp(v)
    firstTRs = logreg_outputs{v}(:,1:2:end);
    secondTRs = logreg_outputs{v}(:,2:2:end);
    meanScorr(v,1) = mean(diag(corr(posteriors',firstTRs,'type','Spearman')));
    meanScorr(v,2) = mean(diag(corr(posteriors',secondTRs,'type','Spearman')));
end

hist(meanScorr(:))

% Pearson correlation
Pcorr = diag(corr(posteriors',logreg_outputs','type','Pearson'));
