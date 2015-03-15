function compile_results(subjnum,varargin)
% subjnum = 101, varargin = {};

%% parse inputs

% optional arguments
pairs = {'searchlight_radius'    3   % radius of sphere (smallest = radius 1 = one voxel)
         'penalty'               1   % regularization penalty
         'zscore'                1}; % whether to zscore
parseargs(varargin,pairs);

% if rondo/della, convert string inputs to numbers
if isrondo || isdella
    str2num_set('subjnum','searchlight_radius','penalty','zscore')
end

% print parsed inputs
fprintf('subjnum: %i\n',subjnum)
fprintf('searchlight_radius: %i\n',searchlight_radius)
fprintf('penalty: %g\n',penalty)
fprintf('zscore: %g\n',zscore)

%% basics

% path to results
basedir = get_basedir(searchlight_radius,penalty,zscore,subjnum);
resultsdir = basedir;

%% load masks

load(fullfile(resultsdir,'precomputations/masks'))
nvox = sum(checkermask(:));

%% load MVPA results for every voxel

% load MVPA results for every voxel
voxels_meanperf = nan(nvox,1);
tic
for ivox = 1:nvox
    if mod(ivox,100)==0
        toc, ivox %#ok<NOPRT>
    end
    
    % load results
    voxdir = dir_filenames(sprintf('%s/searchlights/vox%i_*',resultsdir,ivox),1,1);
    load(fullfile(voxdir,'results'))
        
    % save to voxels_meanperf
    voxels_meanperf(ivox) = results.total_perf;
    clear results
end

%% save as nifti

% compile results into a volume
compiled = nan(size(checkermask));
compiled(checkermask) = voxels_meanperf;

% save nifti
voxelsize = [3 3 3];
save_nifti(compiled,fullfile(resultsdir,'compiled.nii.gz'),voxelsize);

%% save matlab files

save(fullfile(resultsdir,'allvoxels'),...
    'voxels_meanperf','compiled')

