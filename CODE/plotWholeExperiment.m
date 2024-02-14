function plotWholeExperiment(ID, pup, fig_dir)

% This function plot the pupil size changes over the course of the entire
% experiment. The resulting figure will be saved within fig_dir as
% 'ID/ID_PupilTrajectoryAcrossExperiment.pdf'.
%
% plotWholeExperiment(ID, pup, fig_dir)
% 
% input arguments:
% ID: subject identifier
% pup: structure containing the raw, but epoched pupil data
% fig_dir: directory for saving the created figure
%
% output:
% none
% 
% side effects:
% saves created figure at 'fig_dir/ID/ID_PupilTrajectoryAcrossExperiment.pdf'

% format figure
set(gcf,'Unit','centimeters','OuterPosition',[0 0 30 15]);

% where a trial ends/next one starts
trialTimeEnd = cellfun(@(ts) ts(end), pup.time);
% get absolute times
t_starts = [0 cumsum(trialTimeEnd)];

% create continously "advancing" time axis
t_experiment = [];
for i=1:length(pup.trial)
    t_experiment = [t_experiment repmat(t_starts(i),1, length(pup.time{i})) + pup.time{i}];
end

% interpret it wrt to sampling rate
% t_experiment = t_experiment / pup.fsample;

% add vertical lines to visualize where trials end
xline(t_starts);
hold on
plot(t_experiment, [pup.trial{:}]);

% annotate
xlabel('time in seconds');
ylabel('pupil size in a.u.');
title('Pupil size changes over the course of the entire experiment');


 % construct complete file path for saving the figure 
fg_fldr = fullfile(fig_dir, int2str(ID)); % platform-independent
fg_nm   = fullfile(fg_fldr, [int2str(ID) '_PupilTrajectoryAcrossExperiment.pdf']);

% create folder <ID> within fig_dir if it doesn't exist already
if ~exist("fg_fldr", "dir")
    mkdir(fg_fldr);
end

% save figure as a PDF in folder '<ID>' within fig_dir
orient(gcf,'landscape') % change orientation for printing
print('-dpdf',fg_nm, '-bestfit');

end