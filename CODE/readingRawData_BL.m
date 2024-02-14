function pup = readingRawData_BL(ID, triggerValue, beforeTrigger, afterTrigger)

% For the given subject, the raw data is parsed into a data structure
% suitable for preprocessing. This involves splitting the data into
% interval(s) of length beforeTrigger + afterTrigger
% 
% pup = readingRawData_BL(ID, triggerValue, beforeTrigger, afterTrigger)
% 
% input arguments:
% ID: subject identifier
% triggerValue: data will be segmented around triggers with this value
% beforeTrigger: How much time before the specified trigger should be incl?
% afterTrigger: How much time after the trigger should be incl. in trial?
%
% output:
% pup: raw data structure containing segmeneted data from the baseline
% measurements
%
% side effect:
% creates .mat file in which the result will be saved (if this file does
% not exist already)

%% 
path = '~/Documents/Studium/Kognitionswissenschaft/7. Semester/Bachelor thesis/Preprocessing eye tracking data';
data_dir = [path '/PREPROCESSING/DATA'];

% add path to FieldTrip directory
addpath([path '/TOOLS/fieldtrip-20231113']);

%% read data
% only epoch if .m file for ID does not exist
if exist([data_dir '/ft_' int2str(ID) '_pup_bl.mat'],'file')~=2

    % only prefix for convienence
    prefixThisFile = [data_dir '/' int2str(ID) '/' int2str(ID)];

    if ~exist([prefixThisFile '_bl_ATN.asc'],'file')
        % converting file for ft
        eyeAdjustTrigNam([prefixThisFile '_bl.asc']);
    end
    
    % define trials
    cfg                     = [];
    cfg.dataset             = [prefixThisFile '_bl_ATN.asc']; % ascii converted eyelink filename
    cfg.trialfun            = 'ft_trialfun_general';
    cfg.headerformat        = 'eyelink_asc';
    cfg.dataformat          = 'eyelink_asc';
    cfg.trialdef.eventtype  = 'INPUT';
    cfg.trialdef.eventvalue = triggerValue;  % event of interest

    % prestim + poststim info is used to compute number of samples that
    % have to be read
    cfg.trialdef.prestim    = beforeTrigger;    
    cfg.trialdef.poststim   = afterTrigger;    

    % segment the data around the event of interest
    cfg                     = ft_definetrial(cfg);
    
    % save triggers
    cfg.event = ft_read_event(cfg.dataset);
    
    % specify channel for further preprocessing
    cfg.channel             = {'4'};      % channel 2 is the x-coordinate
                                          % channel 3 is the y-coordinate
                                          % channel 4 is the pupil dilation
    
    % probably no need for specifying this again
    %cfg.dataformat          = 'eyelink_asc';
    %cfg.headerformat        = 'eyelink_asc';

    pup                     = ft_preprocessing(cfg);
  
    % save the epoched raw data in .mat file
    save([data_dir '/ft_' int2str(ID) '_pup_bl.mat'],'pup')
    
else
    load([data_dir '/ft_' int2str(ID) '_pup_bl.mat']);
end
