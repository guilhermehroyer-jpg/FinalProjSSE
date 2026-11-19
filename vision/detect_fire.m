function [isFire, F, img, mask] = detect_fire(S)
% DETECT_FIRE  Look for the flame in several frames; report it only if confirmed.
%
%   [isFire, F, img, mask] = detect_fire(S)
%
%   One frame can fool the detector (motion blur, a reflection, a red object
%   at an odd angle), and the robot would then turn towards nothing. So we
%   check up to C.fire.confirmFrames frames and only call it a fire if it
%   passes in at least C.fire.confirmMin of them (default: 2 out of 3).
%   F, img and mask come from the last frame that passed (or the last frame).

C = S.C;
n = C.fire.confirmFrames;
need = C.fire.confirmMin;
hits = 0;
F = []; img = []; mask = [];

for k = 1:n
    if k == 1
        frame = grab_frame(S.cam, C.camera.scale);        % flushes an old buffered frame
    else
        frame = imresize(snapshot(S.cam), C.camera.scale);
    end
    [Fk, maskK] = fire_features(frame, C);
    if classify_fire(Fk, C.fire.rules)
        hits = hits + 1;
        F = Fk; img = frame; mask = maskK;
    elseif hits == 0
        F = Fk; img = frame; mask = maskK;                % keep something to show
    end
    if hits >= need || hits + (n - k) < need
        break                                             % decided already
    end
end
isFire = hits >= need;
end
