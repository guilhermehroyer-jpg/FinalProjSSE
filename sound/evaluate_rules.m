%% EVALUATE_RULES  Tune the rules on training files, then report a confusion matrix.
%
% Put your .wav files in these folders:
%   data/sound/cry/     children crying + people screaming "help!"
%   data/sound/other/   normal speech, music, the car's motors, room noise, clapping...
%
% Each file is cut into 1 s windows. 30% of the FILES (not windows) of each
% class are held out as the test set. Windows from one recording sound very
% alike, so splitting by window would make the test accuracy look too good.

clear; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths

C  = config();
Fs = C.sound.Fs;
L  = Fs;                              % 1 s windows
classes   = {'cry', 'other'};
testShare = 0.3;
rng(1);                               % same train/test split every run

feats  = [];
label  = {};
isTest = false(0, 1);

for c = 1:numel(classes)
    files = dir(fullfile(C.paths.soundData, classes{c}, '*.wav'));
    if isempty(files)
        error('No .wav files found in data/sound/%s', classes{c});
    end
    testIdx = randperm(numel(files), round(testShare*numel(files)));

    for i = 1:numel(files)
        [y, fsFile] = audioread(fullfile(files(i).folder, files(i).name));
        y = mean(y, 2);                                   % stereo -> mono
        if fsFile ~= Fs
            y = resample(y, Fs, fsFile);                  % e.g. 44.1 kHz -> 16 kHz
        end
        if length(y) < L
            y(end+1:L) = 0;                               % pad clips shorter than 1 s
        end

        starts = 1:L:length(y)-L+1;
        winRms = arrayfun(@(s) sqrt(mean(y(s:s+L-1).^2)), starts);
        keep   = winRms >= 0.1*max(winRms);               % skip silent parts of a clip

        for s = starts(keep)
            F = extract_features(y(s:s+L-1), Fs);
            feats = [feats; F]; %#ok<AGROW>
            label{end+1, 1}  = classes{c}; %#ok<SAGROW>
            isTest(end+1, 1) = ismember(i, testIdx);
        end
    end
end

truth = strcmp(label, 'cry');
pred  = false(size(truth));
for k = 1:numel(feats)
    pred(k) = classify_window(feats(k));
end
tr = ~isTest;
fprintf('%d windows: %d training, %d test\n', numel(truth), sum(tr), sum(isTest));

%% Step 1: look at the features per class (TRAINING files only) to choose thresholds
names = {'rms', 'peakFreq', 'flatness', 'voicedFrac', 'bandRatio'};
figure('Name', 'Features per class (training files)');
for k = 1:numel(names)
    subplot(1, numel(names), k);
    v = [feats(tr).(names{k})]';
    boxchart(categorical(label(tr)), v);
    title(names{k});
end

%% Step 2: which rules make us miss cries? (training files)
missed = find(tr & truth & ~pred);
if ~isempty(missed)
    fprintf('\nMissed cries in training (first 15) and the rules they failed:\n');
    for k = missed(1:min(15, end))'
        [~, why] = classify_window(feats(k));
        fprintf('  %s\n', why);
    end
end

%% Step 3: confusion matrices. Tune on training; report the TEST numbers.
report('Training files', truth(tr), pred(tr));
report('Test files', truth(isTest), pred(isTest));

function report(name, truth, pred)
TP = sum( truth &  pred);   FN = sum( truth & ~pred);
FP = sum(~truth &  pred);   TN = sum(~truth & ~pred);
acc  = (TP + TN) / numel(truth);
prec = TP / (TP + FP);
rec  = TP / (TP + FN);

fprintf('\n%s (%d windows)\n', name, numel(truth));
fprintf('                predicted cry   predicted other\n');
fprintf('actual cry      %13d   %15d\n', TP, FN);
fprintf('actual other    %13d   %15d\n', FP, TN);
fprintf('accuracy %.1f%%   precision %.1f%%   recall %.1f%%\n', ...
    100*acc, 100*prec, 100*rec);

figure('Name', name);
heatmap({'cry', 'other'}, {'cry', 'other'}, [TP FN; FP TN], ...
    'XLabel', 'Predicted', 'YLabel', 'Actual', 'Title', name);
end
