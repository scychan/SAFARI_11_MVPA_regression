function basedir = get_basedir(analysis,searchlight_radius,penalty,dozscore,subjnum)

basedir = sprintf('../../results/searchlights/%s/radius%i/penalty%g/zscore%i/SFR%i',...
    analysis,searchlight_radius,penalty,dozscore,subjnum);