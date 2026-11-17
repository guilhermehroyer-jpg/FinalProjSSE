function [S, seen, status] = scan_for_fires(S)
% SCAN_FOR_FIRES  Turn 360 degrees in steps; listen, map and look for fires at every stop.
%
%   [S, seen, status] = scan_for_fires(S)
%
%   seen    indices (into S.M.fires) of UNVISITED fires seen during this scan
%   status  "done", or "sound" if a cry/"help" was heard (priority: the
%           caller should switch to following the sound; S.lastSound has it)
%
%   At every stop:
%     1. listen          -> a sound interrupts the scan immediately
%     2. ultrasonic      -> one obstacle point on the map
%     3. camera          -> if a fire is detected:
%          a. turn to centre it (bearing from the image, fire_geometry)
%          b. measure its distance with the ultrasonic sensor
%          c. compute its real size and map position, add it to the map
%             (sightings of the same fire are merged; visited fires ignored)

C = S.C;
seen   = [];
status = "done";
h0 = get_heading(S);
n  = round(2*pi / C.scan.step);

for k = 0:n-1
    S = turn_to(S, h0 + k*C.scan.step);
    map_draw(S, sprintf('SCAN %d/%d: listening', k+1, n));

    % 1. Priority check: sound
    [H, S] = listen_once(S, C.scan.listenSeconds);
    if H.heard
        S.lastSound = H;
        status = "sound";
        return
    end

    % 2. Map the surroundings
    S = map_add_obstacle(S, read_distance(S));

    % 3. Look for fire
    [isFire, F] = detect_fire(S);
    if ~isFire
        map_draw(S, sprintf('SCAN %d/%d: no fire', k+1, n));
        continue
    end

    S = turn_by(S, fire_geometry(F, NaN, C.camera.hfov));   % a. centre the fire
    [isFire, F] = detect_fire(S);
    if ~isFire
        continue                                             % lost it while turning
    end
    r = read_distance(S);                                    % b. distance
    if isinf(r)
        S = log_event(S, 'Fire seen but beyond ultrasonic range: skipped');
        continue
    end
    S = map_add_obstacle(S, r);
    [~, area] = fire_geometry(F, r, C.camera.hfov);          % c. real size and position
    d  = r + C.ev3.sensorOffset;
    fx = S.pose(1) + d*cos(S.pose(3));
    fy = S.pose(2) + d*sin(S.pose(3));
    [S, idx] = map_add_fire(S, fx, fy, area);
    if idx > 0 && ~ismember(idx, seen)
        seen(end+1) = idx; %#ok<AGROW>
    end
    if idx > 0
        msg = sprintf('SCAN %d/%d: fire F%d at %.2f m, %.0f cm^2', k+1, n, idx, r, area*1e4);
    else
        msg = sprintf('SCAN %d/%d: already visited fire', k+1, n);
    end
    map_draw(S, msg);
end
end
