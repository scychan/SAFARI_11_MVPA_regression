function run_mvpa_inner_loops(subjID)

%% load workspace from run_mvpa_init

tempdata_dir = fullfile('../tempdata',subjID);
load(fullfile(tempdata_dir,'init_workspace'))

%% figure out which settings to use

% get Rondo/Della task ID
taskID = gettaskID;

% get indices for settings
[r_outer, i_pm, i_ftype, i_fthresh] = ind2sub([length(unique(runs)),...
    length(args.penalty_multipliers),...
    length(args.featsel_types),...
    length(args.featsel_threshes)],...
    taskID);

% load actual settings
setting.xvalname = sprintf('%s_%i',innerxvalname,r_outer);
setting.penalty_multiplier = args.penalty_multipliers(i_pm);
setting.featsel_type = args.featsel_types{i_ftype};
setting.featsel_thresh = args.featsel_threshes(i_fthresh);
disp(setting)

%% run xvalidation on this setting

run_xvalidation;

%% save the mean performance for this setting

% get mean performance across sectors
tempresults = nan(1,nsectors);
for isector = 1:nsectors
    tempresults(isector) = results{isector}.total_perf;
end
meanperf = mean(tempresults);

% save mean performance to tempdata_dir
save(fullfile(tempdata_dir,sprintf('meanperf_%i_%i_%i_%i',r_outer,i_pm,i_ftype,i_fthresh)),...
    'meanperf')
