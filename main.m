function main()
% MAIN  Rescue robot mission (state machine).
%
%   Run:  >> setup      (once per MATLAB session)
%         >> main
%
%   Put the robot at its start position and keep it still while it connects
%   (the gyro calibrates). Press the red STOP button on the map, close the
%   map, or press Ctrl+C to stop at any moment; the motors always stop.
%
%   States
%     LISTEN     stand still and listen
%                  heard a cry / "help"  -> SOUND
%                  nothing               -> SCAN
%     SCAN       turn 360 degrees: listen, map with the ultrasonic sensor,
%                look for fires (scan_for_fires)
%                  heard something       -> SOUND     (sound has priority)
%                  unvisited fires seen  -> GOTO_FIRE (the BIGGEST real size)
%                  no unvisited fires    -> DONE
%     GOTO_FIRE  drive to the target fire, stop in front of it, mark it
%                visited                 -> HOME
%                  heard something       -> SOUND
%     SOUND      find the sound's direction and drive to it, report its
%                position                -> HOME
%     HOME       drive back to the start -> LISTEN
%     DONE       no fires left and nothing heard: "area clear", stop

setup;
C = config();
S = robot_init(C);
cleaner = onCleanup(@() robot_shutdown(S)); %#ok<NASGU>

state = "LISTEN";
cycle = 0;
S = log_event(S, 'Mission started');

try
    while true
        switch state

            case "LISTEN"
                cycle = cycle + 1;
                if cycle > C.mission.maxCycles
                    S = log_event(S, 'Cycle limit reached, stopping');
                    break
                end
                map_draw(S, sprintf('Cycle %d: LISTEN', cycle));
                [H, S] = listen_once(S, C.sound.listenSeconds);
                if H.heard
                    S.lastSound = H;
                    S = log_event(S, sprintf('Heard: %s', H.type));
                    state = "SOUND";
                else
                    state = "SCAN";
                end

            case "SCAN"
                [S, seen, status] = scan_for_fires(S);
                if status == "sound"
                    S = log_event(S, sprintf('Heard %s during the scan', S.lastSound.type));
                    state = "SOUND";
                elseif isempty(seen)
                    state = "DONE";
                else
                    [~, i] = max([S.M.fires(seen).area]);
                    S.targetIdx = seen(i);
                    f = S.M.fires(S.targetIdx);
                    S = log_event(S, sprintf('Biggest fire: F%d at (%.2f, %.2f) m, %.0f cm^2', ...
                        f.id, f.x, f.y, f.area*1e4));
                    state = "GOTO_FIRE";
                end

            case "GOTO_FIRE"
                [S, status] = approach_fire(S, S.targetIdx);
                f = S.M.fires(S.targetIdx);
                if status == "arrived"
                    S.M.fires(S.targetIdx).visited = true;
                    S = log_event(S, sprintf('REPORT: fire F%d at (%.2f, %.2f) m, %.0f cm^2', ...
                        f.id, f.x, f.y, f.area*1e4));
                    state = "HOME";
                elseif status == "sound"
                    S = log_event(S, sprintf('Heard %s on the way to the fire', S.lastSound.type));
                    state = "SOUND";
                else
                    S.M.fires(S.targetIdx).visited = true;   % do not try this one again
                    S = log_event(S, sprintf('Could not reach fire F%d (%s)', f.id, status));
                    state = "HOME";
                end
                S.targetIdx = 0;

            case "SOUND"
                [S, status] = follow_sound(S);
                S.muteUntil = toc(S.soundClock) + C.sound.muteAfterHandled;
                if status == "arrived"
                    src = S.M.sounds(end);
                    S = log_event(S, sprintf('REPORT: %s at (%.2f, %.2f) m', src.type, src.x, src.y));
                else
                    S = log_event(S, 'Lost the sound');
                end
                state = "HOME";

            case "HOME"
                [S, status] = go_home(S);
                if status == "sound"
                    S = log_event(S, sprintf('Heard %s on the way home', S.lastSound.type));
                    state = "SOUND";
                else
                    if status == "blocked"
                        S = log_event(S, 'Way home blocked, continuing from here');
                    end
                    state = "LISTEN";
                end

            case "DONE"
                S = log_event(S, 'No unvisited fires and no sounds: AREA CLEAR');
                break
        end
    end
catch ME
    stop_motors(S);
    if strcmp(ME.identifier, 'rescue:stop')
        S = log_event(S, 'STOPPED by the user');
    else
        save_results(S);
        rethrow(ME);
    end
end

stop_motors(S);
save_results(S);
end
