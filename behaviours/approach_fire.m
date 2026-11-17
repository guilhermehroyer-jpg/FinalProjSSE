function [S, status] = approach_fire(S, idx)
% APPROACH_FIRE  Drive to fire S.M.fires(idx) and stop C.approach.stopDistance in front of it.
%
%   [S, status] = approach_fire(S, idx)
%
%   status  "arrived", "sound" (a sound interrupted us), "blocked" or "lost"
%
%   Each step:
%     1. listen (priority)
%     2. if the camera sees the fire: centre it and measure the distance with
%        the ultrasonic sensor (visual servoing, corrects odometry drift)
%        otherwise: turn towards the fire's map position (odometry)
%     3. drive at most C.approach.segment, stopping early for obstacles

C = S.C;
status = "lost";
blockedCount = 0;

for it = 1:C.approach.maxSteps
    [H, S] = listen_once(S, C.scan.listenSeconds);
    if H.heard
        S.lastSound = H;
        status = "sound";
        return
    end

    f = S.M.fires(idx);
    [isFire, F] = detect_fire(S);
    if isFire
        S = turn_by(S, fire_geometry(F, NaN, C.camera.hfov));
        r = read_distance(S);
        if isinf(r)
            r = hypot(f.x - S.pose(1), f.y - S.pose(2)) - C.ev3.sensorOffset;
        end
    else
        S = turn_to(S, atan2(f.y - S.pose(2), f.x - S.pose(1)));
        r = hypot(f.x - S.pose(1), f.y - S.pose(2)) - C.ev3.sensorOffset;
    end

    remaining = r - C.approach.stopDistance;
    map_draw(S, sprintf('GO TO FIRE F%d: %.2f m to go', f.id, max(remaining, 0)));
    if remaining <= C.approach.tolerance
        if isFire                                     % refine the fire's position
            d = r + C.ev3.sensorOffset;
            S.M.fires(idx).x = S.pose(1) + d*cos(S.pose(3));
            S.M.fires(idx).y = S.pose(2) + d*sin(S.pose(3));
        end
        status = "arrived";
        return
    end

    [S, st] = drive_distance(S, min(C.approach.segment, remaining), C.approach.stopDistance);
    if st == "obstacle" && ~isFire
        blockedCount = blockedCount + 1;              % something else is in the way
        if blockedCount >= 2
            status = "blocked";
            return
        end
    end
end
end
