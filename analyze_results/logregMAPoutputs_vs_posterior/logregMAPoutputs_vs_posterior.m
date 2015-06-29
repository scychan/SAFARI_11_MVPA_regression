function logregMAPoutputs_vs_posterior(subjnum,varargin)

%% parse inputs

% optional arguments
pairs = {'searchlight_radius'    3   % radius of sphere (smallest = radius 1 = one voxel)
         'penalty'               1   % regularization penalty
         'dozscore'              1   % whether to zscore
         'mask'             'wholebrain'
	 'iteration'             []};
parseargs(varargin,pairs);

str2num_set('subjnum','searchlight_radius','penalty','dozscore','iteration')

%% set path

addpath('../searchlight')

%% load the results

% results directory
analysis = 'logregMAP';
basedir = get_basedir(analysis,searchlight_radius,penalty,dozscore,mask,subjnum);

% get nvox
groupinfo = load(fullfile(basedir,'precomputations','groupinfo.mat'));
nvox = groupinfo.groups.ends(end);

% load results for all voxels
logreg_outputs = cell(1,nvox);
for v = 1:nvox
    if isempty(iteration)
        voxdir = dir_filenames(sprintf('%s/searchlights/vox%i_*',basedir,v),1,1);
    else
        voxdir = dir_filenames(sprintf('%s/searchlights_iter%i/vox%i_*',basedir,iteration,v),1,1);
    end
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
fprintf('\n computing correlations... ')
for v = 1:nvox
    if mod(v,100)==0
        fprintf('%i... ',v)
    end
    firstTRs = logreg_outputs{v}(:,1:2:end);
    secondTRs = logreg_outputs{v}(:,2:2:end);
    meanScorr(v,1) = mean(diag(corr(posteriors',firstTRs,'type','Spearman')));
    meanScorr(v,2) = mean(diag(corr(posteriors',secondTRs,'type','Spearman')));
end

%% save the results

outdir = '../../results/analyze_results/logregMAPoutputs_vs_posterior'
mkdir_ifnotexist(outdir)
save(sprintf('%s/subj%i_meanScorr',outdir,subjnum), 'meanScorr')

% XX hist(meanScorr(:))

% Pearson correlation
% XX Pcorr = diag(corr(posteriors',logreg_outputs','type','Pearson'));
