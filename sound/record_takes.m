%% RECORD_TAKES  Record labelled 2 s clips into data/sound/<folder>/.
%
% Folders:
%   help/     "help" spoken normally AND screamed (both!)
%   nothelp/  similar words ("hello", "hell", "yelp", "hey"), screams without
%             words, talking, coughs, claps, the robot's motors
%   cry/      cries and screams           (for stage 1, sound/evaluate_rules.m)
%   other/    everything that is not a cry (for stage 1)
%
% Aim for at least 10 takes per person per folder.

clear;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths
C   = config();
Fs  = C.sound.Fs;
dur = 2;                                % seconds per take

folder   = input('Folder (help / nothelp / cry / other): ', 's');
initials = input('Your initials: ', 's');
n        = input('How many takes? ');

outDir = fullfile(C.paths.soundData, folder);
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

rec = audiorecorder(Fs, 16, 1, C.sound.micID);
for k = 1:n
    input(sprintf('Take %d/%d: press Enter, then speak...', k, n), 's');
    recordblocking(rec, dur);
    y = getaudiodata(rec);
    stamp = char(datetime('now', 'Format', 'HHmmssSSS'));
    name  = sprintf('%s_%s_%s.wav', folder, initials, stamp);
    audiowrite(fullfile(outDir, name), y, Fs);
    fprintf('   saved %s (peak level %.2f; aim for 0.2-0.9)\n', name, max(abs(y)));
end
