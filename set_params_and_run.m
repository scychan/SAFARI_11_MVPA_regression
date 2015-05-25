function set_params_and_run(subjID,results_name)

%% add MVPA toolbox to path

if ~isrondo
    addpath(genpath('~/Dropbox/matlab/packages/mvpa'))
    addpath(genpath('~/Dropbox/matlab/packages/spm8'))
end

%% params to optimize over

args.featsel_types = {'corr'};
args.featsel_threshes = [100,500,1000,5000,10000];

args.penalty_multipliers = [0,0.01,0.05,0.1,0.5];

%% hard code for now

args.subjID = subjID;
args.analysis = 'basic';
args.mask = 'wholebrain';

args.runs = '';
args.regs = 'regs';

args.shiftTRs = 2;
args.fwhm = 0;
args.zscore = 1;

args.classifier = 'ridge';

%% display 'args'

disp('args =')
disp(args)

%% run mvpa using the settings

if ~exist('results_name','var')
    results_name = 'results';
end
run_mvpa_init(args,results_name)
