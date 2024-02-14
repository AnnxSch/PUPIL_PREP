function [trialData, nInterpolated] = interpolate_miniblinks(trialData, timewin, delta_cutoff, interp_win, maximum_miniblink_index_duration)

% This function detects miniblinks and performs linear interpolation to
% estimate the invalid data.
%
% trialData = interpolate_miniblinks(trialData, timewin, delta_cutoff, interp_win, maximum_miniblink_index_duration)
% 
% input arguments:
% trialData: cell array containing raw pupil data from one trial. Ensure 
% that proper blinks have already been corrected using 
% 'interpolate_properBlinks_TW.m'!
% timewin: quantifies time window for a sudden change 
% delta_cutoff: minimum pupil size change
% interp_win: padding value used to extend the interpolation window
% maximum_miniblink_index_duration: maximum duration of a miniblink
%
% output:
% trialData: pupil data from one trial corrected for blinks. 
% nInterpolated: number of pupil data points that have been interpolated

% initialize
nInterpolated = 0;

% detect blinks
bli_idx = []; % array of starting indices for miniblinks
for i = 1:timewin:length(trialData)-timewin

    % "\ case": sudden decrease of pupil size (start of miniblink)
    if trialData(i+timewin) - trialData(i) <= delta_cutoff % FIX abs() -> cut-off positive
        bli_idx = [bli_idx i];
    end
end

% clean blinks using linear interpolation
if ~isempty(bli_idx)
    % 
    for i = 1:length(bli_idx)

        % find reopening
        if bli_idx(i) + maximum_miniblink_index_duration < length(trialData) 
            tmp_end = bli_idx(i) + maximum_miniblink_index_duration;
        else
            tmp_end = length(trialData);
        end
        opening = [];
        for ii = bli_idx(i) :timewin: tmp_end-timewin
            % "/ case": pupil size increases rapidly
            if trialData(ii+timewin) - trialData(ii) >= -delta_cutoff
                opening = ii; % take the last rapid increase
            end
        end

        % if start of potential miniblink) is close to end
        if isempty(opening) && (bli_idx(i) >= length(trialData) - maximum_miniblink_index_duration) 
            opening = length(trialData); 
        end
        
        % perform linear interpolation to correct miniblink artifacts
        if ~isempty(opening)
            if opening+interp_win<length(trialData)
                tmp_open = opening+interp_win;
            else
                tmp_open = length(trialData);
            end
            % found index for start of miniblink is too close to beginning
            if bli_idx(i)-interp_win < 1
                tmp_nn = 1;
            else
                tmp_nn = bli_idx(i)-interp_win;
            end
            good = [1:tmp_nn tmp_open:length(trialData)];

            trialData = interp1(good,trialData(good),1:length(trialData));
                % 1st argument: sample points (ie valid values from first dimension/"horizontal")
                % 2nd argument: (valid) sample values (outside of the
                % window surrounding blinks)
                % 3rd argument: length of interpolation axis
            
            nInterpolated = tmp_open - tmp_nn;
            fprintf('miniblink interpolated.\n')
        else
            % if eye opening could not be determined, no interpolation is
            % performed (nInterpolated = 0)
            warning('no eye opening determined - skipping')
        end
    end
end
