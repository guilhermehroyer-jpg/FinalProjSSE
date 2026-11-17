%% TEST_EV3  Check the EV3 connection and calibrate motion. Run this FIRST.
%
% Checks, in order:
%   1. sensors respond (ultrasonic distance, gyro heading)
%   2. driving 0.50 m forward  -> calibrates C.ev3.motorSign and wheelDiameter
%   3. turning 90 deg left     -> calibrates C.ev3.gyroSign
% Put the robot on the floor with ~1 m free space in front of it.

run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths
C = config();
S = robot_init(C, {'ev3'});
cleaner = onCleanup(@() robot_shutdown(S));

%% 1. Sensors
fprintf('\n--- 1. Sensors (5 readings) ---\n');
for k = 1:5
    fprintf('distance %.2f m   heading %.1f deg\n', read_distance(S), rad2deg(get_heading(S)));
    pause(0.3);
end
disp('Move your hand in front of the ultrasonic sensor: the distance should change.');

%% 2. Drive 0.5 m
input(sprintf('\n--- 2. Press Enter: the robot drives 0.50 m FORWARD ---'), 's');
[S, status, moved] = drive_distance(S, 0.50);
fprintf('Status: %s. Encoders say %.3f m, odometry pose (%.3f, %.3f).\n', ...
    status, moved, S.pose(1), S.pose(2));
disp('Measure the real distance with a tape measure:');
disp('  - it drove BACKWARDS  -> set C.ev3.motorSign = -1 in config.m');
disp('  - real distance differs -> wheelDiameter_new = wheelDiameter * real / 0.50');

%% 3. Turn 90 deg left
input(sprintf('\n--- 3. Press Enter: the robot turns 90 deg LEFT (counter-clockwise) ---'), 's');
S = turn_by(S, deg2rad(90));
fprintf('Gyro heading now %.1f deg (target 90).\n', rad2deg(get_heading(S)));
disp('  - it turned RIGHT, or kept spinning until a timeout -> flip C.ev3.gyroSign in config.m');
disp('  - it stops a few degrees short or past              -> adjust C.turn.gain / minSpeed');

fprintf('\nDone.\n');
