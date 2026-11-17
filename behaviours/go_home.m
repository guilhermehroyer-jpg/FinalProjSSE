function [S, status] = go_home(S)
% GO_HOME  Drive back to the start (0, 0) using odometry, then face the start direction.
%
%   [S, status] = go_home(S)
%
%   status  "home", "sound" (heard something on the way) or "blocked"
%
%   Drives in segments of at most 1 m and listens between them, so a cry
%   still has priority. Because of odometry drift the robot ends up NEAR the
%   start, not exactly on it; that is fine, the next scan starts from there.

C = S.C;
status = "home";

for it = 1:6
    dx = -S.pose(1);
    dy = -S.pose(2);
    dist = hypot(dx, dy);
    if dist < 0.10
        break
    end
    S = turn_to(S, atan2(dy, dx));
    map_draw(S, sprintf('RETURNING HOME: %.2f m to go', dist));
    [S, st] = drive_distance(S, min(dist, 1.0), 0.20);
    if st == "obstacle"
        status = "blocked";
        return
    end
    [H, S] = listen_once(S, C.scan.listenSeconds);
    if H.heard
        S.lastSound = H;
        status = "sound";
        return
    end
end
S = turn_to(S, 0);
end
