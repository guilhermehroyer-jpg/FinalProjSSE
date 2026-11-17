function S = turn_to(S, target)
% TURN_TO  Turn on the spot to an absolute heading (radians), using the gyro.
%
%   S = turn_to(S, target)
%
%   P-controller (book Ch. 3): wheel power is proportional to the remaining
%   heading error, limited between C.turn.minSpeed and C.turn.maxSpeed, so the
%   robot turns fast when far from the target and slows down near it.

C  = S.C;
t0 = tic;
first = true;
while true
    check_stop(S);
    err    = wrap_angle(target - get_heading(S));   % positive = must turn left
    errDeg = rad2deg(err);
    if abs(errDeg) <= C.turn.tolerance || toc(t0) > C.turn.timeout
        break
    end
    p = min(C.turn.maxSpeed, max(C.turn.minSpeed, C.turn.gain*abs(errDeg)));
    p = sign(errDeg) * p;
    set_speeds(S, -p, p, first);                    % left wheel back, right forward = turn left
    first = false;
end
stop_motors(S);
pause(0.2);                                         % let the robot settle
S.pose(3) = get_heading(S);
if toc(t0) > C.turn.timeout
    warning('turn_to: timeout. Is C.ev3.gyroSign correct? (tools/test_ev3.m)');
end
end
