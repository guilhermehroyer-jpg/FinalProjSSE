function S = robot_init(C, parts)
% ROBOT_INIT  Connect to the hardware and create the robot state S.
%
%   S = robot_init()                    everything, settings from config.m
%   S = robot_init(C, parts)            only some parts, e.g. {'ev3','map'}
%
%   parts can contain: 'ev3', 'camera', 'mic', 'map'
%
%   S is passed into and returned from every function, so it always holds
%   the latest robot state:
%     S.C          settings (config.m)
%     S.pose       [x y theta] in metres / radians; start = [0 0 0],
%                  theta = 0 is the direction the robot faced at the start,
%                  positive theta = turned left (counter-clockwise)
%     S.M          the map (path, obstacles, fires, sounds)
%     S.ev3, S.mL, S.mR, S.gyro, S.sonic   EV3 connection, motors, sensors
%     S.cam        webcam
%     S.rec        audio recorder
%     S.helpModel  "help" templates + threshold (or [] if not trained yet)

if nargin < 1 || isempty(C), C = config(); end
if nargin < 2, parts = {'ev3', 'camera', 'mic', 'map'}; end

S.C          = C;
S.pose       = [0 0 0];
S.M          = map_init();
S.log        = {};
S.targetIdx  = 0;
S.lastSound  = struct('heard', false, 'type', '', 'level', 0, 'dHelp', NaN);
S.soundClock = tic;     % clock for muting sounds after a source was reached
S.muteUntil  = 0;
S.helpModel  = [];
S.fig = [];  S.ax = [];

if ismember('ev3', parts)
    fprintf('Connecting to EV3 ... ');
    S.ev3   = legoev3(C.ev3.connection{:});
    S.mL    = motor(S.ev3, C.ev3.leftPort);
    S.mR    = motor(S.ev3, C.ev3.rightPort);
    S.gyro  = gyroSensor(S.ev3, C.ev3.gyroPort);
    S.sonic = sonicSensor(S.ev3, C.ev3.sonicPort);
    stop(S.mL); stop(S.mR);
    resetRotation(S.mL); resetRotation(S.mR);
    pause(0.5);                  % keep the robot STILL while the gyro resets
    resetRotationAngle(S.gyro);
    pause(0.5);
    fprintf('ok\n');
end

if ismember('camera', parts)
    fprintf('Connecting to camera ... ');
    S.cam = webcam(C.camera.name);
    S.cam.Resolution = C.camera.resolution;
    fprintf('ok\n');
end

if ismember('mic', parts)
    S.rec = audiorecorder(C.sound.Fs, 16, 1, C.sound.micID);
    if C.sound.useHelpDetector
        if exist(C.paths.helpModel, 'file')
            S.helpModel = load(C.paths.helpModel, 'templates', 'thr');
        else
            warning('No %s yet: "help" detection is off. Run sound/help_train_evaluate.m.', ...
                C.paths.helpModel);
        end
    end
end

if ismember('map', parts)
    S.fig = figure('Name', 'Rescue robot map', 'NumberTitle', 'off', ...
                   'Position', [100 100 800 700]);
    setappdata(S.fig, 'stop', false);
    S.ax = axes(S.fig, 'Position', [0.09 0.08 0.86 0.80]);
    uicontrol(S.fig, 'Style', 'pushbutton', 'String', 'STOP', ...
        'FontWeight', 'bold', 'FontSize', 14, 'ForegroundColor', 'w', ...
        'BackgroundColor', [0.85 0.15 0.15], 'Units', 'normalized', ...
        'Position', [0.80 0.92 0.16 0.06], ...
        'Callback', @(src, ~) setappdata(ancestor(src, 'figure'), 'stop', true));
    map_draw(S, 'Ready');
end
end
