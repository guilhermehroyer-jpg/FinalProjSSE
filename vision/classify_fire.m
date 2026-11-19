function [isFire, failed] = classify_fire(F, T)
% CLASSIFY_FIRE  Rule-based classifier: is this blob our printed flame?
%
%   [isFire, failed] = classify_fire(F)      thresholds from config.m (C.fire.rules)
%   [isFire, failed] = classify_fire(F, T)   your own thresholds
%
%   isFire is true only if ALL rules pass; failed lists the rules that did not.
%   Colour alone is not enough (any red object would pass), so the rules
%   check what makes OUR flame unique:
%     - its silhouette matches the flame template      (shape)
%     - its proportions                                (height / width)
%     - its three colour layers: red outside, orange, and a yellow core
%     - the yellow core sits in the lower part of the flame
%   A red jacket has no orange/yellow layers and the wrong shape; a red-orange-
%   yellow logo has layers but the wrong shape and proportions.

if nargin < 2
    C = config();
    T = C.fire.rules;
end

if ~F.found
    isFire = false;
    failed = 'no red blob';
    return
end

checks = { ...
    'big enough',         F.area       >= T.minArea;
    'saturated colours',  F.meanSat    >= T.minSat;
    'flame shape',        F.shapeIoU   >= T.minShapeIoU;
    'flame proportions',  F.aspect     >= T.aspectMin && F.aspect <= T.aspectMax;
    'red outer layer',    F.fracRed    >= T.minRed;
    'orange layer',       F.fracOrange >= T.minOrange;
    'yellow core',        F.fracYellow >= T.minYellow;
    'core at the bottom', F.yellowPos  >= T.minYellowPos };

ok     = [checks{:, 2}];
isFire = all(ok);
failed = strjoin(checks(~ok, 1), ', ');
end
