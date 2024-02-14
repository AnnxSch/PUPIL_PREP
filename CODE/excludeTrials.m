function pup = excludeTrials1(pup, validTrials)

% This function will remove all trials that have previously been identified
% as being untrustworthy. 
%
% input arguments:
% pup:
% validTrials: array of trial identifiers corresponding to trials
% in which less than 75% of the data points have been roughly calculated
% during previous preprocessing steps
% 
% output:
% pup: structure in which all information pertaining to trials that do not
% meet the inclusion criterion has been removed.
%
% "side effects":
% overhauls pup (removal of invalid trials)

% trial-wise classes of data are characterised by correct number of entries
ntrials = length(pup.trial); % number of trials

% set up anonymous function for identifying relevant fields
condition = @(elem) length(elem) == ntrials; 

flds = fieldnames(pup); % all field names

% remove information associated with untrustworthy trials from relevant 
% fields
for ii=1:length(flds)
    fname = flds{ii};
    % check if field named 'fname' contains trial-wise information
    if condition(pup.(fname))
        % cleanse unmarked trial data from all relevant fiels
        pup.(fname) = pup.(fname)(validTrials);
    end
end

% number of trials that have have been removed
pup.nRemoved = ntrials - length(validTrials);

end

