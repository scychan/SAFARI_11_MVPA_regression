function perf_across_subjs(featsel_thresh,penalty,varargin)

pairs = {'subjnums'   setdiff(101:132,[111 128])...
    }; parseargs(varargin,pairs)

%% basics

nsubj = length(subjnums);
nsector = 4;

%% load the data

resultsdir = sprintf('../results/mvpa_results/featsel%i/penalty%g',featsel_thresh,penalty);
results = cell(1,nsubj);
for isubj = 1:nsubj
    subj = subjnums(isubj);
    subjdir = dir_filenames(sprintf('%s/SFR%i/*_results',resultsdir,subj),1,1);
    tmpload = load(fullfile(subjdir,'results'));
    results{isubj} = tmpload.results;
end

%% compile avg performance for each subject and each sector

perf = nan(nsubj,nsector);
for isubj = 1:nsubj
    for isector = 1:nsector
        perf(isubj,isector) = results{isubj}{isector}.total_perf;
    end
end

%% plot histograms for each sector separately

figure
for isector = 1:nsector
    [m,n] = subplot_square(nsector,isector);
    hist(perf(:,isector),-0.3:0.05:0.6)
    [~,p] = ttest(perf(:,isector));
    titlebf(sprintf('Sector %i.  meanperf = %.2f.  p = %.2g',isector,mean(perf(:,isector)),p))
end
equalize_subplot_axes('xy',gcf,m,n)
for isector = 1:nsector
    subplot_square(nsector,isector);
    hold on
    drawacross('v',0,'k--',2)
    drawacross('v',mean(perf(:,isector)),'r--')
end
suptitle(sprintf('Mean across sectors = %.2f',mean(perf(:))))

%% save meanperf

meanperf = mean(perf(:));
save(fullfile(resultsdir,'meanperf'),'meanperf')