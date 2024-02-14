function pup = pup_preprocess_Anne_modular_selfpaced(ID, data_dir, ...
                                                     nblocks, fieldtrip_dir, verbose1, fig_dir)
% This is a rewritten function definition of Tobias' pup_preprocess.m
% agenda: 
% (1) read and epoch: create fieldtrip structure for the given subject
% (2) descriptive statistics
% (3) interpolate blinks
% (4) low-pass filter
% (5) calculate % corrected
% (6) substractive baseline correction
%                                    _____________REQUIRED_____________    
%                                   /                                  \  
% pup = pup_preprocess_Anne_modular(ID, data_dir, nblocks, fieldtrip_dir,...
%                                   verbose1, fig_dir)
%                                   \___OPTIONAL____/
%                                       
% REQUIRED input arguments:
% ID: subject identifier
% data_dir: string specifying the path to directory containing the data. The
% target location should contain a separate folders names <ID> in which the 
% raw asc files named '<ID>_<1:nblocks>.asc' are stored.
% nblocks: number of blocks in the experiment
% fieldtrip_dir: string specifying the path to the fieldtrip toolbox
%
% OPTIONAL input arguments:
% verbose1: boolean flag indicating whether to plot intermediate
% preprocessing steps. The default is set to 1.
% fig_dir: string specifying the designated directory for created figures.
% The default destination is the pwd.
% 
% output: 
% pup: structure containing pre-processed pupil data in field 'trial'
%
% side effect:
% - creates 'ft_<ID>_pup_preprocess.mat' files in which the raw, but
% epoched data is stored
% - if verbose1: creates histogram based on raw data
% - if verbose2: creates figure of the data at different stages 
% of the preprocessing procedure 
% - if verbose3: creates explanatory figures illustrating how the 
% parameter values used in the preprocessing steps should be interpreted. 

% make the arguments verbose2 and fig_dir optional and set defaults
arguments 
    ID            (1,:) double
    data_dir      (1,:) char
    nblocks       (1,:) double
    fieldtrip_dir (1,:) char
    verbose1      (1,:) double = 1 % 1 for plotting un/preprocessed pupil data
    fig_dir       (1,:) char = pwd % save figures to pwd
end

verbose2 = 1;   % 1 for plotting the pupil size changes over the course of whole experiment
verbose3 = 0;   % 1 for plotting the spread of the raw data 
verbose4 = 1;   % 1 for creating explanatory visualizations of preprocessing steps

%% parameters

%%%% Please modify %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% parameters for data segmentation
triggerValue = 90; % DATA: 80, TESTDATA: 90

%%%% please also un/comment the following sections 

% OPTION 1: Define the value of the trigger associated with the end 
% of a trial. If this option is selected, trials may vary in length.
%%% use this option for TESTDATA!
EOTvalue = 91; % end of the trial trigger
beforeTrigger = -1; % default
afterTrigger  = -1; % default, epoching will only depend on EOTvalue

% OPTION 2: Fixed trial lengths
% If the trials are of fixed length or the value of the trigger marking
% the end of a trial is unknown, the number of seconds to include before
% and after triggerValue occurred should be specified.  
%%% use this option for DATA!
% beforeTrigger = 1;  % 1 s before trigger |  
% afterTrigger  = 6;  % 6 s after trigger  |-> trial length: 7 s
% EOTvalue = [];      % default, epoching will not depend on EOTvalue
% optional according to fieldtrip 

%%%% If neither EOTvalue, nor beforeTrigger or afterTrigger are specified,
%%%% each "epoch" will only include the sample collected directly after
%%%% triggerValue.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% parameters for (proper) eye blink interpolation 
lowerbound = 1000; % threshold for eyeblink in arbitrary dilation units
%lwb_mode = convertStringsToChars(["'arbitrarily' set to " + num2str(lowerbound)]); % for note on figure if verbose2
lwb_mode = '1000AU';
    % idea: calculate mean and sd of pupil measures for each trial
    % -> define blinks as zero values || measurements more than 3 (2?) SD smaller 
    % than mean pupil size
    % better idea: use median since this quantity is more robust to outliers
    % -> Ehsan: quantiles
tpIntp = 100;  % interpolate +- 100 samples around blink target (blinks typically last for 100-150 ms)
eyeblink_corr = 'linear';

% parameters for miniblink interpolation
timewin = 5;
delta_cutoff = -30;
interp_win = 200; 
maximum_miniblink_index_duration = 1000; %Anne %FIX why 1000?

% parameters for lowpass filtering
lp_cutoff = 30; % cut-off frequency of 30 Hz

% parameters for extrapolating onset mini-blinks
d2_crit = .6; %.8; % FIXME: why .6?
def_beginning = 1000;
start_search = 101;
sc_start = 100;
sc_end = 300;
sc_d_crit = .05;
interp_win_onsetMiniblinks = 500;

% for rejecting trials that have abnormally large amplitudes
%rej_thresh = inf;%1500;%3000;% % reject trials with amplitudes above this threshold

% parameters for excluding trials or subjects due to poor data integrity
% set both parameters to 1 for no exclusion
trlInclusion = 0.75; % exclude trials if > 75% of the trialdata had to be corrected
sbjInclusion = 0.5; % exclude subjects if > 50% of their data had to be corrected

% parameters for baseline correction
idxEndBaseline = 1999; % the first 2000 samples serve as baseline data


%% read the raw data from the .asc file and define trials
pup = readingRawData_selfpaced(ID, data_dir, ...
                               nblocks, triggerValue, ...
                               fieldtrip_dir, ...
                               EOTvalue, ...
                               beforeTrigger, afterTrigger);

%% compute descriptive statistics of NONZERO raw data
% will be used for (onset) mini/blink detection
fprintf('*******Computing descriptive statistic of raw data...*******\n');

% calculate summary statistics (mean, sd, P15) based on NONZERO! data
for t = 1:length(pup.trial)
    [pup.trlMeans(t), pup.trlSDs(t), pup.trlP15s(t)] = trialStats(pup.trial{t});
end

% across trials (again, disregarding 0s)
pup = pupilStats(ID, pup, verbose3, fig_dir); 

%% set lowerbound based on summary statistics

%%% OPTION 1: 15th percentile (nonzero data)
% fprintf('The 15th percentile of the nonzero raw data is %4.2f AU.\nSet the 15th percentile as a lowerbound for eyeblink detection.\n', ...
%        pup.glblP15_raw);
% lowerbound = pup.glblP15_raw;
% lwb_mode = "P15nz"; 

%%% OPTION 2: three standard deviations away from the mean (nonzero data)
% fprintf('Set [mean - 3 sds] (as as a lowerbound for eyeblink detection.\n');
% lowerbound = pup.glblmean_raw - 3 * pup.glblsd_raw;
% lwb_mode = "mean3sd"; 

%%% OPTION 3: two standard deviations away from the mean
% fprintf('Set [mean - 2 sds] (as as a lowerbound for eyeblink detection.\n');
% lowerbound = pup.glblmean_raw - 2 * pup.glblsd_raw;
% lwb_mode = "mean2sd"; 

fprintf('... done computing descriptive statistics.\n');

%% plot the raw pupil size changes throughout each trial 
if verbose1
    % create new figure window
    f1 = figure('Name', 'Pupil Trajectories', 'units','normalized', ...
                'OuterPosition',[0 0 1 1],'Color','w');
    set(gcf,'Unit','centimeters','OuterPosition',[0 0 40 30]);
    set(gcf,'PaperPositionMode','auto');
    subplot(4,1,1)
    %sgtitle("pupil size trajectory for subject " + int2str(ID) + " over course of each trial (" + lwb_version + ")");
    plotAllTrials(ID, pup, "unprocessed", lwb_mode, fig_dir);
end 

%% plot the raw pupil size changes throughout the whole experiment
if verbose2
    f2 = figure('Name', 'Experiment-wide pupil trajectories', ...
                'OuterPosition',[0 0 1 1],'Color','w');
    plotWholeExperiment(ID, pup, fig_dir);
end

%% interpolate blinks 
fprintf('*******Interpolating (proper) eyeblinks (lowerbound %4.2f)...*******\n', lowerbound)

% start creating a visualization for an example single trial 
if verbose4
    if ID == 908
    f4 = figure('Name','Visualization of blink correction');
    visualizeBlinkInterp(ID, pup.trial{10}, pup.maxtime, ...    % use trial 10
                         lowerbound, tpIntp, eyeblink_corr, ...
                         fig_dir); 
    end
end


% identify proper eyeblinks and replace corresponding data by interpolation
% to increase statistical power
for t = 1:length(pup.trial)

    % FIXME!!
    % % find most conservative threshold?
    % lowerbound = max([pup.trlMeans(t) - 2*pup.trlSDs(t), ...
    %                   pup.glblmean - 2*pup.glblsd]);

    [pup.trial{t}(end,:), pup.nbelow(t), pup.nblinks(t), pup.bInterpN(t)] = ...  
             interpolate_properBlinks(pup.trial{t}(end,:), lowerbound, tpIntp, ...
                                         eyeblink_corr);
    % nbelow(t) is number of pupil data points below lowerbound (incl. nblinks)
    % nblinks(t) is number of proper blinks in trial t
    
    % compute the fraction of corrected data points in current trial    
    pup.bfrac(t) = pup.bInterpN(t)/length(pup.maxtime);
    % if pup.bfrac(t) > trlInclusion
    %     fprintf('CAUTION! Too few valid data points in trial %4.0f (%4.2f %% below threshold)\n', t, pup.bfrac(t) * 100);
    % end
end

% total percentage of OG data points associated with blinks (across trials)
pup.bPercent = sum(pup.bInterpN) / (length(pup.trial) * length(pup.maxtime)) * 100;
fprintf('For subject %4.0f, %4.2f %% of the data pupil data is now interpolated.\n', ...
        ID, pup.bPercent);

fprintf('... done correcting proper blinks.\n');

%% replace miniblinks based on diff 
fprintf('*******Interpolating miniblinks (delta_cutoff %4.2f)*******\n', delta_cutoff)

for t = 1:length(pup.trial)
  [pup.trial{t}(end,:), pup.mbInterpN(t)] = ...
                  interpolate_miniblinks(pup.trial{t}(end,:), delta_cutoff, ...
                                         interp_win, ...
                                         maximum_miniblink_index_duration);
end

% total percentage of miniblinks (across trials)
pup.mbPercent = sum(pup.mbInterpN) / (length(pup.trial) * length(pup.maxtime)) * 100; 
fprintf('In subject %4.0f, %4.2f %% of the data were miniblinks.\n', ...
        ID, pup.mbPercent);
fprintf('... done correcting miniblinks.\n');

%% exclude trials which are below the threshold
% check for outlying samples/trials and remove trials which fail to meet
% the inclusion criterion of > 25% valid data points
% CAUTION: overwrites pup here
%[pup, percKept] = excludeTrials(pup, lowerbound);
%fprintf('%4.2f %% of the trials were exluded', 1 - percKept);

%% detrend trials
% commented out in Tobias' code

%% lowpass filter
% cognitive (real, ≠relevant?) effects on pupil size emerge slowly
% (fact check: approx. 500ms after trigger stimulus earliest?!) 
pup = apply_lowpassfilter(pup, lp_cutoff); % low-pass-filtering requires DSP System or Signal Processing Toolbox

%% plot all trials to see impact of blink correction
if verbose1
    figure(f1)
    subplot(4,1,2);
    plotAllTrials(ID, pup, "blink", fig_dir);
end

%% reject trials which go past ### in amplitude
% commented out in Tobias' code

%% extrapolate data in trials with (half-)closed eyes in the beginning
fprintf('*******Correcting onset mini-blinks...*******\n')

for t = 1:length(pup.trial)
    [pup.trial{t}(end,:), pup.ombExtrapN(t)] = ...
            extrapolate_initialPupilSizes(pup.trial{t}(end,:), ...
                            d2_crit, def_beginning, start_search, sc_start, ...
                            sc_end, sc_d_crit, interp_win_onsetMiniblinks);
end

% total percentage of onset miniblinks (across all trials)
pup.ombPercent = sum(pup.ombExtrapN) / (length(pup.trial) * length(pup.maxtime)) * 100;
fprintf('In the data for subject %4.0f, %4.2f %% of the data points are onset miniblinks.\n', ID, pup.ombPercent);

fprintf('... done extrapolating onset miniblinks.\n')


%% percentage of corrected data
fprintf('*******Checking data integrity...*******\n');

% array that holds identifiers of valid trials
validTrials = [];

% percentage of inter/extrapolated data per trial 
for t=1:length(pup.trial)
    pup.proportionEstimated(t) = (pup.bInterpN(t) + pup.mbInterpN(t) + pup.ombExtrapN(t)) / ...
                                 length(pup.maxtime);
    
    % Tobias, 2016: Any trial where more than 25% of samples were marked as
    % blinks were rejected from the analysis
    if pup.proportionEstimated(t) > trlInclusion
        fprintf('CAUTION! Trial %4.0f in subject %4.0f contains too few valid datapoints (%4.2f %% estimated)!\n', ...
                t, ID, pup.proportionEstimated(t) * 100);
    else 
        validTrials = [validTrials, t];
    end
end

% total percentage of inter/extrapolated data points across all trials
pup.totalcorrectedProportion = sum(pup.proportionEstimated) / length(pup.trial);

% consider excluding subject if > (50%?) of his/her data are invalid
if pup.totalcorrectedProportion > sbjInclusion
    fprintf('CAUTION! A substantial proportion of data from subject %4.0f is unreliable (%4.2f %% estimated)!\n', ...
            ID, pup.totalcorrectedProportion);
end

fprintf('... done.\n');

%% exclude trials which are below the threshold
fprintf('*******Exclude trials...*******\n');

% filter out trials that have been deemed to be untrustworthy (not in
% validTrials
pup = excludeTrials(pup, validTrials);
fprintf('For subject %4.0f, a total of %4.0f trials (%4.2f %%) have been excluded.\n', ...
        ID, pup.nRemoved, pup.nRemoved/length(pup.trial) *100);

%% plot all trials
if verbose1
    figure(f1)
    subplot(4,1,3);
    plotAllTrials(ID, pup, "completed", fig_dir);
    
end

%% visually reject trials
% commented out in Tobias' code

%% <baseline data preprocessing>
% commented out in Tobias' code (section titled baseline correct)

%% get max time per trial - again
[C,I] = max(cellfun('length',pup.time(:)));
pup.maxtime = pup.time{I};

%% baseline correct
fprintf('*******Perform (substractive? FIXME) baseline correction*******\n');
pup.rej_trial = [];
tmp_tr = pup.triggers;
tmp_mt = pup.maxtime;
tmp_rej = pup.rej_trial;
tmp_nblinks = pup.nblinks;
cfg = [];
cfg.demean = 'yes';
cfg.channel = {'4'};
cfg.baselinewindow = [-.5 0];
pup                     = ft_preprocessing(cfg, pup);
pup.triggers = tmp_tr;
pup.maxtime = tmp_mt;
pup.rej_trial = tmp_rej;
pup.nblinks = tmp_nblinks;

fprintf('... done\n');

if verbose1
    figure(f1)
    subplot(4,1,4);
    dat = nan(length(pup.trial),length(pup.maxtime));
    for t = 1:length(pup.trial)
        dat(t,1:length(pup.trial{t})) = pup.trial{t}(end,:);
    end
    plot(pup.maxtime,dat)
    xlim([pup.maxtime(1), pup.maxtime(end)]); % formatting
    title("after baseline correction");
    % construct complete file path for saving the figure 
    fg_fldr = fullfile(fig_dir, int2str(ID)); % platform-independent

    fg_nm   = fullfile(fg_fldr, [int2str(ID) '_trial_preprocessing_' lwb_mode '.pdf']);
    
    % create folder <ID> within fig_dir if it doesn't exist already
    if ~exist("fg_fldr", "dir")
        mkdir(fg_fldr);
    end

    % save figure as a PDF in folder '<ID>' within fig_dir
    orient(gcf,'landscape') % change orientation for printing
    print('-dpdf',fg_nm, '-bestfit');
    close all
end

%% difference wave
% fprintf('*******Perform baseline correction*******\n');
% 
% % Tobias distinguishes between conditions -> TODO
% 
% % take the first 2000 samples of each trial as a baseline 
% %BL = pup.trial{:}(1:idxEndBaseline); 
% BL = cellfun(@(t) t(1:idxEndBaseline), pup.trial, 'UniformOutput', false);
% %BL = reshape([BL], 1, length(pup.trial));
% meanBL = cellfun(@(bl) mean(bl), BL, 'UniformOutput', false); % average over baseline
% 
% % substractive baseline correction
% for t = 1:length(pup.trial)
%     pup.trial{t} = pup.trial{t} - meanBL{t};
% end
% %pup.trial{:} = pup.trial{:} - repmat(meanBL, 1, length(pup.trial))
% 
% if verbose2
%     figure(f1)
%     subplot(4,1,3);
%     plot(pup.maxtime, pup.trial);
%     title("after baseline correction");
    % fg_fldr = fullfile(fig_dir, int2str(ID)); % platform-independent
    % fg_nm   = fullfile(fg_fldr, [int2str(ID) '_trial_preprocessing_AU.pdf']);
    % 
    % % create folder <ID> within fig_dir if it doesn't exist already
    % if ~exist("fg_fldr", "dir")
    %     mkdir(fg_fldr);
    % end
    % 
    % % save figure as a PDF in folder '<ID>' within fig_dir
    % orient(gcf,'landscape') % change orientation for printing
    % print('-dpdf',fg_nm, '-bestfit');
% end

%figure(f1)
% path = '~/Documents/Studium/Kognitionswissenschaft/7. Semester/Bachelor thesis/Preprocessing eye tracking data/PREPROCESSING/preprocessing_modular';
% 
% fg_nm = [path '/FIGURES/' int2str(ID) '_trial_preprocessing_AU_baseline.jpg'];
% print('-djpeg',fg_nm);
% close all

fprintf('Done preprocessing subject %3.0f.\n\n\n', ID);
