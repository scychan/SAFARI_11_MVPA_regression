function voxel_spheres = compute_spheres(mask,centers,radius,varargin)
% Returns the indices corresponding to the spheres for each voxel in the
% mask
% 
% for testing:
% mask(:,:,1) = [0 1 1
%     1 0 1
%     0 1 1
%     1 1 1];
% mask(:,:,2) = ~mask;
% radius = 2;
% varargin = {'plot_sphere',1};

%% parse options
pairs = {'plot_sphere'  0};
parseargs(varargin,pairs)

%% basics

dims = size(mask);
maskinds = find(mask);

centerinds = find(centers);
nvox = sum(centers(:));

%% compute indices for every voxel in the volume

subs = cell(1,3);

subs{1} = repmat(vert(1:dims(1)),[1 dims(2) dims(3)]);
subs{1} = subs{1}(:);

subs{2} = repmat(1:dims(2),[dims(1) 1 dims(3)]);
subs{2} = subs{2}(:);

tempinds = nan(1,1,dims(3));
tempinds(:) = 1:dims(3);
subs{3} = repmat(tempinds,[dims(1) dims(2) 1]);
subs{3} = subs{3}(:);

%% compute relative inds for each voxel in the sphere
sphere = [];
zlim = radius - 1;
for z = -zlim:zlim
    xlim = radius - abs(z) - 1;
    for x = -xlim:xlim
        ylim = xlim - abs(x);
        for y = -ylim:ylim
            sphere = [sphere; x y z];
        end
    end
end
spheresize = size(sphere,1);

% plot the sphere
if plot_sphere
    figure
    zvals = -zlim:zlim;
    nsubplots = length(zvals);
    for isubplot = 1:nsubplots
        z = zvals(isubplot);
        [m,n] = subplot_square(nsubplots,isubplot);
        zvoxels = sphere(sphere(:,3)==z,:);
        scatter(zvoxels(:,1),zvoxels(:,2))
        title(sprintf('z = %i',z))
    end
    equalize_subplot_axes('xy',gcf,m,n,1:nsubplots)
end
    

%% compute the sphere around every voxel

voxel_spheres = cell(nvox,1);
if plot_sphere
    figure(101); figuresize('fullscreen')
    colormap('bone')
end
for ivox = 1:nvox
    % which voxel in the mask
    voxelind = centerinds(ivox);
    voxelsubs = [subs{1}(voxelind) subs{2}(voxelind) subs{3}(voxelind)];
    % compute sphere around the voxel
    voxel_sphere = repmat(voxelsubs,spheresize,1) + sphere;
    % remove invalid points outside volume
    for idim = 1:3
        invalid = voxel_sphere(:,idim) < 1 | voxel_sphere(:,idim) > dims(idim);
        voxel_sphere(invalid,:) = [];
    end
    % convert to inds
    voxel_sphere = sub2ind(dims,voxel_sphere(:,1),...
        voxel_sphere(:,2),...
        voxel_sphere(:,3));
    % remove invalid voxels outside mask
    voxel_sphere = intersect(voxel_sphere,maskinds);
    % plot sphere
    if plot_sphere && ismultiple(ivox-1,100)
        figure(101)
        volume = zeros(size(mask));
        volume(mask) = 0.5;
        volume(voxel_sphere) = 1;
        nsubplots = size(volume,3);
        for isubplot = 1:nsubplots
            subplot_square(nsubplots,isubplot);
            imagesc(volume(:,:,isubplot))
        end
        pause(0.05)
    end
    % save to cell
    voxel_spheres{ivox} = voxel_sphere;
end