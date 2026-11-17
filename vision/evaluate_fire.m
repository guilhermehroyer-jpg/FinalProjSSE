%% EVALUATE_FIRE  Tune the fire rules on training images, report a confusion matrix on test images.
%
% Collect images with live_fire.m (press f / n). Tune C.fire.rules in config.m.
% Vary the conditions:
%   data/images/fire/    target at different distances (0.3-2 m), angles,
%                     positions in the frame, lighting
%   data/images/nofire/  the room without the target, ESPECIALLY other red or
%                     orange things (clothes, bags, fire extinguisher, skin, wood)
%
% Move the camera between saves: consecutive frames are almost identical,
% and identical images in both training and test sets inflate the score.

clear; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths
C = config();
rng(1);
classes   = {'fire', 'nofire'};
testShare = 0.3;

F_all = []; label = {}; isTest = false(0, 1); names = {};
for c = 1:numel(classes)
    files = dir(fullfile(C.paths.imageData, classes{c}, '*.png'));
    if isempty(files), error('No images in data/images/%s', classes{c}); end
    testIdx = randperm(numel(files), round(testShare*numel(files)));
    for i = 1:numel(files)
        img = imread(fullfile(files(i).folder, files(i).name));
        F = fire_features(img, C.fire.mask);
        F_all = [F_all; F]; %#ok<AGROW>
        label{end+1, 1}  = classes{c}; %#ok<SAGROW>
        isTest(end+1, 1) = ismember(i, testIdx);
        names{end+1, 1}  = files(i).name; %#ok<SAGROW>
    end
end

truth = strcmp(label, 'fire');
pred  = false(size(truth));
why   = cell(size(truth));
for k = 1:numel(F_all)
    [pred(k), why{k}] = classify_fire(F_all(k), C.fire.rules);
end
tr = ~isTest;
fprintf('%d images: %d training, %d test\n', numel(truth), sum(tr), sum(isTest));

%% Step 1: features per class on TRAINING images -> choose thresholds
feat = {'area', 'extent', 'circularity', 'meanSat'};
figure('Name', 'Fire features per class (training images)');
for k = 1:numel(feat)
    subplot(1, numel(feat), k);
    v = [F_all(tr).(feat{k})]';
    boxchart(categorical(label(tr)), v);
    title(feat{k});
end

%% Step 2: which training images go wrong, and why?
wrong = find(tr & truth ~= pred);
if ~isempty(wrong)
    fprintf('\nMisclassified training images:\n');
    for k = wrong(:)'
        fprintf('  %-28s true=%-6s  %s\n', names{k}, label{k}, why{k});
    end
end

%% Step 3: confusion matrices (report the TEST one)
report('Fire detector - training images', truth(tr), pred(tr));
report('Fire detector - test images',     truth(isTest), pred(isTest));

function report(name, truth, pred)
TP = sum( truth &  pred);   FN = sum( truth & ~pred);
FP = sum(~truth &  pred);   TN = sum(~truth & ~pred);
fprintf('\n%s (%d images)\n', name, numel(truth));
fprintf('                 predicted fire   predicted other\n');
fprintf('actual fire      %14d   %15d\n', TP, FN);
fprintf('actual other     %14d   %15d\n', FP, TN);
fprintf('accuracy %.1f%%   precision %.1f%%   recall %.1f%%\n', ...
    100*(TP+TN)/numel(truth), 100*TP/(TP+FP), 100*TP/(TP+FN));
figure('Name', name);
heatmap({'fire', 'other'}, {'fire', 'other'}, [TP FN; FP TN], ...
    'XLabel', 'Predicted', 'YLabel', 'Actual', 'Title', name);
end
