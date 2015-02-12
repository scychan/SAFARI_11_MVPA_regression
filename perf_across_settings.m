%% basics

resultsdir = '../results/mvpa_results';

%% get all setting values

% featselvals
featselvals_str = dir_filenames(resultsdir,1);
featselvals = nan(size(featselvals_str));
nfs = length(featselvals);
for ifs = 1:nfs
    featselvals(ifs) = str2double(featselvals_str{ifs}(8:end));
end

% penaltyvals
penaltyvals = cell(1,nfs);
for ifs = 1:nfs
    fs = featselvals(ifs);
    penaltyvals_str = dir_filenames(sprintf('%s/featsel%i',resultsdir,fs),1);
    penaltyvals{ifs} = nan(size(penaltyvals_str));
    for ip = 1:length(penaltyvals{ifs})
        penaltyvals{ifs}(ip) = str2double(penaltyvals_str{ip}(8:end));
    end
end

%% load meanperf for all settings

meanperf = cell(1,nfs);
for ifs = 1:nfs
    np = length(penaltyvals{ifs});
    meanperf{ifs} = nan(1,np);
    for ip = 1:np
        tmpload = load(sprintf('%s/featsel%i/penalty%g/meanperf',...
            resultsdir,featselvals(ifs),penaltyvals{ifs}(ip)));
        meanperf{ifs}(ip) = tmpload.meanperf;
    end
end

%% rank the settings

settings_all = [];
perf_all = [];
for ifs = 1:nfs
    np = length(penaltyvals{ifs});
    settings_all = [settings_all;
        [featselvals(ifs)*ones(np,1) penaltyvals{ifs}]];
    perf_all = [perf_all
        meanperf{ifs}'];
end
sorted = sortAbyv([settings_all, perf_all], perf_all);
