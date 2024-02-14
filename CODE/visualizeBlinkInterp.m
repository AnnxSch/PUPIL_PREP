function visualizeBlinkInterp(ID, trialData, timeAxis, lowerbound, tpIntp, ...
                              interpolationMode, ...
                              fig_dir)

% This function creates a figure that visualizes the functionality and 
% parameters used for eye blink interpolation. The figure will be saved as
% '<ID>/<ID>_bInterp_visual.jpg' in fig_dir
% FIXME: At the moment, the figure is only scaled accurately for subject
% 908 :(
%
% visualizeBlinkInterp(ID, trialData, timeAxis, lowerbound, tpIntp, interpolationMode, fig_dir)
%
% input arguments:
% ID: subject identifier
% trialData: cell array containing raw pupil data from one trial
% timeAxis: array containing time axis for the trial data
% lowerbound: pupil sizes below this integer will be treated as eye blinks
% tpIntp: padding value used to extend the interpolation window
% interpolationMode: string that should be either 'cubic' or 'linear'
% fig_dir: string specifying the designated directory for created figures
%
% output: none

%path = '~/Documents/Studium/Kognitionswissenschaft/7. Semester/Bachelor thesis/Preprocessing eye tracking data/PREPROCESSING/preprocessing_modular';

% array that marks if data point is above the threshold
lowerboundFlags = trialData > lowerbound;

% examine which data from the pupil size channel is okay
% nnls is array of indices from pupil measurements larger than
% lowerbound
nnls = find(lowerboundFlags); % indices points that are not null (above threshold)

% add tpIntp timepoints befor & after
if ~isempty(nnls)

    % array of boundary indices of blinks (starting points)
    bnds = find(diff(nnls)>1); % (points of inflection: p\ )

    ii = 1;

    % hold last sample point that exceeds lowerbound before the 1st blink
    % for plotting
    idxlastExceedancePriorToBlink = bnds(ii);
    timelastExceedancePriorToBlink = timeAxis(idxlastExceedancePriorToBlink);
    %datalastExceedancePriorToBlink = trialData(idxlastExceedancePriorToBlink);

    % recursively delete neighbourhood of invalid data samples
    while ii <= length(bnds) % length(bnds) is #starting points

        % extend window to overcome boundary effects
        % lower bound 
        if bnds(ii)-tpIntp < 1 % e.g. if pupil is < lowerbound in the first tpIntp (ms?) of the trial
            lb = 2; 
        else 
            lb = bnds(ii)-tpIntp; % beginning of interpolation window
        end

        % upper bound
        if bnds(ii)+tpIntp > length(nnls)   % length(nnls) number of valid samples
            % bnds(ii) is index if blink start/end
                % if blink start/end is within the tpIntp time window
                % before the end of the 
            % FIXME!!! why not check (if bnds(ii)+tpIntp > nnls(end)) ?
            ub = length(nnls); 
        else 
            ub = bnds(ii)+tpIntp; % end of interpolation window
        end
        
        % delete the neighboring indices from the protocol
        nnls(lb:ub) = [];  
        
        % from remaining indices: find boundaries of the blinks
        bnds = find(diff(nnls)>1); % once a blink has been identified
        % and the data has been marked as invalid, the algorithm
        % searches again for blinks until blinks are no longer
        % identified

        % b(ii) will be the index before the lb of the current blink
        % for next loop we want to examine the next blink ->
        % increment
        ii = ii+1; 
    end

    % if trial starts with blink: use first 'good' timepoint as starting point
    if nnls(1) ~= 1     
        trialData(1) = trialData(nnls(1));
        nnls = [1 nnls];
    end
    % if trial ends with blink: use last 'good' timepoint as end point
    if nnls(end) ~= length(trialData) 
        trialData(end) = trialData(nnls(end));
        nnls = [nnls length(trialData)];
    end

    % plotting padding
    surr = 50; %left
    surrR = 140; % right

    % visualize the upcoming correction procedure for the first blink
    idxstartItp = find(diff(nnls) > 1,1); % index of last valid datapoint before 1st blink
    idxendItp = nnls(idxstartItp+1); % index of first valid datapoint after 1st blink
    
    %startItp = [timeAxis(idxstartItp); trialData(idxstartItp)];
    %endItp = [timeAxis(idxendItp); trialData(idxendItp)];
    timeItp = [timeAxis(idxstartItp) timeAxis(idxendItp)];
    dataItp = [trialData(idxstartItp) trialData(idxendItp)];

    % "zoom" to the first blink
    timeAxis = timeAxis(idxstartItp-surr:idxendItp+surrR);
    trialExcerpt = trialData(idxstartItp-surr:idxendItp+surrR);

    % plot the first eye blink
    plot(timeAxis, trialExcerpt, 'k', 'LineWidth', 0.7);
    hold on

    % set axis limits for better visibility 
    ylimits = [600 2100];
    xlimits = [3.325 3.85];
    %xlimits = [timeItp(1)-0.155 timeItp(2)+0.16]
    ylim(ylimits);
    xlim(xlimits);
    
    % remove the ticks on top horizontal and right vertical axis
    axs = gca; % get a hold of current axes
    axs.Box = "off"; % remove the automatic axes
    xline(axs, axs.XLim(2)); % add new x axis
    yline(axs, axs.YLim(2)); % add new y axis
    % CAUTION! AXES WON'T SCALE AUTOMATICALLY WHEN ZOOMING FURTHER IN/OUT

    % add dots to mark last valid datapoints
    plot(timeItp, dataItp, '.', ...
         'MarkerSize', 15, 'MarkerFaceColor', "#D95319", ...
         'MarkerEdgeColor', "#A2142F");
    % xarr = [timelastExceedancePriorToBlink timeItp(1)]; % official x coordinates
    % yarr = [lowerbound+30, lowerbound+30]; % official y coordinates
    % FIXME: transformation of coordinates is annoying 
    % % transform coordinates to figure coordinates (normalized)
    % % place the coordinates "inside" the axis vectors xlim and ylim
    % xarr = xarr - xlimits(1);
    normTime = timeItp - xlimits(1);
  
    % yarr = yarr - ylimits(1);
    % % length of the axis vectors
    % ylen = ylimits(2) - ylimits(1);
    xlen = xlimits(2) - xlimits(1);
    xtrsf = 1/xlen; % factor for transformation of the x coordinates
    normTime = xtrsf * normTime;
    % ytrsf = 1/ylen; % factor for transformation of the y coordinates
    % figxarr = xtrsf * xarr;
    % figyarr = ytrsf * yarr;
    % annotation('arrow', figxarr, figyarr);

    % for some obscure reason, the converted coordinates still dont fit 
    % suspicion: (xlimits(1), 600) does not correspond to (0,0)
    normTime(1) = normTime(1) + 0.105;
    normTime(2) = normTime(2) - 0.0275;
    
    annotation("textarrow", [normTime(1) normTime(1)], [0.6 0.745], ...
               'String', {["last accepted"], ["sample"], ["before blink"]}, ...
               'Color', "#A2142F");
    annotation("textarrow", [normTime(2) normTime(2)], [0.6 0.745], ...
               'String', {["first accepted"], ["sample"], ["after blink"]}, ...
               'Color', "#A2142F");


    % interpolation mode
    switch interpolationMode
        case 'cubic'
            trialData = spline(nnls,trialData(nnls),1:length(trialData));
            
        case 'linear'
            % nnls: all indices that don't need to be interpolated
            % 1st argument: sample points (i.e. valid values from "first
            % dimension")
            % 2nd argument: (valid) sample values (outside of the
            % window surrounding blinks)
            % 3rd argument: length of interpolation axis
            trialData = interp1(nnls,trialData(nnls),1:length(trialData)); %FIX why linearly connected
            
        otherwise
            error('eyeblink correction not specified')
    end

    % add corrected pupil trace to visulization
    trialExcerpt_corrected = trialData(idxstartItp:idxendItp);
    trialExcerpt_corrected = [nan(1,surr) trialExcerpt_corrected nan(1,surrR)];
    plot(timeAxis, trialExcerpt_corrected, 'Color', [0.4660 0.6740 0.3080], ...
         'LineStyle', ':', 'LineWidth', 1.9);

    % annotate the corrected pupil trace
    annotation('textarrow', [0.65 0.5], [0.87 0.76], 'String', ' interpolated samples', ...
               'Color', [0.4660 0.6740 0.3080]);

    % add horizontal line to visualize lowerbound
    yline(lowerbound, '--', 'lowerbound', 'LabelVerticalAlignment', 'middle', ...
          'Color', "#A2142F", 'LineWidth', .75);

    % add interpolation window (transparent)
    %rectangle('Position', [timeAxis(surr+1) 600 ])
    %Y = [600 1900 600 1900];
    patch('Faces', [1 2 3 4], 'Vertices', ...
          [timeAxis(surr+1) 600;  timeAxis(surr+1) 1950; timeAxis(end-surrR) 1950; timeAxis(end-surrR) 600], ...
          'FaceColor', "#0072BD", ...
          'FaceAlpha', 0.05, ...
          'EdgeColor', "#0072BD", ...
          'EdgeAlpha', 0.05);
    text(timeAxis(surr+1)+0.004, 1950, 'interpolation window', 'Color', "#0072BD", 'HorizontalAlignment', 'left', ...
         'VerticalAlignment', 'top');

    % add arrows to depict tpIntp
    xarrL = [timeItp(1) timelastExceedancePriorToBlink ]; % official x coordinates
    yarrL = [lowerbound+30, lowerbound+30]; % official y coordinates

    % use quiver
    % p1 = [2 3];                         % First Point
    % p2 = [9 8];                         % Second Point
    % dp = p2-p1;                         % Difference
    % figure
    % quiver(p1(1),p1(2),dp(1),dp(2),0)
    % grid
    % axis([0  10    0  10])
    % text(p1(1),p1(2), sprintf('(%.0f,%.0f)',p1))
    % text(p2(1),p2(2), sprintf('(%.0f,%.0f)',p2))

    %quiver(xarr(1), yarr(1), diff(xarr), diff(yarr), 0, 'Marker' , '<', 'MaxHeadSize',0.5);
    % visualize padding on the left
    line(xarrL, yarrL, 'LineStyle', '-', 'DisplayName', 'tpIntp', 'Marker', '|', 'Markersize', 3, 'LineWidth', 0.7, 'Color', [0 0.4470 0.7410]);
    text(max(xarrL)-diff(xarrL)/2,max(yarrL) + 30, '100 ms', 'Color', [0 0.4470 0.7410], 'HorizontalAlignment', 'center');

    % visualize padding on the right
    timefirstExceedanceAfterBlink = timeAxis(end-surrR+1-tpIntp); 
    xarrR = [timefirstExceedanceAfterBlink, timeItp(2)];
    yarrR = yarrL;
    line(xarrR, yarrR, 'LineStyle', '-', 'DisplayName', 'tpIntp', 'Marker', '|', 'Markersize', 3, 'LineWidth', 0.7, 'Color', [0 0.4470 0.7410]);
    text(max(xarrR)-diff(xarrR)/2,max(yarrR) + 30,'100 ms', 'Color', [0 0.4470 0.7410], 'HorizontalAlignment', 'center');
    
    % annotate
    ylabel('pupil size in a.u.');
    xlabel('time in sec');
    title(interpolationMode + " interpolation procedure for correcting eye blinks");

    % save figure
    % construct complete file path for saving the figure 
    fg_fldr = fullfile(fig_dir, int2str(ID)); % platform-independent
    fg_nm   = fullfile(fg_fldr, [int2str(ID) '_bInterp_visual.pdf']);
    
    % create folder <ID> within fig_dir if it doesn't exist already
    if ~exist("fg_fldr", "dir")
        mkdir(fg_fldr);
    end
    
    % save figure as a PDF in folder '<ID>' within fig_dir
    orient(gcf,'landscape') % change orientation for printing
    print('-dpdf',fg_nm, '-bestfit');

    hold off
end