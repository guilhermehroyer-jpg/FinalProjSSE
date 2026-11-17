function [isFire, F, img, mask] = detect_fire(S)
% DETECT_FIRE  Grab a frame and run the rule-based fire detector on it.
%
%   [isFire, F, img, mask] = detect_fire(S)
%
%   F is the feature struct from fire_features (centroid, area, steer, ...).

img = grab_frame(S.cam, S.C.camera.scale);
[F, mask] = fire_features(img, S.C.fire.mask);
isFire = classify_fire(F, S.C.fire.rules);
end
