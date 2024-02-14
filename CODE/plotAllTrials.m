function plotAllTrials(ID, pup, preprocessingStatus, lwb_mode, fig_dir)

% This function plots the all pupil size trajectories over the course of 
% one trial for the subject with identifier ID. 
%
% plotAllTrials(ID, pup, preprocessingStatus, lwb_mode, fig_dir)
%
% input arguments:
% ID:  subject identifier
% pup: structure containing raw, but segmented data for given subject
% preprocessingStatus: 'unprocessed' if data is unprocessed, 'blink' if
% last completed step was blink interpolation, 'completed' is preprocessing is
% completed
% lwb_mode: character string specifying the logic employed to obtain the utilized
% lowerbound for eye blink identification and correction. This string
% is used to annotate the figure and to generate a suitable file name. 
% fig_dir: string specifying the designated directory for created figures.
% 
% side effects:
% saves the plot .fig file in PDF file in folder '<ID>/' within fig_dir

% bring all trials to the same length (fill with NaNs if needed)
dat = nan(length(pup.trial),length(pup.maxtime)); %in our case: 164x7000
for t = 1:length(pup.trial)
    dat(t,1:length(pup.trial{t})) = pup.trial{t}(1,:); %alternatively (end,:)
end

% FIXME: this is still somewhat messy

% if data is raw 
if preprocessingStatus == "unprocessed"
    % plot the raw pupil size trajectories over the course of each trial
    plot(pup.maxtime,dat);

    % formatting
    xlim([pup.maxtime(1), pup.maxtime(end)])

    % annotate
    sgtitle("pupil size trajectory for subject " + int2str(ID) + ...
            " over course of each trial (" + lwb_mode + ")"); % main title
    ylabel('pupil size (a.u.)');
    title("before preprocessing"); % title for this subplot
    
    %% mark the trigger values
    % select sample + value of triggers of type INPUT from trigger structure
    inputs = getTriggerValuesPlusSamples(pup);
    % only include trigger values from the first trial in the plot for clarity
    xline(inputs.samples{1}, '-.', inputs.values{1}, 'LabelHorizontalAlignment', 'center', 'LineWidth', 1)
else
% blinks have been interpolated
if preprocessingStatus == "blink"
    % plot the pupil size trajectories over the course of each trial
    plot(pup.maxtime,dat)
    
    % formatting
    xlim([pup.maxtime(1), pup.maxtime(end)])

    % percentage of corrected data so far
    percentCorrected = pup.bPercent + pup.mbPercent;

    % annotate
    ylabel('pupil size (a.u.)');
    title("after blink correction + low-pass filtering (" + int2str(percentCorrected) + "% interpolated)");
end
if preprocessingStatus == "completed"
    % plot the preprocessed pupil size trajectories (over each trial)
    plot(pup.maxtime, dat);
    
    % formatting
    xlim([pup.maxtime(1), pup.maxtime(end)])

    % annotate
    ylabel('pupil size (a.u.)');
    xlabel('time in sec (0 corresponds to trigger with value 80)');
    title("after preprocessing (" + int2str(pup.totalcorrectedProportion * 100) + "% corrected and " + int2str(pup.nRemoved) + " trial removals)");
     
    % % construct complete file path for saving the figure 
    % fg_fldr = fullfile(fig_dir, int2str(ID)); % platform-independent
    % fg_nm   = fullfile(fg_fldr, [int2str(ID) '_trial_preprocessing_' lwb_mode '.pdf']);
    % 
    % % create folder <ID> within fig_dir if it doesn't exist already
    % if ~exist("fg_fldr", "dir")
    %     mkdir(fg_fldr);
    % end
    % 
    % % save figure as a PDF in folder '<ID>' within fig_dir
    % orient(gcf,'landscape') % change orientation for printing
    % print('-dpdf',fg_nm, '-bestfit');
end

end

