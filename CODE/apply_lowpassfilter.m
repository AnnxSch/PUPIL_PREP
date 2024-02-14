function pup = apply_lowpassfilter(pup, lp_cutoff)

% This function low-pass filters the data using a cut-off frequency of
% lp_cutoff Hz. 
%
% pup = apply_lowpassfilter(pup, lp_cutoff)
%
% input arguments:
% pup: structure containing pupil data corrected for blinks
% lp_cutoff: cut-off frequency of the low-pass filter
%
% ouput: 
% pup: structure in which data in field 'trial' has been low-pass filtered

%%
fprintf('*******Low-pass filtering the data (cut-off frequency %3.2f Hz)*******\n', lp_cutoff)

% temporarily store trigger, maxtime and number of proper blink, etc information
tmp_tr = pup.triggers;
tmp_mt = pup.maxtime;
tmp_nbl = pup.nblinks;
tmp_nbelow = pup.nbelow; % #blink-associated datapoints
tmp_bfrac = pup.bfrac;  % fraction of sampled data corresponding to blinks
tmp_bPercent = pup.bPercent; % percentage of blink-related data
tmp_bInterpN = pup.bInterpN; % #blink-related datapoints
tmp_mbInterpN = pup.mbInterpN; % #miniblink-related datapoints
tmp_mbPercent = pup.mbPercent; % percentage of miniblink-associated data


% initialise the configuration structure for low-pass filtering
cfg = [];
cfg.lpfilter = 'yes';
cfg.lpfreq = lp_cutoff;

% apply low-pass filter with a cut-off frequency of 30 Hz
pup = ft_preprocessing(cfg, pup);
    % low-pass-filtering requires DSP System + Signal Processing Toolbox

% add temporarily stored info
pup.triggers = tmp_tr;
pup.maxtime = tmp_mt;
pup.nblinks = tmp_nbl;
pup.nbelow = tmp_nbelow;
pup.bfrac = tmp_bfrac;
pup.bInterpN = tmp_bInterpN;
pup.bPercent = tmp_bPercent;
pup.mbInterpN = tmp_mbInterpN;
pup.mbPercent = tmp_mbPercent;