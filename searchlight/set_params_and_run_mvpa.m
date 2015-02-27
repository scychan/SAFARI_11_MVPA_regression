function set_params_and_run_mvpa(subjnum,analysis,varargin)

% optional arguments
pairs = {'searchlight_radius'    2    % radius of sphere (smallest = radius 1 = one voxel)
         'penalty'               0    % regularization penalty for logistic regression
         'groupnum'              []   % can manually enter, when not submitting array jobs
         'voxels_to_run'         []}; % can manually override the "groups" settings
parseargs(varargin,pairs);

% if rondo/della, convert string inputs to numbers
if isrondo || isdella
    str2num_set('subjnum')
    need_to_convert = {'searchlight_radius','penalty','groupnum','voxels_to_run'};
    for inputstrnum = 1:length(need_to_convert)
        inputstr = need_to_convert{inputstrnum};
        if any(strcmp(varargin,inputstr))
            str2num_set(inputstr)
        end
    end
end

% get Rondo/Della array task ID #
if isempty(groupnum) && isempty(voxels_to_run) %#ok<NODEF>
    if isrondo
        groupnum = eval(getenv('SGE_TASK_ID'));
    elseif isdella
        groupnum = eval(getenv('SLURM_ARRAY_TASK_ID'));
    else
        error('need groupnum or voxels_to_run');    
    end
end

% print parsed inputs
fprintf('subjnum: %i\n',subjnum)
fprintf('analysis: %s\n',analysis)
fprintf('groupnum: %i\n',groupnum)

% save to args
args.subjID = subjnum;
args.analysis = analysis;
args.searchlight_radius = searchlight_radius;
args.penalty = penalty;
args.groupnum = groupnum;

%% add MVPA toolbox to the path

if isdella
    addpath(genpath('~/matlab/packages/mvpa'))
end

%% set all other args
% options:  current_category
%           preceding_category

% EPI info
args.info.TR = 2;

% preproc
args.zscore = 1;
args.shiftTRs = 2;

% selectors
args.runs = 'FRonly_xvalid';
switch args.analysis
    case 'CLO_current_category'
        args.regs = 'regs_FRonly';
    case 'CLO_preceding_category'
        args.regs = 'regs_FRonly_ABinC12';
end

% classifier
args.penalty = penalty;


%% display 'args'

disp('args =')
disp(args)

%% get group info
% load: groups, volume_size, voxel_spheres

load(sprintf('../results/radius%i/penalty%g/CLO%i/precomputations/groupinfo',...
    searchlight_radius,penalty,subjnum))

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
