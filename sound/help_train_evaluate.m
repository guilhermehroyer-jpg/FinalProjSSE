%% HELP_TRAIN_EVALUATE  Build "help" templates, choose the threshold, report the confusion matrix.
%
% Needs data/sound/help/*.wav and data/sound/nothelp/*.wav (record_takes.m).
%
% How the files are used (each file is used for ONE thing only):
%   40% of the "help" files            -> TEMPLATES
%   rest of "help" + all "nothelp"     -> split 50/50 into
%        TUNING files (to choose the threshold)
%        TEST files   (for the confusion matrix in the report)
%
% Each clip gets a score = smallest DTW distance to any template.
% Score <= threshold  ->  "help".

clear; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths
C  = config();
Fs = C.sound.Fs;
rng(1);                                 % same split every run

helpFiles  = dir(fullfile(C.paths.soundData, 'help',    '*.wav'));
otherFiles = dir(fullfile(C.paths.soundData, 'nothelp', '*.wav'));
if numel(helpFiles) < 10 || numel(otherFiles) < 6
    error('Record more clips: at least 10 "help" and 6 "nothelp" files.');
end

%% 1. Templates
helpFiles  = helpFiles(randperm(numel(helpFiles)));     % shuffle
otherFiles = otherFiles(randperm(numel(otherFiles)));
nT = round(0.4*numel(helpFiles));
templFiles = helpFiles(1:nT);
restHelp   = helpFiles(nT+1:end);

templates = cell(nT, 1);
for k = 1:nT
    templates{k} = word_features(read_mono(templFiles(k), Fs), Fs);
end
fprintf('%d templates built\n', nT);

%% 2. Score every other clip (smallest DTW distance to a template)
sHelp  = score_files(restHelp,   templates, Fs);
sOther = score_files(otherFiles, templates, Fs);

hTune = 1:2:numel(sHelp);   hTest = 2:2:numel(sHelp);    % files are shuffled,
oTune = 1:2:numel(sOther);  oTest = 2:2:numel(sOther);   % so alternating is random

%% 3. Choose the threshold on the TUNING files
% Try every tuning score as a threshold and keep the one with the best
% balanced accuracy (average of the recall of both classes), so that the
% bigger "nothelp" class does not dominate.
cand = sort([sHelp(hTune); sOther(oTune)]);
bestBal = -inf;
for t = cand'
    bal = (mean(sHelp(hTune) <= t) + mean(sOther(oTune) > t)) / 2;
    if bal > bestBal
        bestBal = bal;
        thr = t;
    end
end
fprintf('Chosen threshold: %.3f (balanced accuracy on tuning files %.1f%%)\n', thr, 100*bestBal);

figure('Name', 'DTW scores of the tuning files');
edges = linspace(min(cand), max(cand), 20);
histogram(sHelp(hTune),  edges, 'FaceAlpha', 0.6); hold on;
histogram(sOther(oTune), edges, 'FaceAlpha', 0.6);
xline(thr, 'k--', 'threshold', 'LineWidth', 1.5);
xlabel('Smallest DTW distance to a "help" template');
ylabel('Number of clips');
legend('help', 'not help', 'Location', 'best');
title('Smaller distance = more similar to "help"');

%% 4. Confusion matrix on the TEST files (this goes in the report)
truth = [true(numel(hTest), 1); false(numel(oTest), 1)];
pred  = [sHelp(hTest) <= thr; sOther(oTest) <= thr];
report('"help" detector - test files', truth, pred);

if ~exist(fileparts(C.paths.helpModel), 'dir'), mkdir(fileparts(C.paths.helpModel)); end
save(C.paths.helpModel, 'templates', 'thr', 'Fs');
fprintf('Saved templates and threshold to %s\n', C.paths.helpModel);

%% Local functions
function s = score_files(files, templates, Fs)
s = zeros(numel(files), 1);
for k = 1:numel(files)
    C = word_features(read_mono(files(k), Fs), Fs);
    s(k) = min(cellfun(@(T) dtw_distance(C, T), templates));
end
end

function y = read_mono(file, Fs)
[y, fsFile] = audioread(fullfile(file.folder, file.name));
y = mean(y, 2);                          % stereo -> mono
if fsFile ~= Fs
    y = resample(y, Fs, fsFile);
end
end

function report(name, truth, pred)
TP = sum( truth &  pred);   FN = sum( truth & ~pred);
FP = sum(~truth &  pred);   TN = sum(~truth & ~pred);
fprintf('\n%s (%d clips)\n', name, numel(truth));
fprintf('                 predicted help   predicted other\n');
fprintf('actual help      %14d   %15d\n', TP, FN);
fprintf('actual other     %14d   %15d\n', FP, TN);
fprintf('accuracy %.1f%%   precision %.1f%%   recall %.1f%%\n', ...
    100*(TP+TN)/numel(truth), 100*TP/(TP+FP), 100*TP/(TP+FN));
figure('Name', name);
heatmap({'help', 'other'}, {'help', 'other'}, [TP FN; FP TN], ...
    'XLabel', 'Predicted', 'YLabel', 'Actual', 'Title', name);
end
