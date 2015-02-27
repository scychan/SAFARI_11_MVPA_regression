function precomputations(subjnum,ngroups_max,varargin)

% subjnum = 101, ngroups_max = 5000, varargin={}

%% parse inputs

% optional arguments
pairs = {'searchlight_radius'    3    % radius of sphere (smallest = radius 1 = one voxel)
         'penalty'               1};  % regularization penalty for logistic regression
parseargs(varargin,pairs);

% if rondo/della, convert string inputs to numbers
if isrondo || isdella
    str2num_set('subjnum','ngroups_max')
    if any(strcmp(varargin,'searchlight_radius'))
    	str2num_set('searchlight_radius')
    end
    if any(strcmp(varargin,'penalty'))
    	str2num_set('penalty')
    end
end

% print parsed inputs
fprintf('subjnum: %i\n',subjnum)
fprintf('searchlight_radius: %i\n',searchlight_radius)
fprintf('penalty: %g\n',penalty)

%% filepaths

datadir = sprintf('../../data/SFR%i',subjnum);

%% load wholebrain mask

fprintf('==> loading brain mask... \n')

brainmask = load_nifti(fullfile(datadir,'mask_wholebrain.nii'));
brainmask = logical(brainmask);

%% sample every other voxel from the mask

fprintf('==> making checkermask... \n')

% checkerboard for the whole volume
checkerboard = zeros(size(brainmask));
for i = 1:size(brainmask,1)
    for j = 1:size(brainmask,2)
        for k = 1:size(brainmask,3)
            if mod(i+j+k,2)
                checkerboard(i,j,k) = 1;
            end
        end
    end
end

% conjunction of checkerboard and brainmask
checkermask = brainmask & checkerboard;
nvox = sum(checkermask(:));

%% pre-compute the spheres around each voxel

fprintf('==> computing voxel spheres... \n')

voxel_spheres = compute_spheres(brainmask,checkermask,searchlight_radius);

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
outdir = sprintf('../../results/radius%i/penalty%g/SFR%i/precomputations',...
    searchlight_radius,penalty,subjnum);
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
save(fullfile(outdir,'masks'),'brainmask','checkermask')

