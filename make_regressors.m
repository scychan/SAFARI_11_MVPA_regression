function make_regressors(subjnum,analysis)

%% set directory for saving regressors and selectors

outdir = sprintf('../results/regressors/SFR%i',subjnum);
mkdir_ifnotexist(outdir)

%% load corrected behavioral data

behav_data_file = sprintf('../../5_analyze_behavioral_data/results/rescore/subj%i',subjnum);
load(behav_data_file)

%% load info about scans

% run_lengths
fmri_data_dir = sprintf('../../6_fMRI_data/SFR%i',subjnum);
run_lengths = load(fullfile(fmri_data_dir,'run_lengths.txt'));
nruns = length(run_lengths);
totTR = sum(run_lengths);

% TR info
TRsecs = 2;

% sess to use
episess = [10 11 12 13];

%% adjustments to times for concatenated 4D file (to account for pauses between scans)

% times relative to the start of the 4D file
T.run_start(1) = 0;
for i = 2:nruns
    T.run_start(i) = TRsecs*sum(run_lengths(1:(i-1)));
end
T.adjustment = trials.t.startscan_trigger(episess) - T.run_start';

%% stimulus onsets
% XX allow option for second TR only, or both TRs?

run_Tstims = cell(1,nruns);
for run = 1:nruns
    sess = episess(run);
    run_Tstims{run} = [trials.t.stim_onset{sess}{:}] - T.adjustment(run);
end
T.stim_onset = [run_Tstims{:}];
nstim = length(T.stim_onset);
TR.stim_onset = round(T.stim_onset/TRsecs) + 1;

% to check
figure; plot(reshape(TR.stim_onset',1,nstim),'.')

%% make regressors

switch analysis
    
    case 'ridge'
        % posterior P(zone|animals so far), at the time of each stimulus
        
        % load the posteriors
        posteriors = [stimlist.trials.posteriors_new{episess}];
        posteriors = vertcat(posteriors{:});
        
        % make regs
        regs = zeros(4,totTR);
        for istim = 1:nstim
            regs(:,TR.stim_onset(istim)) = posteriors(istim,:);
            regs(:,TR.stim_onset(istim)+1) = posteriors(istim,:);
        end
        
        % to check
        figure; plot(regs','.')
        
        % save the regs
        regsname = ['regs_' analysis];
        save(fullfile(outdir,regsname), 'regs')
        
    case 'logregMAP'
        % for each sector:
        %   1 if sector is MAP
        %   0 otherwise
        % 10 sets of regressors, each randomly subsampled to get equal numbers in each condition
        
        % load the posteriors
        posteriors = [stimlist.trials.posteriors_new{episess}];
        posteriors = vertcat(posteriors{:});
        
        % find MAP for each timepoint
        [~, MAP] = max(posteriors,[],2);
        
        % num in each class
        MAPhist = hist(MAP,1:4);
        num_to_rm = MAPhist - min(MAPhist);
        
        % set random seed
        setseedwclock;
        
        % make 10 sets of regressors (randomly subsampling each time)
        for iter = 1:10
            
            % randomly subsample the larger classes
            iterMAP = MAP;
            for sector = 1:4
                sectorinds = find(MAP == sector);
                sectorinds = sectorinds(randperm(MAPhist(sector)));
                iterMAP(sectorinds(1:num_to_rm(sector))) = 0;
            end
            
            % make regs
            regs = zeros(4,totTR);
            for istim = 1:nstim
                if iterMAP(istim) > 0
                    regs(iterMAP(istim), TR.stim_onset(istim)) = 1;
                    regs(iterMAP(istim), TR.stim_onset(istim)+1) = 1;
                end
            end
            
            % to check
            figure; hold on
            plot(regs','.')
            postregs = zeros(4,totTR);
            for istim = 1:nstim
                postregs(:,TR.stim_onset(istim)) = posteriors(istim,:);
                postregs(:,TR.stim_onset(istim)+1) = posteriors(istim,:);
            end
            plot(postregs')
            
            % save the regs
            regsname = sprintf('regs_%s_iter%i',analysis,iter);
            save(fullfile(outdir,regsname), 'regs')
        end
end

