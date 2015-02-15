% structure 'setting' should be set up in calling function (run_mvpa.m)

%% whether one setting or one setting per xvalidation iteration
nsetting = numel(setting);
onlyonesetting = (nsetting == 1);

%% feature selection
% use the same selectors that will be used in cross-validation
% => featselname OR featselnames{isector}

for iter = 1:nsetting
    
    switch setting(iter).featsel_type
        case 'none'
            %== No feature selection ==%
            featselname{iter} = maskname;
            
        case 'corr'
            %== Correlation-based feature selection ==%
            for isector = 1:nsectors
                if onlyonesetting
                    statmap_namestem = 'stat';
                    featselmask_namestem = 'featselmask';
                else
                    statmap_namestem = sprintf('stat_iter%i',iter);
                    featselmask_namestem = sprintf('featselmask_iter%i',iter);
                end
                subj = feature_select(subj,epiname, ...
                    regsnames_separated{isector}, setting(iter).xvalname, ...
                    'statmap_funct','statmap_xcorr', ...
                    'statmap_arg', [], ...
                    'new_map_patname', sprintf('%s_sector%i',statmap_namestem,isector), ...
                    'thresh', []);
                featselnames{iter,isector} = sprintf('%s_sector%i',featselmask_namestem,isector); %#ok<SAGROW>
                subj = create_sorted_mask(subj, sprintf('%s_sector%i',statmap_namestem,isector),...
                    featselnames{iter,isector}, setting(iter).featsel_thresh,'descending',1);
            end
            
        case 'anova'
            %== ANOVA-based feature selection ==%
            subj = feature_select(subj,epiname,regsname,setting(iter).xvalname,...
                'thresh',setting(iter).featsel_thresh);
            featselname{iter} = [epiname '_thresh' num2str(setting(iter).anovathresh)];
    end
end

%% classification

% each iteration separately
if strcmp(args.classifier,'ridge') && strcmp(setting(iter).featsel_type,'corr')
    results = cell(nsetting,nsectors);
else
    results = cell(nsetting,1);
end
for iter = 1:nsetting
    
    % compute penalty
    if exist('featselname','var')
        nvox = sum(vert(get_mat(subj,'mask',featselname{iter})));
    else
        nvox = sum(vert(get_mat(subj,'mask',[featselnames{iter,1} '_1'])));
        setting(iter).penalty = setting(iter).penalty_multiplier * nvox;
    end
    
    % get class_args
    switch(args.classifier)
        case 'gnb'
            class_args.train_funct_name = 'train_gnb';
            class_args.test_funct_name = 'test_gnb';
            perfmet_func = 'perfmet_maxclass';
        case 'bp'
            class_args.train_funct_name = 'train_bp';
            class_args.test_funct_name = 'test_bp';
            class_args.nHidden = 0;
            perfmet_func = 'perfmet_maxclass';
        case 'L2logreg'
            class_args.train_funct_name = 'train_L2_RLR';
            class_args.test_funct_name = 'test_L2_RLR';
            class_args.penalty = setting(iter).penalty;
            class_args.lambda = 'crossvalidation'; % XX-- peeking??
            perfmet_func = 'perfmet_maxclass';
        case 'logreg'
            class_args.train_funct_name = 'train_logreg';
            class_args.test_funct_name = 'test_logreg';
            class_args.penalty = setting(iter).penalty;
            perfmet_func = 'perfmet_maxclass';
        case 'ridge'
            class_args.train_funct_name = 'train_ridge';
            class_args.test_funct_name = 'test_ridge';
            class_args.penalty = setting(iter).penalty;
            perfmet_func = 'perfmet_xcorr';
        otherwise
            disp('(-) unknown classifier type!');
            return
    end
    
    % do cross-validation, just for this iteration
    if strcmp(args.classifier,'ridge') && strcmp(setting(iter).featsel_type,'corr')
        for isector = 1:nsectors
            [subj, results{iter,isector}] = cross_validation(subj,epiname,regsnames_separated{isector},...
                setting(iter).xvalname,featselnames{iter,isector},class_args,...
                'perfmet_functs',perfmet_func);
        end
    else
        [subj, results{iter}] = cross_validation(subj,epiname,regsname,...
            setting(iter).xvalname,featselname{iter},class_args,...
            'perfmet_functs',perfmet_func);
    end
end