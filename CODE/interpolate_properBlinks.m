function [trialData, nbelow, nblinks, bInterpN] = interpolate_properBlinks(trialData, lowerbound, tpIntp, interpolationMode)

% This function identifies blinks (pupil data < lowerbound) and employs 
% interpolation to replace the affected sections of the pupil data. A wider
% interpolation window is used that overlaps with regions of data exceeding
% the lowerbound.
% 
% [trialData, nbelow, nblinks, bInterpN] = interpolate_properBlinks(pup, lowerbound, tpIntp, interpolationMode)
% 
% input arguments:
% trialData: cell array containing raw pupil data from one trial
% lowerbound: pupil sizes below this integer will be treated as eye blinks
% tpIntp: padding value used to extend the interpolation window
% interpolationMode: string that should be either 'cubic' or 'linear'
%
% output:
% trialData: pupil data from one trial in which effects of proper blinks 
% have been corrected
% nbelow: number of pupil data points that fall below the lowerbound
% threshold (contains nblinks!)
% nblinks: number of proper blinks in this trial
% bInterpN: number of sample points that were replaced by interpolation

% initialize the total number of corrected datapoints
bInterpN = 0;

% number of proper blinks
nblinks = max(bwlabel(trialData==0));  

% array that marks if data point is above the threshold
lowerboundFlags = trialData > lowerbound;

% number of data points below the lowerbound threshold
nbelow = sum(~lowerboundFlags);

% examine which data from the pupil size channel is okay
% nnls is array of indices from pupil measurements larger than
% lowerbounds
nnls = find(lowerboundFlags); % indices points that are not null (above threshold)

% add tpIntp timepoints befor & after
if ~isempty(nnls)

    % array of boundary indices of blinks (starting points)
    bnds = find(diff(nnls)>1); % (points of inflection: p\ )

    ii = 1;

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

    % number of datapoints that will be corrected
    bInterpN = length(trialData) - length(nnls);

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
end

%else case is missing (nnls is empty = Whole trial is below thresh). What to do?
% exclude? -> see pup_preprocess_Anne_modular

