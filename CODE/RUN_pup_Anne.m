%% Clear
clear all; close all; clc;

%% TO MODIFY
% directories

repo_dir = fullfile('..');
data_dir = fullfile(repo_dir, 'TESTDATA/');
fig_dir  = fullfile(repo_dir,'FIGURES/');

fieldtrip_path = fullfile(repo_dir, 'TOOLS/fieldtrip-20230118');

% plotting mode
verbose1 = 0; % 1 for plotting intermediate preprocessing steps for trial data
verboseb = 1; % 1 for plotting intermediate preprocessing steps for baseline

% meta information
nblocks = 1;  % blocks in experiment (TESTDATA: 1, DATA: 4)

% NOTE %%%%%%%%%%
%%%%% Please also ADJUST the PARAMETER VALUES in section "parameters" in
%%%%% the beginning of the file 'pup_preprocess_Anne_modular_selfpaced.m'.
%%%%%
%%%%% Moreover, please also MODIFY the ARGUMENTS PASSED to ft_appenddata 
%%%%% in 'readingRawData.m' (between lines 99 to 120) ACCORDING TO the
%%%%% value of NBLOCKS if there are no 'ft_<ID>_pup_preprocess.mat' files 
%%%%% in your data_dir. Unfortunately, ft_appenddata cannot be applied 
%%%%% iteratively and ft_appenddata(cfg, pupb{1}, pupb{2}, pupb{3}, pupb{4}) 
%%%%% will crash if nblocks < 4, for example. I will look into this again 
%%%%% and will try to find a way to fix this inconvienence.
%%%%%%%%%%%%%%%%%

%% get subjects
fprintf(["Get subject data from " + data_dir + "...\n"])

list = dir(data_dir);
sl = [];
for s = 1:length(list)
    try
        % data folders names corresponding to each subject will be stored
        % in sl
        sl = [sl str2num(list(s).name)];
    end
end

assert(~isempty(sl), "Data could not be read from the specified directory. Examine the correctness of the file path.");

% make sure to not use the asc file that is not tab-separated
sl = [sl(sl~=999)];

% for testing
%sl = [sl(3)];
%sl = [101];


%% initialize matrix that will hold pupillometry measures
pup_responsitivity = [];
%% run subjects
for s = 1:length(sl)

    % add current subject ID to output structure
    pup_responsivity(s,1) = sl(s);
    
    % preprocess trial data
    fprintf('Start preprocessing trial data from subject %3.0f...\n', sl(s))
    clear pup  
    pup = pup_preprocess_Anne_modular_selfpaced(sl(s), data_dir, ...
                                                nblocks, fieldtrip_path, ...
                                                verbose1, fig_dir); 
    % Steps for preprocessing:
    % % 1.) EDF -> asc (only tabs as delimiters!): DONE
      % 2.) Create a FieldTrip structure (after: epoched)
      % *.) descriptive statistics
      % 3.) interpolate (mini)blinks
      % 4.) -e-p-o-c-h-
      % *.) low-pass filter
      % *.) extrapolate onset miniblinks
      % *.) percentage estimated/corrected data
      % 5.) plot

   % keep record of average number of blinks in trial data
   nblinks(s) = mean(pup.nblinks);

   % FIXME: pup_bl2peak()
   % res(s) = pup_bl2peak(pup);
   % pup_responsivity(s,2) = res(s).meanPeak; 
   % pup_responsivity(s,3) = res(s).meanPeak/res(s).meanBL;

   
   % preprocess baseline data
   % fprintf('Start preprocessing baseline data from subject %3.0f...\n', sl(s))
   % [pup_responsitivity(s,4) , tmp_bl_pup] = pup_baseline_Anne_modular(sl(s), verboseb);
   % 1st output: avg pupil size over the baseline period after
   % preprocessing
   % 2nd output: preprocessed baseline data
   % FIXME! No baseline files available

   % keep record of number of blinks during baseline 
   % n_bl_blinks(s) = tmp_bl_pup.nblinks;

   % pup_responsivity(s,5) = res(s).meanPeak/pup_responsivity(s,4);

   %ANNE
   save([num2str(sl(s)) '_pup.mat'], 'pup');
end

fprintf('\nDone preprocessing.\n')

%% save 
% save('2018_pupil_summary.mat','pup_responsivity','sl')
% save('2018_blinks.mat','nblinks','sl')
% save('2018_it.mat','n_bl_blinks','sl')
% disp('all done.')
