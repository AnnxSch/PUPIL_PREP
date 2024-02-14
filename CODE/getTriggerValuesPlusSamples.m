function inputs = getTriggerValuesPlusSamples(pup)

% This function extracts the sample number(?) and values for all events of 
% type 'INPUT' from the pup data structure. 
%
% inputs = getTriggerValuesPlusSamples(pup)
%
% input arguments:
% pup: structure storing information about the segmented data (trial-wise). 
% Information about the triggers can be found in field 'triggers'.
%
% output:
% inputs: cell array with fields ...
%   inputs.samples: cell array containing sample number at which the
%   triggers of type 'INPUT' have occurred 
%   inputs.value: cell array storing values of all triggers of type 'INPUT'

% initialise output structure
inputs = {};
inputs.samples = {}; % use cell array because #INPUTS may differ
inputs.values = {};

 for t=1:length(pup.triggers)
    logicalIndex = strcmp({pup.triggers{1,t}(:).type}, 'INPUT');
    tmp_inputSamples = [pup.triggers{1,t}(logicalIndex).sample];
    tmp_inputValues = {pup.triggers{1,t}(logicalIndex).value}; % used for labeling

    % transform to inputSamples to match the time axis pup.maxtime
    % inputSamples relative to pup.sampleinfo(i,1) (sample index of trial
    % start)
    tmp_inputSamples = tmp_inputSamples - pup.sampleinfo(t,1);

    % msec -> sec + shift to time of prestim 
    tmp_inputSamples = tmp_inputSamples * 10^(-3) - 1; %FIX

    % save 
    inputs.samples{t} = tmp_inputSamples; 
    inputs.values{t} = tmp_inputValues;
 end
