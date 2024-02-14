function pup = readingRawData(ID, data_dir, ...
                              nblocks, triggerValue, beforeTrigger, afterTrigger, ...
                              fieldtrip_dir)

% For the given subject, parse the data into a data structure suitable for
% further processing and segment the raw pupil data from all blocks into 
% trials around the trigger of interest.
% 
% pup = readingRawData(ID, data_dir, nblocks, triggerValue, beforeTrigger, afterTrigger, fieldtrip_dir)
% 
% input arguments:
% ID: subject identifier
% data_dir: string specifying the path to directory containing the data. The
% target location should contain a separate folders names <ID> in which the 
% raw asc files named '<ID>_<1:nblocks>.asc' are stored.
% nblocks: number of blocks in experiment
% triggerValue: data will be segmented around this trigger
% beforeTrigger: How much time before the trigger should be included?
% afterTrigger: How long after the trigger should be incl. in the trial?
% fieldtrip_dir: string specifying the path to the fieldtrip toolbox
% 
% output:
% pup: raw data structure that contains segmented data from all trials
% 
% side effect:
% creates .mat file in which the result will be saved (if this file does
% not exist already)

%%  add path to FieldTrip directory
addpath(fieldtrip_dir);

%% read data
% only do trial segmentation if .m file for ID does not exist in the data
% directory
if exist([data_dir 'ft_' int2str(ID) '_pup_preprocess.mat'], 'file') ~= 2
    for b = 1:nblocks
        display(['Defining the trials for block ' int2str(b)])
        
        % only prefix for convienence
        subjDataDir = fullfile(data_dir, int2str(ID)); % platform-independent
        prefixThisFile = fullfile(subjDataDir, ...
                                  [int2str(ID) '_' int2str(b)]); %CAUTION: this file does not really exist

        % Have the trigger names been converted yet?
        if ~exist([prefixThisFile '_ATN.asc'], 'file')
            % adjust the trigger names: MSG -> INPUT
            eyeAdjustTrigNam([prefixThisFile '.asc']);
        end

        thisFile = [prefixThisFile '_ATN.asc'];

        % initialise the config structure for trial definition
        cfg                     = []; 
        cfg.dataset             = thisFile; % ascii converted eyelink filename
        cfg.trialfun            = 'ft_trialfun_general'; 
                % string with filename. Function ft_trialfun_general is
                % called by ft_definetrial and is used when a trial 
                % definition is based on a single trigger
        cfg.headerformat        = 'eyelink_asc';
        cfg.dataformat          = 'eyelink_asc';
        cfg.trialdef.eventtype  = 'INPUT';      % indicate trigger type
        cfg.trialdef.eventvalue = triggerValue; % events of interest
        
        % prestim + poststim info is used to compute number of samples that
        % have to be read
        cfg.trialdef.prestim    = beforeTrigger;    
        cfg.trialdef.poststim   = afterTrigger;    
       
        % Segment the data around the events of interest (epoching)
        cfg                     = ft_definetrial(cfg); 
            % adds field cfg.trl which is a Nx3 matrix
            % each row represents 1 trial

        % save triggers
        cfg.event = ft_read_event(cfg.dataset);

        % Specify the channel for preprocessing data
        cfg.channel             = {'4'};         
            % asc file contains 4 data from channels:
            % % channel 1 represents time
              % channel 2 is the x-coordinate
              % channel 3 is the y-coordinate
              % channel 4 is the pupil dilation

        % read data per trial (default), filter it, and write it to disk (in
        % another format)
        pupb{b}                 = ft_preprocessing(cfg);
        % FIXME: What does this do?
        % Spontaneous guess: baseline correction %JAN24: dont think so
    end

    %% merge data from all blocks 
    cfg = [];

    % specify .mat file name 
    cfg.outputfile = fullfile(data_dir, ['ft_' int2str(ID) '_pup_preprocess']);
    
   
    %%%% PLEASE MODIFY ACCORDINGLY %%%%%%%
    % write combined raw data into the .mat file

    %%% TOBIAS' DATA IS FROM 4 EXPERIMENTAL BLOCKS
    % assert(nblocks==4, ['Your value of nblocks does not match the number of' ...
    %                     'epoched data blocks passed to ft_appenddata.\n' ...
    %                     'Please update the input arguments to ft_appenddata!\n']);
    % pup = ft_appenddata(cfg, pupb{1}, pupb{2}, pupb{3}, pupb{4});
    % 
    %%%%% TESTDATA contains datafiles from 1 block each
    assert(nblocks==1, ['Your value of nblocks does not match the number of' ...
                        'epoched data blocks passed to ft_appenddata.\n' ...
                        'Please update the input arguments to ft_appenddata!\n']);
    pup = ft_appenddata(cfg, pupb{1}); 
    % 
    % FIXME!! find/write an alternative to ft_appenddata since function 
    % cannot be applied iteratively
    %for i=1:nblocks
    %    cfg = ft_appenddata(cfg, pupb{i});
    %end
    %pup = cfg;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % retain trigger (make new field in pup structure)
    pup.triggers = {};
    for b = 1:nblocks
        % triggers between start + end of trial in this block
        TriggersInBthBlock = getTriggers(pupb{b});
        % concatenate row-wise
        pup.triggers = cat(2,pup.triggers, TriggersInBthBlock);
    end

    % get max time per trial
    [C,I] = max(cellfun('length',pup.time(:)));
        % cellfun applies the length function to all elements of pup.time
        % C = 7000
    pup.maxtime = pup.time{I}; % save for plotting later

    %save([data_dir '/ft_' int2str(ID) '_pup_preprocess.mat'],'pup');
    save([cfg.outputfile '.mat'], 'pup');

else
    %load([data_dir '/ft_' int2str(ID) '_pup_preprocess.mat']);
    load([data_dir 'ft_' int2str(ID) '_pup_preprocess.mat']);
end