function [S, status] = follow_sound(S)
% FOLLOW_SOUND  Find the direction of a sound (stop-and-scan) and drive to its source.
%
%   [S, status] = follow_sound(S)
%
%   status  "arrived" (source added to the map) or "lost"
%
%   One microphone cannot hear direction, so the robot turns and compares
%   loudness (300-3000 Hz, band_level) at every heading:
%     - first step: a full 360 degree scan (8 headings)
%     - later steps: only -90..+90 degrees around the current heading
%   Then it turns to the loudest heading and drives C.sound.segment.
%   It has arrived when the sound is very loud (C.sound.closeLevel) or the
%   ultrasonic sensor sees something within C.sound.stopDistance.
%   The sound must keep playing during the search (loop it on a speaker).

C = S.C;
status = "lost";
lostCount = 0;
step = C.sound.scanStep;

for it = 1:C.sound.maxSteps
    h0 = get_heading(S);
    if it == 1
        offsets = (0:round(2*pi/step)-1) * step;    % full circle
    else
        offsets = (-2:2) * step;                      % front half only
    end

    levels = zeros(size(offsets));
    for k = 1:numel(offsets)
        S = turn_to(S, h0 + offsets(k));
        stop_motors(S);
        recordblocking(S.rec, C.sound.scanSeconds);
        levels(k) = band_level(getaudiodata(S.rec), C.sound.Fs);
        S = map_add_obstacle(S, read_distance(S));
        map_draw(S, sprintf('FOLLOW SOUND: heading %d/%d, level %.4f', k, numel(offsets), levels(k)));
    end

    [best, kb] = max(levels);
    if best < C.sound.minLevel
        lostCount = lostCount + 1;
        if lostCount >= 2
            return                                    % status stays "lost"
        end
        continue
    end
    lostCount = 0;

    S = turn_to(S, h0 + offsets(kb));
    r = read_distance(S);
    if best >= C.sound.closeLevel || r <= C.sound.stopDistance + 0.05
        if isinf(r)
            d = C.ev3.sensorOffset + C.sound.stopDistance;
        else
            d = r + C.ev3.sensorOffset;
        end
        type = S.lastSound.type;
        if isempty(type), type = 'sound'; end
        S = map_add_sound(S, S.pose(1) + d*cos(S.pose(3)), S.pose(2) + d*sin(S.pose(3)), type);
        status = "arrived";
        return
    end

    dist = C.sound.segment;
    if isfinite(r)
        dist = min(dist, r - C.sound.stopDistance);
    end
    S = drive_distance(S, dist, C.sound.stopDistance);
end
end
