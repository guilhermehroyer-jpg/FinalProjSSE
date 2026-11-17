function [H, S] = listen_once(S, seconds)
% LISTEN_ONCE  Record once (motors stopped) and run both sound detectors.
%
%   [H, S] = listen_once(S, seconds)
%
%   H.heard  true if stage 1 (cry/scream rules) OR stage 2 ("help" templates) fires
%   H.type   'cry', 'help', or ''
%   H.level  loudness in the 300-3000 Hz band (see band_level)
%   H.dHelp  smallest DTW distance to a "help" template (NaN if not used)
%
%   Right after a sound source has been reached, sounds are ignored for
%   C.sound.muteAfterHandled seconds, so the robot does not drive straight
%   back to the same speaker.

C = S.C;
H = struct('heard', false, 'type', '', 'level', 0, 'dHelp', NaN);

stop_motors(S);
recordblocking(S.rec, seconds);
y  = getaudiodata(S.rec);
Fs = C.sound.Fs;
H.level = band_level(y, Fs);

if toc(S.soundClock) < S.muteUntil
    return                                      % muted after handling a source
end

%% Stage 1: cry/scream rules on every 1 s window
L = Fs;
starts = 1:round(L/2):max(1, numel(y) - L + 1); % 50% overlapping windows
for s = starts
    seg = y(s:min(s+L-1, numel(y)));
    if numel(seg) < L, break; end
    if classify_window(extract_features(seg, Fs), C.sound.cryRules)
        H.heard = true;
        H.type  = 'cry';
        return
    end
end

%% Stage 2: "help" template matching
if C.sound.useHelpDetector && ~isempty(S.helpModel)
    Cw = word_features(y, Fs);
    d  = cellfun(@(T) dtw_distance(Cw, T), S.helpModel.templates);
    H.dHelp = min(d);
    if H.dHelp <= S.helpModel.thr
        H.heard = true;
        H.type  = 'help';
    end
end
end
