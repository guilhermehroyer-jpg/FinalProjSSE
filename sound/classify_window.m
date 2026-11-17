function [isCry, failed] = classify_window(F, T)
% CLASSIFY_WINDOW  Stage 1: rule-based cry/scream detector for one 1 s window.
%
%   [isCry, failed] = classify_window(F)      thresholds from config.m
%   [isCry, failed] = classify_window(F, T)   your own thresholds struct T
%
%   F comes from extract_features. isCry is true only if ALL rules pass.
%   failed lists the rules that did not pass (useful when tuning).

if nargin < 2
    C = config();
    T = C.sound.cryRules;
end

checks = { ...
    'loud enough',        F.rms        >= T.minRms;
    'peak in cry range',  F.peakFreq   >= T.fLo && F.peakFreq <= T.fHi;
    'tonal (not noise)',  F.flatness   <= T.maxFlat;
    'sustained',          F.voicedFrac >= T.minVoiced;
    'energy in band',     F.bandRatio  >= T.minBand };

ok     = [checks{:, 2}];
isCry  = all(ok);
failed = strjoin(checks(~ok, 1), ', ');
end
