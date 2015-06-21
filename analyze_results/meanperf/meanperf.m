% Get mean performance, across LOO iterations and subsampling iterations
function meanperf(subjnum,varargin)

%% parse inputs

% optional arguments
pairs = {'analysis'              'logregMAP'
         'searchlight_radius'    3   % radius of sphere (smallest = radius 1 = one voxel)
         'penalty'               1   % regularization penalty
         'dozscore'              1   % whether to zscore
         'mask'             'MAPconjunction/thresh0.95'
         'niters'               10   % number of subsampling iterations
         'chance'               0.25};
parseargs(varargin,pairs);

%% get results directory

addpath('../searchlight')

basedir = get_basedir(analysis,searchlight_radius,penalty,dozscore,brainmask,subjnum);

%% load results

for iter = 1:niters
    load(sprintf('%s/allvoxels%i.mat',basedir,iter))
    results(iter,:) = voxels_meanperf;
end

%% get meanperf for each voxel

voxelmeans = mean(results,1);

figure; hold on
hist(voxelmeans,20)
drawacross('v',chance,'r--')