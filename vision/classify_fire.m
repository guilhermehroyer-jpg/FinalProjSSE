function [isFire, failed] = classify_fire(F, T)
% CLASSIFY_FIRE  Rule-based classifier: is the largest red blob our "fire" target?
%
%   [isFire, failed] = classify_fire(F)      thresholds from config.m (C.fire.rules)
%   [isFire, failed] = classify_fire(F, T)   your own thresholds
%
%   isFire is true only if ALL rules pass; failed lists the rules that did not.
%   The thresholds are STARTING GUESSES: tune them with evaluate_fire.m.

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
    'big enough',        F.area        >= T.minArea;
    'solid shape',       F.extent      >= T.minExtent;
    'compact shape',     F.circularity >= T.minCircularity;
    'saturated red',     F.meanSat     >= T.minSat };

ok     = [checks{:, 2}];
isFire = all(ok);
failed = strjoin(checks(~ok, 1), ', ');
end

