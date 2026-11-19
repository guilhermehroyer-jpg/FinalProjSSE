%% MEASURE_FOV  Measure the camera's horizontal field of view with a fire print.
%
% The FOV is needed for the fire's direction and real size (fire_geometry.m).
%   1. Measure the WIDTH of the fire print (widest part of the flame).
%   2. Put it straight in front of the camera at a measured distance (~1 m).
%   3. Run this script.
%
% Width in pixels  wpx = W * w / (2 * r * tan(hfov/2))
%   =>  hfov = 2 * atan( W * w / (2 * r * wpx) )

run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths
C   = config();
cam = webcam(C.camera.name);
cam.Resolution = C.camera.resolution;

w = input('Real width of the fire print (m), e.g. 0.15: ');
r = input('Distance from camera to the print (m), e.g. 1.0: ');

img = grab_frame(cam, C.camera.scale);
F   = fire_features(img, C);
clear cam
if ~F.found
    error('No red blob found. Check the lighting and C.fire.mask in config.m.');
end

wpx  = F.bbox(3);
W    = F.imgSize(2);
hfov = 2*atan(W*w / (2*r*wpx));

imshow(img); hold on;
rectangle('Position', F.bbox, 'EdgeColor', 'g', 'LineWidth', 2);
title(sprintf('blob width %.0f px of %d px  ->  FOV %.1f deg', wpx, W, rad2deg(hfov)));
fprintf('Horizontal FOV = %.1f deg\nSet in config.m:  C.camera.hfov = deg2rad(%.1f);\n', ...
    rad2deg(hfov), rad2deg(hfov));
