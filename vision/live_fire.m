%% LIVE_FIRE  Live red-target ("fire") detection with the Microsoft LifeCam.
%
%   Left: camera image with the detected blob (green box = FIRE, yellow = red
%   blob that failed a rule). Right: the cleaned binary mask.
%
%   Keys (click the figure window first):
%     f  save the current frame to data/images/fire/    (target IS in view)
%     n  save the current frame to data/images/nofire/  (target NOT in view)
%   Close the window to stop.

clear cam; close all;
run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths

C     = config();                     % camera name, resolution and thresholds live here
scale = C.camera.scale;

cam = webcam(C.camera.name);
cam.Resolution = C.camera.resolution;

for d = {'fire', 'nofire'}
    if ~exist(fullfile(C.paths.imageData, d{1}), 'dir'), mkdir(fullfile(C.paths.imageData, d{1})); end
end

%% Set up the figure once
img = imresize(snapshot(cam), scale);
fig = figure('Name', 'Fire detection - close to stop   (f = save fire, n = save no fire)');
set(fig, 'KeyPressFcn', @(src, evt) setappdata(src, 'key', evt.Character));

ax1 = subplot(1, 2, 1);
hImg = imshow(img); hold on;
hBox   = rectangle('Position', [1 1 1 1], 'EdgeColor', 'g', 'LineWidth', 2, 'Visible', 'off');
hCross = plot(NaN, NaN, '+', 'MarkerSize', 14, 'LineWidth', 2);
ax2 = subplot(1, 2, 2);
hMask = imshow(false(size(img, 1), size(img, 2)));
title(ax2, 'Mask after opening/closing');

%% Main loop
nSaved = 0;
while ishandle(fig)
    img = imresize(snapshot(cam), scale);
    [F, mask] = fire_features(img, C.fire.mask);
    [isFire, failed] = classify_fire(F, C.fire.rules);

    hImg.CData  = img;
    hMask.CData = mask;

    if F.found
        col = 'y';  if isFire, col = 'g'; end
        set(hBox, 'Position', F.bbox, 'EdgeColor', col, 'Visible', 'on');
        set(hCross, 'XData', F.centroid(1), 'YData', F.centroid(2), 'Color', col);
    else
        set(hBox, 'Visible', 'off');
        set(hCross, 'XData', NaN, 'YData', NaN);
    end

    if isFire
        title(ax1, sprintf('FIRE  |  steer %+.2f  |  area %.2f%%', F.steer, 100*F.area));
    else
        title(ax1, ['no fire: ' failed]);
    end

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
