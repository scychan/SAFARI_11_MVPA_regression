function importance_maps(featsel_thresh,penalty,subjnum)

%% basics

make_plots = 0;
niter = 4;
nsector = 4;

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
iterations = cell(niter,nsector);
for iter = 1:niter
    for sector = 1:nsector
        iterations{iter,sector} = tmpload.results{iter,sector}.iterations;
    end
end

% get the weights for all the iterations
weights = cell(1,niter);
for iter = 1:niter
    nvox = length(iterations{iter,1}.scratchpad.ridge.betas);
    weights{iter} = nan(nsector,nvox);
    for sector = 1:nsector
        weights{iter}(sector,:) = iterations{iter,sector}.scratchpad.ridge.betas;
    end
end

% average over the iterations
% weights = mean(weights,3); XX

%% histogram of weights

if make_plots
    figure
    for iter = 1:niter
        for isector = 1:nsector
            subplot_ij(niter,nsector,iter,isector)
            w = weights{iter}(isector,:);
            hist(w(w~=0),10)
            %     set(gca,'xlim',clims)
            %     set(gca,'ylim',[0 30])
        end
    end
    equalize_subplot_axes('xy',gcf,niter,nsector,'r')
end

%% make plots (one for each category)
% average across iterations XX

% nslices = size(mask,3);
% nrows = floor(sqrt(nslices));
% ncols = ceil(nslices/nrows); XX

for iter = 1:niter
    for isector = 1:nsector
        
        % get the mask
        maskname = sprintf('featselmask_iter%i_sector%i_1',iter,isector);
        mask = get_mat(subj,'mask',maskname);
        nslices = size(mask,3);
        
        % un-mask the weights
        weights3D{iter,isector} = zeros(size(mask));
        weights3D{iter,isector}(mask==1) = weights{iter}(isector,:);
        
        if make_plots
            figure; figuresize('fullscreen')
            colormap('cool')
            for islice = 1:nslices
                subplot_square(nslices,islice)
                clims = [-0.015 0.015];
                % clims = [min(weights(:,icat)) max(weights(:,icat))];
                imagesc(weights3D{iter,isector}(:,:,islice),clims)
            end
        end
    end
end

%% Get importance map

% Make importance maps in the style of McDuff et al (2009)
% (+) weight * (+) activity while regressor is on => (+) importance
% (-) weight * (-) activity while regressor is on => (-) importance
% Different signs => 0 importance

importance_maps = cell(1,niter);
for iter = 1:niter
    for isector = 1:nsector
        
        patname = results{iter,isector}.iterations.created.patname;
        maskname = results{iter,isector}.iterations.created.maskname;
        selname = results{iter,isector}.iterations.created.selname;
        
        maskname = sprintf('featselmask_iter%i_sector%i_1',iter,isector);
        maskinfo = get_object(subj,'mask',maskname);
        nvox = maskinfo.nvox;
        importance_maps{iter,isector} = zeros(1,nvox);
        
        masked_pat  = get_masked_pattern(subj,patname,maskname);
        selectors   = get_mat(subj,'selector',selname);
        pats_to_avg  = masked_pat(:,selectors==1);
        avg_activity = horz(mean(pats_to_avg,2));
        
        % positive quadrant
        posvoxels = weights{iter}(isector,:) > 0 & avg_activity > 0;
        importance_maps{iter,isector}(posvoxels) = weights{iter}(isector,posvoxels) .* avg_activity(posvoxels);
        
        % negative quadrant
        negvoxels = weights{iter}(isector,:) < 0 & avg_activity < 0;
        importance_maps{iter,isector}(negvoxels) = - weights{iter}(isector,negvoxels) .* avg_activity(negvoxels);
    end
end

%% Histogram of the importance values

if make_plots
    figure
    for iter = 1:niter
        for isector = 1:nsector
            subplot_ij(niter,nsector,iter,isector)
            w = importance_maps{iter,isector};
            hist(w(w~=0),10)
            %     set(gca,'xlim',clims)
            %     set(gca,'ylim',[0 30])
        end
    end
    equalize_subplot_axes('xy',gcf,niter,nsector,'r')
end

%% Plot importance map (one for each iter and each sector)
% averaged across iterations XX

for iter = 1:niter
    for isector = 1:nsector
        
        % get mask
        maskname = sprintf('featselmask_iter%i_sector%i_1',iter,isector);
        mask = get_mat(subj,'mask',maskname);
        nslices = size(mask,3);
        
        % un-mask the importance map
        importance3D{iter,isector} = zeros(size(mask));
        importance3D{iter,isector}(mask==1) = importance_maps{iter,isector};
        
        if make_plots
            figure; figuresize('fullscreen')
            colormap('cool')
            for islice = 1:nslices
                subplot_square(nslices,islice)
                % clims = [-0.015 0.015];
                clims = [min(importance_maps{iter,isector}), max(importance_maps{iter,isector})];
                imagesc(importance3D{iter,isector}(:,:,islice),clims)
            end
        end
    end
end

%% compile everything XX
% maps.(datatype).mask = mask;
% maps.(datatype).weights = weights3D;
% maps.(datatype).importances = importance3D;

%% save maps XX
% outdir = '../../../results/analyze_results/importance_maps/unnormalized';
% mkdir_ifnotexist(outdir);
% save(sprintf('%s/CLO%i',outdir,subjnum),'maps')
