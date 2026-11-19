%% LIVE_FIRE  Live fire detection: colour layers + shape template + confirmation.
%
%   Left:   camera image. Box around the best candidate:
%           green = passes all rules, yellow = rejected (the title says why)
%   Middle: colour mask (red, orange and yellow pixels, cleaned)
%   Right:  shape match. White = blob and template overlap,
%           green = template only, magenta = blob only.
%   "CONFIRMED" = passed in at least 2 of the last 3 frames, which is what the
%   robot uses (detect_fire.m), so single-frame flickers are ignored.
%
%   Keys (click the figure window first):
%     f  save the current frame to data/images/fire/    (flame IS in view)
%     n  save the current frame to data/images/nofire/  (flame NOT in view)
%   Close the window to stop.

clear cam; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths

C     = config();                     % camera name, resolution and thresholds live here
scale = C.camera.scale;
T     = fire_template(C);

cam = webcam(C.camera.name);
cam.Resolution = C.camera.resolution;

for d = {'fire', 'nofire'}
    if ~exist(fullfile(C.paths.imageData, d{1}), 'dir'), mkdir(fullfile(C.paths.imageData, d{1})); end
end

%% Set up the figure once
img = imresize(snapshot(cam), scale);
fig = figure('Name', 'Fire detection - close to stop   (f = save fire, n = save no fire)', ...
             'Position', [60 200 1400 420]);
set(fig, 'KeyPressFcn', @(src, evt) setappdata(src, 'key', evt.Character));

ax1 = subplot(1, 3, 1);
hImg = imshow(img); hold on;
hBox   = rectangle('Position', [1 1 1 1], 'EdgeColor', 'g', 'LineWidth', 2, 'Visible', 'off');
hCross = plot(NaN, NaN, '+', 'MarkerSize', 14, 'LineWidth', 2);
ax2 = subplot(1, 3, 2);
hMask = imshow(false(size(img, 1), size(img, 2)));
title(ax2, 'Colour mask');
ax3 = subplot(1, 3, 3);
hShape = imshow(double(cat(3, false(size(T)), T, false(size(T)))));
title(ax3, 'Shape match');

%% Main loop
nSaved  = 0;
history = false(1, C.fire.confirmFrames);    % results of the last frames
while ishandle(fig)
    img = imresize(snapshot(cam), scale);
    [F, mask] = fire_features(img, C);
    [isFire, failed] = classify_fire(F, C.fire.rules);
    history = [history(2:end), isFire];
    confirmed = sum(history) >= C.fire.confirmMin;

    hImg.CData  = img;
    hMask.CData = mask;
    hShape.CData = double(cat(3, F.shape, T, F.shape));   % R and B = blob, G = template

    if F.found
        col = 'y';  if isFire, col = 'g'; end
        set(hBox, 'Position', F.bbox, 'EdgeColor', col, 'Visible', 'on');
        set(hCross, 'XData', F.centroid(1), 'YData', F.centroid(2), 'Color', col);
    else
        set(hBox, 'Visible', 'off');
        set(hCross, 'XData', NaN, 'YData', NaN);
    end

    if confirmed
        title(ax1, sprintf('CONFIRMED FIRE | steer %+.2f | area %.2f%%', F.steer, 100*F.area), ...
              'Color', [0 0.6 0]);
    elseif isFire
        title(ax1, 'fire in this frame (not confirmed yet)', 'Color', [0.8 0.6 0]);
    else
        title(ax1, ['no fire: ' failed], 'Color', 'k', 'Interpreter', 'none');
    end
    title(ax3, sprintf(['shape %.2f  aspect %.2f\nred %.0f%%  orange %.0f%%  ' ...
        'yellow %.0f%%  core at %.2f'], F.shapeIoU, F.aspect, 100*F.fracRed, ...
        100*F.fracOrange, 100*F.fracYellow, F.yellowPos));

    % Save frames for evaluation
    key = getappdata(fig, 'key');
    if ~isempty(key)
        setappdata(fig, 'key', '');
        if any(key == 'fn')
            folder = 'fire';  if key == 'n', folder = 'nofire'; end
            name = sprintf('%s_%s.png', folder, char(datetime('now', 'Format', 'HHmmssSSS')));
            imwrite(img, fullfile(C.paths.imageData, folder, name));
            nSaved = nSaved + 1;
            fprintf('saved %s (%d this session)\n', name, nSaved);
        end
    end

    drawnow;
end
clear cam
