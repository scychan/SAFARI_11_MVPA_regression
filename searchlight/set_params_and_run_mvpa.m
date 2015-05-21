function set_params_and_run_mvpa(subjnum,analysis,varargin)

% optional arguments
pairs = {'searchlight_radius'    3          % radius of sphere (smallest = radius 1 = one voxel)
         'penalty'               1          % regularization penalty for ridge regression
         'dozscore'              1          % whether to zscore
         'groupnum'              []         % can manually enter, when not submitting array jobs
         'voxels_to_run'         []};       % can manually override the "groups" settings
parseargs(varargin,pairs);

% convert string inputs to numbers, if necessary
str2num_set('subjnum','searchlight_radius','penalty','dozscore','groupnum','voxels_to_run')

% get Rondo/Della array task ID #
if isempty(groupnum) && isempty(voxels_to_run) %#ok<NODEF>
    if isrondo || isdella
        groupnum = gettaskID;
    else
        error('need groupnum or voxels_to_run');    
    end
end

% print parsed inputs
fprintf('subjnum: %i\n',subjnum)
fprintf('groupnum: %i\n',groupnum)

% save to args
args.subjID = subjnum;
args.searchlight_radius = searchlight_radius;
args.analysis = analysis;
args.penalty = penalty;
args.zscore = dozscore;
args.groupnum = groupnum;

%% add MVPA toolbox to the path

if isdella
    addpath(genpath('~/matlab/packages/mvpa'))
end

%% set analysis-dependent args

switch analysis
    
    case 'ridge'
        args.classifier = 'ridge';
        
    case 'logregMAPmulti'
        args.classifier = 'L2logreg';
end

args.runs = '';
args.regs = ['regs_' analysis];

%% set all other args

args.subjID = subjnum;
args.analysis = analysis;
args.mask = 'wholebrain';

args.shiftTRs = 2;
args.fwhm = 0;

args.penalty = penalty;

%% EPI info
args.info.TR = 2;

%% display 'args'

disp('args =')
disp(args)

%% get group info
% load: groups, volume_size, voxel_spheres

basedir = get_basedir(analysis,searchlight_radius,penalty,dozscore,subjnum);
load(fullfile(basedir,'precomputations/groupinfo'))

if isempty(voxels_to_run) %#ok<NODEF>
    voxels_to_run = groups.starts(groupnum) : groups.ends(groupnum);
end

%% iterate through all the voxels/searchlights in the group

for ivox = voxels_to_run
    fprintf('ivox %i...\n',ivox)
    %% set mask
    
    args.ivox = ivox;
    
    args.mask = zeros(volume_size);
    args.mask(voxel_spheres{ivox}) = 1;
    
    %% run mvpa using the settings
    
    run_mvpa(args)
end
