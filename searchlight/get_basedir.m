function basedir = get_basedir(searchlight_radius,penalty,dozscore,subjnum)

basedir = sprintf('../../results/searchlights/radius%i/penalty%g/zscore%i/SFR%i',...
    searchlight_radius,penalty,dozscore,subjnum);