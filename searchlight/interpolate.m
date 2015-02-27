function interpolate(subjnum,analysis,varargin)
% INPUTS
% subjnum - e.g. 109
% analysis - e.g. 'CLO_preceding_category'
% 
% EXAMPLE
% subjnum = 109, analysis = 'CLO_current_category', varargin = {}

%% parse inputs

% optional arguments
pairs = {'searchlight_radius'    2          % radius of sphere (smallest = radius 1 = one voxel)
	 'penalty'               0          % regularization penalty
         'interpolate_method'    'linear'   % method of interpolation ('linear' or 'spline')
         'visualize'             0};        % show visualization
parseargs(varargin,pairs);

% if rondo/della, convert string inputs to numbers
if isrondo || isdella
    str2num_set('subjnum')
    if any(strcmp(varargin,'searchlight_radius'))
    	str2num_set('searchlight_radius')
    end
    if any(strcmp(varargin,'penalty'))
    	str2num_set('penalty')
    end
end

% print parsed inputs
fprintf('subjnum: %i\n',subjnum)
fprintf('analysis: %s\n',analysis)
fprintf('searchlight_radius: %i\n',searchlight_radius)

% set path
addpath('helpers')

%% load searchlight results and masks

resultsdir = sprintf('../results/radius%i/penalty%g/CLO%i',searchlight_radius,penalty,subjnum);

% load
load(fullfile(resultsdir,'precomputations','masks'))
load(fullfile(resultsdir,analysis,'allvoxels'),'voxels_meanperf')

% basics
nvox_checker = length(voxels_meanperf);
checkermask_inds = find(checkermask);
[checkermask_subs.x, checkermask_subs.y, checkermask_subs.z] = ind2sub(size(checkermask),checkermask_inds);
brainmask_inds = find(brainmask);
[brainmask_subs.x, brainmask_subs.y, brainmask_subs.z] = ind2sub(size(brainmask),brainmask_inds);

%% figure out which voxels need to be filled in

% which voxels need to be filled in
tofill = brainmask - checkermask;
tofill_inds = find(tofill);
[tofill_subs.x, tofill_subs.y, tofill_subs.z] = ind2sub(size(tofill),tofill_inds);
nvox_fill = length(tofill_inds);

%% re-zero -- everything relative to chance

switch analysis
    case 'CLO_current_category'
        chance = 1/3;
    case 'CLO_preceding_category'
        chance = 1/2;
end

voxels_meanperf = voxels_meanperf - chance;

%% interpolate

% first fill in actual values
checker_perf = zeros(size(brainmask));
checker_perf(checkermask_inds) = voxels_meanperf;

% interpolate
switch interpolate_method
    case 'linear'        
        F = scatteredInterpolant(checkermask_subs.x, checkermask_subs.y, checkermask_subs.z, ...
            voxels_meanperf,'linear');
        interpolated_vals = F(brainmask_subs.x, brainmask_subs.y, brainmask_subs.z);
        
        interpolated = zeros(size(brainmask));
        interpolated(brainmask_inds) = interpolated_vals;
        
    case 'spline'
        error('not yet written')
end

%% visualize 

if visualize
    figure
    for i = 1:34;
        subplot(321);
        imagesc(squeeze(checker_perf(:,:,i)));
        title(num2str(i));
        subplot(323);
        imagesc(squeeze(checker_perf(:,:,i+1)));
        subplot(325);
        imagesc(squeeze(checker_perf(:,:,i+2)));
        subplot(322);
        imagesc(squeeze(interpolated(:,:,i)),[0 0.7]);
        subplot(324);
        imagesc(squeeze(interpolated(:,:,i+1)),[0 0.7]);
        subplot(326);
        imagesc(squeeze(interpolated(:,:,i+2)),[0 0.7]);
        pause;
    end
end
%% save as nifti

voxelsize = [3 3 3];

save_nifti(interpolated,fullfile(resultsdir,analysis,'interpolated.nii.gz'),voxelsize);

%% save the result

params = var2struct(subjnum,analysis,searchlight_radius,interpolate_method); %#ok<NASGU>
save(fullfile(resultsdir,analysis,'interpolated.mat'),...
    'params','interpolated')