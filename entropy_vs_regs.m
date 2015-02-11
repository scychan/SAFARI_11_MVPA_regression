% compute correlation / relationship between entropy and latent-cause
% regressors

%% 

subjnums = setdiff(101:134,[111 128]);
nsubj = length(subjnums);
nsectors = 4;

addpath('helpers')

%% load the p(latent cause) posterior regressors

regs = cell(1,nsubj);
for isubj = 1:nsubj;
    subj = subjnums(isubj);
    tempload = load(sprintf('../results/regressors/SFR%i/regs',subj));
    regs_sum = sum(tempload.regs);
    regs{isubj} = tempload.regs(:,regs_sum > 0);
end

%% compute the entropy at each timepoint

entropy = cell(1,nsubj);
for isubj = 1:nsubj
    T = size(regs{isubj},2);
    entropy{isubj} = nan(1,T);
    for t = 1:T
        entropy{isubj}(t) = compute_entropy(regs{isubj}(:,t));
    end
end

%% compute correlation

corrtypes = {'Pearson','Spearman'};
corrs = nan(length(corrtypes),nsubj,nsectors);
for ict = 1:length(corrtypes)
    corrtype = corrtypes{ict};
    for isubj = 1:nsubj
        entropy_series = entropy{isubj};
        for isector = 1:nsectors
            regs_series = regs{isubj}(isector,:);
            corrs(ict,isubj,isector) = corr(entropy_series',regs_series','type',corrtype);
        end
    end
end