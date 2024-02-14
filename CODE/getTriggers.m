function triggers = getTriggers(data)

% This function assigns triggers to their corresponding trials.
%
% triggers = getTriggers(data)
%
% input arguments:
% data: struct that contains segmented data from one block. 
%       The field 'sampleinfo' contains [sample-indices of trial starts , sample-indices of trial
%       ends] relative to the start of the raw data. 
%       cfg.event contains information about the triggers
% 
% output:
% triggers: trial-wise storage of trigger information

% loop through all trials from that block
for t = 1:length(data.trial)
    % find all triggers with sample indices >= trial start and <= trial end
    % index
    trg_tmp = find([data.cfg.event(:).sample]>=data.sampleinfo(t,1) & ...
                   [data.cfg.event(:).sample]<=data.sampleinfo(t,2));
    
    % add all triggers from that trial
    triggers{t} = data.cfg.event(trg_tmp);
end

end