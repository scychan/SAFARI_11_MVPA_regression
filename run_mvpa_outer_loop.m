function run_mvpa_outer_loop(subjID)

%% load workspace from run_mvpa_init

tempdata_dir = fullfile('../tempdata',subjID);
load(fullfile(tempdata_dir,'init_workspace'))

%% model-selection (find best parameters) on inner xvalidation loops

% for each inner loop
results_inner = nan(length(unique(runs)),...
    length(args.penalty_multipliers),...
    length(args.featsel_types),...
    length(args.featsel_threshes));
best_setting = nan(1,max(unique(runs)));
for r_outer = unique(runs)
    for i_pm = 1:length(args.penalty_multipliers) % penalty multiplier
        for i_ftype = 1:length(args.featsel_types) % feature selection type
            if strcmp(setting.featsel_type,'none')
                error('no need to iterate over thresholds -- write this code')
            else
                for i_fthresh = 1:length(args.featsel_threshes) % feature selection threshold
                    % load the mean performance for this setting
                    load(fullfile(tempdata_dir,sprintf('meanperf_%i_%i_%i_%i',r_outer,i_pm,i_ftype,i_fthresh)))
                    results_inner(r_outer,i_pm,i_ftype,i_fthresh) = meanperf;
                end
            end
        end
    end
    
    % find the best setting
    [~, best_setting(r_outer)] = max(vert(results_inner(r_outer,:,:,:)));
end

%% do cross-validation on the outer loop, using the best settings from the inner loop

% get the best setting for each r_outer
for r_outer = unique(runs)
    [i_pm, i_ftype, i_fthresh] = ind2sub([length(args.penalty_multipliers),...
        length(args.featsel_types),...
        length(args.featsel_threshes)],...
        best_setting(r_outer));
    
    setting(r_outer).penalty_multiplier = args.penalty_multipliers(i_pm);
    setting(r_outer).featsel_type = args.featsel_types{i_ftype};
    setting(r_outer).featsel_thresh = args.featsel_threshes(i_fthresh);
    
    setting(r_outer).xvalname = sprintf('%s_%i',outerxvalname,r_outer);
end

% run xvalidation
run_xvalidation

% save the results
results_outer = results;
clear results

%% make plots for results

makefigs = 0;
if makefigs
    fig1 = mvpa_confusion_matrix(results,condnames);
    fig2 = mvpa_plot_v_time(results,condnames);
    
    saveas(fig1,fullfile(results_dir,'confusion_matrix.fig'))
    saveas(fig2,fullfile(results_dir,'timeplot.fig'))
end

%% save results

% results_name
full_results_name = sprintf('%s_%s',datestr(now,'mmddyy_HHSS'),results_name);

% results_dir
results_dir = sprintf('../results/mvpa_results/%s/%s',args.subjID, full_results_name);
mkdir_ifnotexist(results_dir)

% remove the functional pattern, which is large
subj = remove_mat(subj,'pattern',epiname);

% save args, subj, results_inner, results_outer
save(fullfile(results_dir,'args'),'args')
save(fullfile(results_dir,'subj'),'subj')
save(fullfile(results_dir,'results_inner'),'results_inner')
save(fullfile(results_dir,'results_outer'),'results_outer')

% save figures
if makefigs
    saveas(fig1,fullfile(results_dir,'confusion_matrix.eps'))
    saveas(fig2,fullfile(results_dir,'timeplot.eps'))
end