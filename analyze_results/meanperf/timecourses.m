% plot the classifier output as a function of time
function timecourses(subjnum,varargin)

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

%% fixed params

ncat = 4;
colors = [0 0 1;
      0 0.5 0;
      1 0 0;
      0 0.75 0.75;
      0.75 0 0.75;
      0.75 0.75 0;
      0.25 0.25 0.25];
set(groot,'defaultAxesColorOrder',colors)

%% load results

% get nvox
groupinfo = load(fullfile(basedir,'precomputations','groupinfo.mat'));
nvox = groupinfo.groups.ends(end);

% load results for all voxels
logreg_outputs = cell(niters,nvox);
for iter = 1 %:niters
    for v = 16 %:nvox
        voxdir = dir_filenames(sprintf('%s/searchlights_iter%i/vox%i_*',basedir,iter,v),1,1);
        voxresults = load(fullfile(voxdir,'results.mat'));
        nfolds = length(voxresults.results.iterations);
        
        for fold = 3 %:nfolds
            desireds = voxresults.results.iterations(fold).perfmet.desireds;
            acts = voxresults.results.iterations(fold).acts;
            
            figure; hold on
            for cat = 1:4
                cat_timepoints = find(desireds == cat);
                plot(cat_timepoints,0.9*ones(size(cat_timepoints)),'.',...
                    'MarkerFaceColor',colors(cat,:),...
                    'MarkerEdgeColor',colors(cat,:))
            end
            plot(acts')
            
            
        end
    end
end
