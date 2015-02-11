function set_params_and_run(subjID,results_name,varargin)

%% parse inputs

pairs = {
    'featsel_thresh'         7000
    'penalty_multiplier'     0.05
    }; parseargs(varargin,pairs);
str2num_set('featsel_thresh','penalty_multiplier')

%% add MVPA toolbox to path

if ~isrondo
    addpath(genpath('~/Dropbox/matlab/packages/mvpa'))
    addpath(genpath('~/Dropbox/matlab/packages/spm8'))
end

%% hard code for now

args.subjID = subjID;
args.analysis = 'basic';
args.mask = 'wholebrain';

args.runs = '';
args.regs = 'regs';

args.shiftTRs = 2;
args.fwhm = 0;
args.zscore = 1;

args.featsel_type = 'corr';
args.featsel_thresh = featsel_thresh;

args.classifier = 'ridge';
args.penalty = penalty_multiplier * args.featsel_thresh;

%% display 'args'

disp('args =')
disp(args)

%% run mvpa using the settings

run_mvpa(args,results_name)
