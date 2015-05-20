function precomputations(subjnum,analysis,ngroups_max,varargin)

% subjnum = 101, ngroups_max = 5000, varargin={}

%% parse inputs

% optional arguments
pairs = {'searchlight_radius'    3    % radius of sphere (smallest = radius 1 = one voxel)
         'penalty'               1    % regularization penalty for logistic regression
         'dozscore'              1    % whether to zscore
         'smoothedEPIs'          0 }; % whether to use smoothed EPIs
parseargs(varargin,pairs);

% if rondo/della, convert string inputs to numbers
if isrondo || isdella
    str2num_set('subjnum','ngroups_max','searchlight_radius','penalty','dozscore','smoothedEPIs')
end

% print parsed inputs
fprintf('subjnum: %i\n',subjnum)
fprintf('analysis: %s\n',analysis)
fprintf('searchlight_radius: %i\n',searchlight_radius)
fprintf('penalty: %g\n',penalty)
fprintf('dozscore: %i\n',dozscore)
fprintf('smoothedEPIs: %i\n',smoothedEPIs)

%% filepaths

datadir = sprintf('../../data/SFR%i',subjnum);

%% load wholebrain mask

fprintf('==> loading brain mask... \n')

brainmask = load_nifti(fullfile(datadir,'mask_wholebrain.nii'));
brainmask = logical(brainmask);
nvox = sum(brainmask(:));

%% pre-compute the spheres around each voxel

fprintf('==> computing voxel spheres... \n')

voxel_spheres = compute_spheres(brainmask,brainmask,searchlight_radius);

%% assign voxels to groups

fprintf('==> assign voxels to groups... \n')
nvox_eachgroup = ceil(nvox/ngroups_max);
ngroups = ceil(nvox/nvox_eachgroup);
groups.starts = (0:ngroups-1) * nvox_eachgroup + 1;
groups.ends = (1:ngroups) * nvox_eachgroup;
groups.ends(end) = nvox;

%% save info for the batch

fprintf('==> save batch info... \n')

% directory for saving
basedir = get_basedir(analysis,searchlight_radius,penalty,dozscore,subjnum);
outdir = fullfile(basedir,'precomputations');
mkdir_ifnotexist(outdir)

% print out ngroups to a text file (to be read by submit_searchlight_2.sh)
fid = fopen(fullfile(outdir,'groupstats.sh'),'w');
fprintf(fid,'ngroups=%i\n',ngroups);
fprintf(fid,'nvox=%i\n',nvox);
fclose(fid); 

% save group info
volume_size = size(brainmask);
save(fullfile(outdir,'groupinfo'),'groups','voxel_spheres','volume_size')

% save masks
save(fullfile(outdir,'masks'),'brainmask')

