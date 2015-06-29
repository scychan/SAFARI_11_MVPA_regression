% plot classifier performance -- distribution across voxels
% all subjects in one figure

subjnums = setdiff(101:134,[101 110 121:124 126 111 128]);
nsubj = length(subjnums);

figure
figuresize('fullscreen')

for isubj = 1:nsubj
    subjnum = subjnums(isubj);
    
    subplot_square(nsubj,isubj)
    meanperf(subjnum)
    title(sprintf('SFR%i',subjnum))
end