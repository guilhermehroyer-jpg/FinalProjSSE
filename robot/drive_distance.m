function [S, status, moved] = drive_distance(S, d, obstacleStop)
% DRIVE_DISTANCE  Drive straight for d metres (negative = backwards) and update the pose.
%
%   [S, status, moved] = drive_distance(S, d)
%   [S, status, moved] = drive_distance(S, d, obstacleStop)
%
%   obstacleStop  stop early if the ultrasonic distance drops below this (m);
%                 0 or omitted = no obstacle check
%   status        "done", "obstacle" or "timeout"
%   moved         distance actually driven (m), from the wheel encoders
%
%   Distance comes from the motor encoders:
%       metres = degrees / 360 * pi * wheelDiameter
%   The gyro keeps the robot straight (P-controller on the heading error).
%   Odometry update at the end (book: dead reckoning):
%       x = x + moved * cos(theta),  y = y + moved * sin(theta)
%   using the average of the start and end heading.

if nargin < 3, obstacleStop = 0; end
C = S.C;
k = C.ev3.motorSign * pi * C.ev3.wheelDiameter / 360;   % metres per encoder degree

L0 = double(readRotation(S.mL));
R0 = double(readRotation(S.mR));
h0 = get_heading(S);
v  = sign(d) * C.drive.speed;
status  = "done";
timeout = 5 + 20*abs(d);
t0 = tic;
first = true;

while true
    check_stop(S);
    dl = k * (double(readRotation(S.mL)) - L0);
    dr = k * (double(readRotation(S.mR)) - R0);
    if abs((dl + dr)/2) >= abs(d)
        break
    end
    if toc(t0) > timeout
        status = "timeout";
        break
    end
    if obstacleStop > 0 && d > 0 && read_distance(S, 1) <= obstacleStop
        status = "obstacle";
        break
    end
    errDeg = rad2deg(wrap_angle(h0 - get_heading(S)));  % positive = drifted right
    corr   = max(-10, min(10, C.drive.headingGain * errDeg));
    set_speeds(S, v - corr, v + corr, first);           % right faster = steer left
    first = false;
end
stop_motors(S);
pause(0.2);

% Final odometry update
dl = k * (double(readRotation(S.mL)) - L0);
dr = k * (double(readRotation(S.mR)) - R0);
moved = (dl + dr)/2;
h1   = get_heading(S);
hMid = h0 + wrap_angle(h1 - h0)/2;
S.pose(1) = S.pose(1) + moved*cos(hMid);
S.pose(2) = S.pose(2) + moved*sin(hMid);
S.pose(3) = h1;
S.M.path(end+1, :) = S.pose(1:2);
end
