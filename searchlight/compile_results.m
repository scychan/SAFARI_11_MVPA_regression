function compile_results(subjnum,analysis,varargin)
% subjnum = 109, analysis = 'CLO_current_category', varargin = {};

%% parse inputs

% optional arguments
pairs = {'searchlight_radius'    2   % radius of sphere (smallest = radius 1 = one voxel)
         'penalty'               0   % regularization penalty
         'wholebrain'            0}; % whether the searchlight was performed with a whole-brain mask
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
    if any(strcmp(varargin,'wholebrain'))
    	str2num_set('wholebrain')
    end
end

% print parsed inputs
fprintf('subjnum: %i\n',subjnum)
fprintf('analysis: %s\n',analysis)
fprintf('searchlight_radius: %i\n',searchlight_radius)
fprintf('penalty: %g\n',penalty)

%% basics

% path to results
resultsdir = sprintf('../results/radius%i/penalty%g/CLO%i',searchlight_radius,penalty,subjnum);

% expt design
nlist = 12;
nMitems = 6;
ncat = 3;

%% load masks

if wholebrain
    if ~exist(fullfile(resultsdir,'precomputations/masks_wholebrain.mat'),'file')
        movefile(fullfile(resultsdir,'precomputations/masks.mat'),...
            fullfile(resultsdir,'precomputations/masks_wholebrain.mat'));
    end
    load(fullfile(resultsdir,'precomputations/masks_wholebrain'))
else
    load(fullfile(resultsdir,'precomputations/masks'))
end
nvox = sum(checkermask(:));

if ~wholebrain ( nvox > 20000 || exist(fullfile(resultsdir,'precomputations/masks_wholebrain.mat'),'file'))
    error('are you sure it''s not wholebrain...?')
end

%% load MVPA results for every voxel

% load MVPA results for every voxel
voxels_meanperf = nan(nvox,1);
tic
for ivox = 1:nvox
    if mod(ivox,100)==0
        toc, ivox %#ok<NOPRT>
    end
    
    % load results
    voxdir = dir_filenames(sprintf('%s/%s/searchlights/vox%i_*',resultsdir,analysis,ivox),1,1);
    load(fullfile(voxdir,'results'))
    
    % for each list...
    correct = nan(nlist,nMitems);
    for ilist = 1:nlist
        
        % figure out the correct categories
        switch analysis
            case 'CLO_current_category'
                M_TRs = [5 6 11 12 17 18 23 24 29 30 35 36];
                desireds = results.iterations(ilist).perfmet.desireds(M_TRs);
            case 'CLO_preceding_category'
                desireds = results.iterations(ilist).perfmet.desireds(2*(1:nMitems));
                catsinplay = unique(desireds);
                other = nan(1,nMitems);
                for M = 1:nMitems
                    other(M) = setdiff(catsinplay,desireds(M));
                end
        end
        
        % get M-item activations (averaged across the two TRs)
        Macts = nan(ncat,nMitems);
        for M = 1:nMitems
            switch analysis
                case 'CLO_current_category'
                    Mitem_TRs = [-1 0] + 6*M;
                case 'CLO_preceding_category'
                    Mitem_TRs = [-1 0] + 2*M;
            end
            Macts(:,M) = mean(results.iterations(ilist).acts(:,Mitem_TRs),2);
        end
        
        % which are correct?
        for M = 1:nMitems
            switch analysis
                case 'CLO_current_category'
                    if length(unique(Macts(:,M))) == 1 % all are the same
                        correct(ilist,M) = 1/3;
                    elseif length(unique(Macts(:,M))) == 2 % two are the same
                        correct(ilist,M) = 1/2*(Macts(desireds(M),M) == max(Macts(:,M)));
                    else % all are different
                        correct(ilist,M) = (Macts(desireds(M),M) == max(Macts(:,M)));
                    end
                case 'CLO_preceding_category'
                    if Macts(desireds(M),M) == Macts(other(M),M) % the two are the same
                        correct(ilist,M) = 1/2;
                    else
                        correct(ilist,M) = Macts(desireds(M),M) > Macts(other(M),M);
                    end
            end
        end
    end
        
    voxels_meanperf(ivox) = mean(correct(:));
    clear results
end

%% save as nifti

% compile results into a volume
compiled = nan(size(checkermask));
compiled(checkermask) = voxels_meanperf;

% save nifti
voxelsize = [3 3 3];
if wholebrain
    save_nifti(compiled,fullfile(resultsdir,analysis,'compiled_wholebrain.nii.gz'),voxelsize);
else
    save_nifti(compiled,fullfile(resultsdir,analysis,'compiled.nii.gz'),voxelsize);
end

%% save matlab files

if wholebrain
    save(fullfile(resultsdir,analysis,'allvoxels_wholebrain'),...
        'voxels_meanperf','compiled')
else
    save(fullfile(resultsdir,analysis,'allvoxels'),...
        'voxels_meanperf','compiled')
end

