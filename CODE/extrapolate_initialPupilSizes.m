function [trialData, nExtrapolated] = extrapolate_initialPupilSizes(trialData, d2_crit, def_beginning, start_search, sc_start,  sc_end, sc_d_crit, interp_win_onsetMiniblinks)

% This function identifies and corrects initial (half-)closures of the eyes
% by searching for rapid velocity? pupil size changes in the beginning of 
% all trials.
%
% [trialData, nExtrapolated] = extrapolate_initialPupilSizes(trialData, d2_crit, def_beginning, start_search, sc_start,  sc_end, sc_d_crit, interp_win_onsetMiniblinks)
% 
% input arguments:
% trialData: structure containing blink-corrected and low-pass 
% filtered data from one trial
% d2_crit: absolute change rate threshold used to classify rapid changes
% def_beginning: integer specifying the end of the "beginning" period
% start_search: starting point from which on a slight change could occur
% sc_start: padding value used to extend the search window to the left
% sc_end: padding value used to extend the search window to the right
% sc_d_crit: absolute change rate threshold used to classify slight changes
% interp_win_onsetMiniblinks: size of the interpolation window
%
% output:
% trialData: cell array in which pupil size data contaminated with initial 
% (half-)closures of the eyes have been replaced with linearly extrapolated 
% values
% nExtrapolated: number of pupil data points that just been extrapolated

% initialize
nExtrapolated = 0;

% does pupil size velocity? change rapidly
if max(abs(diff(diff(trialData(1:def_beginning))))) > d2_crit  % change in 1 sec bigger than criterion
    % find end of blink
    tmp = [];
    for i= start_search:10:def_beginning %FIXME: why start at 101?
        % find the last slight change
        if mean(abs(diff(diff(trialData(i-sc_start:i+sc_end))))) < sc_d_crit
            % FIXME: why 400 msec(?) time window
        % if isempty(tmp) && mean(abs(diff(diff(pup.trial{t}(i-100:i+300))))) < .05
            tmp = i;
        end
    end
    % extrapolate the initial pupil sizes
    trialData(1:tmp-1) = interp1(tmp:tmp+interp_win_onsetMiniblinks, ...
                                    trialData(tmp:tmp+interp_win_onsetMiniblinks), ...
                                    1:tmp-1,'linear','extrap');
    % number of extrapolated data points 
    nExtrapolated = tmp;
end