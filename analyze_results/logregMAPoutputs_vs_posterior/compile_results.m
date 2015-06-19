subjnums = setdiff(101:134, [101 111 121:130]);
nsubj = length(subjnums);

subjmeans = nan(nsubj,2);
for isubj = 1:nsubj
    subjnum = subjnums(isubj);
    load(sprintf('../../results/analyze_results/logregMAPoutputs_vs_posterior/subj%i_meanScorr.mat',subjnum))
    
    hist(meanScorr)
    
    subjmeans(isubj,:) = mean(meanScorr)
    [~,p] = ttest(meanScorr)
    
    pause
end