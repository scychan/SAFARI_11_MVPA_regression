function make_runs_selector(subjnum)

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

%% make runs selector - for cross-validation

% get scan starts (in TRs)
TR.run_start = cumsum([1 run_lengths(1:end-1)]);

% make runs selector
runs = zeros(1,totTR);
for irun = 1:nruns-1
    runs( TR.run_start(irun) : (TR.run_start(irun+1) - 1) ) = irun;
end
runs(TR.run_start(end) : end ) = nruns;

% to check
figure; plot(runs','k--'); hold on; plot(regs'.*repmat(runs',1,4),'.')
for irun = 1:nruns
    disp(sum(runs==irun))
end

% save the runs selector
save(fullfile(outdir,'runs'),'runs')