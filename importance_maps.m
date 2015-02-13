function importance_maps(featsel_thresh,penalty,subjnum)

%% basics

make_plots = 0;
niter = 4;
nsector = 4;
maskname = 'wholebrain';

% directories
data_dir = sprintf('../data/SFR%i',subjnum);
resultsdir = sprintf('../results/mvpa_results/featsel%i/penalty%g',featsel_thresh,penalty);
subjdir = dir_filenames(sprintf('%s/SFR%i/*_results',resultsdir,subjnum),1,1);

%% prep

if ~isrondo
    addpath(genpath('~/Dropbox/matlab/packages/mvpa'))
    addpath(genpath('~/Dropbox/matlab/packages/spm8'))
end

%% load MVPA results

tmpload = load(fullfile(subjdir,'results'));
iterations = cell(1,nsector);
for sector = 1:nsector
    iterations{sector} = tmpload.results{sector}.iterations;
end

% get the weights for all the iterations
nvox = length(iterations{1}(1).scratchpad.ridge.betas);
weights = nan(nvox,nsector,niter);
for sector = 1:nsector
    for iter = 1:niter
        weights(:,sector,iter) = iterations{sector}(iter).scratchpad.ridge.betas;
    end
end

% average over the iterations
weights = mean(weights,3);

%% histogram of weights

if make_plots
    figure
    for isector = 1:nsector
        subplot(nsector,1,isector)
        
        w = weights(:,isector);
        
        hist(w(w>0.01),20)
        %     set(gca,'xlim',clims)
        %     set(gca,'ylim',[0 30])
    end
end

%% load mask

mask_file = fullfile(data_dir,['mask_' maskname '.nii']);
mask = load_nifti(mask_file);

%% make plots (one for each category)
% average across iterations XX

nslices = size(mask,3);
nrows = floor(sqrt(nslices));
ncols = ceil(nslices/nrows);

for icat = 1:3
    
    catname = categories{icat};
    
    % un-mask the weights
    weights3D.(catname) = zeros(size(mask));
    weights3D.(catname)(mask==1) = weights(:,icat);
    
    if make_plots
        figure
        colormap('cool')
        
        for islice = 1:nslices
            
            subplot(nrows,ncols,islice)
            
            clims = [-0.015 0.015];
            % clims = [min(weights(:,icat)) max(weights(:,icat))];
            imagesc(weights3D.(catname)(:,:,islice),clims)
        end
    end
end

%% Get importance map

% Make importance maps in the style of McDuff et al (2009)
% (+) weight * (+) activity while regressor is on => (+) importance
% (-) weight * (-) activity while regressor is on => (-) importance
% Different signs => 0 importance

load(sprintf('../../../../mvpa_results/CLO%i/%s/args.mat',subjnum,datatype))

subj = set_up_subj(args);

patname = results.iterations(1).created.patname;
maskname = results.iterations(1).created.maskname;
regsname = results.iterations(1).created.regsname;

maskinfo = get_object(subj,'mask',maskname);
nvox = maskinfo.nvox;
importance_map_alliter = zeros(nvox,3,niter);

for iter = 1:niter
    
    selname = results.iterations(iter).created.selname;
    
    masked_pat  = get_masked_pattern(subj,patname,maskname);
    selectors   = get_mat(subj,'selector',selname);
    regressors  = get_mat(subj,'regressors',regsname);
    
    for icat = 1:3
        pats_to_avg  = masked_pat(:,regressors(icat,:)==1);
        avg_activity = mean(pats_to_avg,2);
        
        % positive quadrant
        posvoxels = weights(:,icat) > 0 & avg_activity > 0;
        importance_map_alliter(posvoxels,icat,iter) = weights(posvoxels,icat) .* avg_activity(posvoxels);
        
        % negative quadrant
        negvoxels = weights(:,icat) < 0 & avg_activity < 0;
        importance_map_alliter(negvoxels,icat,iter) = - weights(negvoxels,icat) .* avg_activity(negvoxels);
    end
    
end

importance_map = squeeze(mean(importance_map_alliter,3));

%% Histogram of the importance values

if make_plots
    figure
    for icat = 1:3
        subplot(3,1,icat)
        
        w = importance_map(:,icat);
        
        hist(w,20)
        %     hist(w(w>0.01),20)
        %     set(gca,'xlim',clims)
        %     set(gca,'ylim',[0 30])
    end
end

%% Plot importance map (one for each category)
% averaged across iterations

nslices = size(mask,3)
nrows = floor(sqrt(nslices));
ncols = ceil(nslices/nrows);

for icat = 1:3
    
    catname = categories{icat};
    
    % un-mask the importance map
    importance3D.(catname) = zeros(size(mask));
    importance3D.(catname)(mask==1) = importance_map(:,icat);
    
    if make_plots
        figure
        colormap('cool')
        
        for islice = 1:nslices
            
            subplot(nrows,ncols,islice)
            
            % clims = [-0.015 0.025];
            clims = [min(weights(:,icat)) max(weights(:,icat))];
            imagesc(importance3D.(catname)(:,:,islice),clims)
            %         imagesc(importance3D(:,:,islice))
        end
    end
end

%% compile everything
maps.(datatype).mask = mask;
maps.(datatype).weights = weights3D;
maps.(datatype).importances = importance3D;

%%
outdir = '../../../results/analyze_results/importance_maps/unnormalized';
mkdir_ifnotexist(outdir);
save(sprintf('%s/CLO%i',outdir,subjnum),'maps')
