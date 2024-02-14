% function outfile = eyeAdjustTrigNam(infile,orgTrigNam,newTrigNam)
%
% triggers in eyelink file are indicated by 'MSG'. However, fieldtrip
% requires it to be called 'INPUT'. This function adjusts these prefixes
% and writes a new file which should be readable by fieldtrip.
%
% @infile: file of original eyelink ascii-file
% @orgTrigNam: prefix of original triggers (default: 'MSG')
% @newTrigNam: prefix of new triggers (default: 'INPUT': readable by
% fieldtrip)
% @outfile: name of output-file
%
% TH, 10.14
%
%
% Anne: function was modified to prevent trig renaming for MSG lines 
% with !Mode message (presumably occur only in the beginning of the file?)

function outfile = eyeAdjustTrigNam(infile,orgTrigNam,newTrigNam)

if nargin < 3; newTrigNam = 'INPUT'; end
if nargin < 2; orgTrigNam = 'MSG'; end

fprintf('converting file...')

% read file
fid=fopen(infile,'r','n',"US-ASCII"); %file access type, order for reading, character encoding
% fid is integer file identifier now
% fid = -1 if file cannot be opened
C = textscan(fid,'%s','delimiter','\n'); %cell array of text data
fclose(fid);

% replace orgTrigNam (start at line 27)
for i = 28:length(C{1})
    [in,o] = regexp(C{1}{i},orgTrigNam); %in::starting indices where orgTrigNam is found
                                         %o::ending indices for each match
    
    ModeExclamationmark = contains(C{1}{i}, '!MODE');

    if ~isempty(in) & ~ModeExclamationmark;
        C{1}{i} = [newTrigNam C{1}{i}(o+1:end)]; %account for more chars in newTrigNam
        %C{1}{i} = [newTrigNam C{1}{i}(o+1:end) '  ']; %account for more chars in newTrigNam
    end
%     [in,o] = regexp(C{1}{i},'Trigger ');
%     if ~isempty(in)
%         C{1}{i} = [C{1}{i}(1:in-1) C{1}{i}(o+1:end)];
%     end
end


% outfile

[path,name,ext] = fileparts(infile); %file path, file name, file extension
                                     %here: ext=.asc (input is asc)
%FIX: creates name XOR path to output file: 
%outfile = [path + "/" + name + "_ATN" + ext]; 
%outfile = [path '/' name '_ATN' ext]; 
outfile = fullfile(path, [name '_ATN' ext]);

% write to file
fid=fopen(outfile,'wt','n','US-ASCII');
for i = 1:length(C{1})
    fprintf(fid,C{1}{i});
    fprintf(fid,'\n');
end
fclose(fid);

fprintf(' done\n')
end