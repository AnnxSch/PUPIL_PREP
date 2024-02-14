function [meanPupil, sdPupil, P15Pupil] = trialStats(trialData)

% This function calculates the mean, standard deviation and 10th percentile
% on a per-trial basis. For the calculation of these quantities, ONLY 
% NONZERO pupil measurements are included. Disregarding 0s prevent 
% distortion from instances in which the eye could not be tracked (could 
% also be caused by factors other than eye blinks).
%
% [meanPupil, sdPupil, P10Pupil] = trialStats(trialData)
% 
% input arguments:
% trialData: cell array containing raw pupil data from one trial
%
% ouput:
% meanPupil: mean pupil size in arbitrary units for this trail
% sdPupil: standard deviation of pupil size in arbitrary units
% P10Pupil: pupil size below which 15% of the data falls (15th percentile)

% disregard zeros in trialData
NZtrialData = trialData(trialData ~= 0);

meanPupil = mean(NZtrialData);
sdPupil = std(NZtrialData);
P15Pupil = quantile(NZtrialData, 0.15);
