function basedir = get_basedir(analysis,searchlight_radius,penalty,dozscore,brainmask,subjnum)

basedir = sprintf('../../results/searchlights/%s/radius%i/penalty%g/zscore%i/mask%s/SFR%i',...
    analysis,searchlight_radius,penalty,dozscore,brainmask,subjnum);