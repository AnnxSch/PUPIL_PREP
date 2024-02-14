function pup = pupilStats(ID, pup, verbose1, fig_dir)

% This function calculates the mean, standard deviation and 15th percentile
% of NONZERO pupil measurements across all trials. Disregarding 0s and only
% including nonzero pupil data prevents distortion from instances in which
% the eye could not be tracked. 
% The obtained summary statistics will play a key role in identifying
% artifacts in preceding preprocessing stages.
%
% pup = pupilStats(ID, pup, verbose1, fig_dir)
%
% input arguments:
% ID: subject identifier
% pup: structure containing raw, but segmented data for given subject. 
% For each trial, information about the mean DIAMETER(?) and the raw pupil
% % diameter/mean area depends on eye tracker settings
% data (both in arbitrary units) can be retrieved from the fields 'trlMeans'
% and 'trial'.
% verbose1: boolean flag indicating whether to create a histogram of the
% pupil data. If 1, the figure will be saved in fig_dir as '<ID>_raw_hist.jpg'
% fig_dir: string specifying the designated directory for created figures.
%
% output:
% pup: input data structure which features two new fields ('glblmean_raw', 
% 'glblsd_raw' and 'glbl_P15_raw') holding the global mean, standard 
% deviation and 15th percentile of the raw pupil data in arbitrary units

% filter out nonzero data
allData = [pup.trial{:}];
nzData = allData(allData ~= 0);

% compute the summary statistics across trials
pup.glblmean_raw = mean(nzData); % for testing: 908: 1228.5 a.u.
pup.glblsd_raw = std(nzData);  % 908: 473.2675 a.u.
% pooled std?

% value below which 15% of the data falls
pup.glblP15_raw = quantile(nzData, 0.15);

% get a rough sense of the underlying distribution of the data
if verbose1
    f = figure('Name', 'data spread overview');
    h = histogram(allData, 'Normalization', 'probability', ...
                  'FaceColor', [0.6350 0.0780 0.1840], ...
                  'EdgeColor', [0.6350 0.0780 0.1840], ...
                  'DisplayName', 'Pupil data from all trials (incl. 0s)');
    % not yet successful attemps to colour the "zero" bar red and the other
    % bars in a different colour
    %b = bar(1:length(h.BinCounts),h.Values);
    hold on
    %tmp_values_zero = h.Values(1);
    %h.Values(1) = 0;
    %b.FaceColor = 'flat';
    %b.CData(1,:) = [0.6350 0.0780 0.1840];
    %hold on
    % depict the 10th percentile in the plot
    xl = xline(pup.glblP15_raw, '--', '15 th percentile', ...
               'DisplayName', 'P15 only based on NONZERO measures', ...
               'LineWidth', 2, 'LabelHorizontalAlignment', 'left', 'LabelVerticalAlignment', 'middle');

    %xlim([0, max(allData)]);
    xlabel('Pupil size in a.u.');
    ylabel('frequency');
    title("Overview of subject " + num2str(ID) + "'s (nonzero) data distribution");
    legend('show', 'Position', [0.3 0.8 0.05 0.1]);
    hold off

    % construct complete file path for saving the figure 
    fg_fldr = fullfile(fig_dir, int2str(ID)); 
    fg_nm = fullfile(fg_fldr, [int2str(ID) '_raw_hist.pdf']);

    % create folder <ID> within fig_dir if it doesn't exist already
    if ~exist("fg_fldr", "dir")
        mkdir(fg_fldr);
    end
    
    % save figure as a PDF in folder '<ID>' within fig_dir
    orient(gcf,'landscape') % change orientation for printing
    print('-dpdf',fg_nm, '-bestfit');
end

end