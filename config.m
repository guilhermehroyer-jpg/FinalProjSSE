function C = config()
% CONFIG  Every setting of the project in one place.
%
%   C = config();
%
%   Change values HERE, never inside the other files. Values marked
%   CALIBRATE must be measured on your own robot (see tools/ and README).

C.root = fileparts(mfilename('fullpath'));

%% Paths ----------------------------------------------------------------
C.paths.soundData = fullfile(C.root, 'data', 'sound');    % help/ nothelp/ cry/ other/
C.paths.imageData = fullfile(C.root, 'data', 'images');   % fire/ nofire/
C.paths.helpModel = fullfile(C.root, 'models', 'help_model.mat');
C.paths.fireTemplateImage = fullfile(C.root, 'data', 'images', 'fire_template.jpg');  % the printed picture
C.paths.fireTemplate      = fullfile(C.root, 'models', 'fire_template.mat');        % built from it automatically
C.paths.results   = fullfile(C.root, 'results');

%% EV3 robot ------------------------------------------------------------
C.ev3.connection    = {'USB'};      % or {'Bluetooth', '/dev/tty.EV3-SerialPort'}
C.ev3.leftPort      = 'B';          % motor ports
C.ev3.rightPort     = 'C';
C.ev3.gyroPort      = 2;            % sensor ports
C.ev3.sonicPort     = 4;
C.ev3.motorSign     = 1;            % CALIBRATE: -1 if positive speed drives backwards
C.ev3.gyroSign      = -1;           % CALIBRATE: makes left (counter-clockwise) turns positive
C.ev3.wheelDiameter = 0.056;        % CALIBRATE: metres (standard EV3 wheel is 5.6 cm)
C.ev3.sensorOffset  = 0.08;         % metres from the wheel axle to the ultrasonic sensor front
C.ev3.sonicMax      = 2.5;          % readings at or above this mean "nothing seen"

%% Driving and turning --------------------------------------------------
C.drive.speed       = 25;           % motor power 0-100 when driving straight
C.drive.headingGain = 1.5;          % P-gain: power correction per degree of heading error
C.turn.maxSpeed     = 20;           % P-controller for turning on the spot
C.turn.minSpeed     = 7;            % below this the wheels may not move at all
C.turn.gain         = 0.5;          % power per degree of remaining error
C.turn.tolerance    = 2;            % degrees
C.turn.timeout      = 8;            % seconds

%% Camera ---------------------------------------------------------------
C.camera.name       = "Microsoft® LifeCam Cinema(TM)";   % exact name from webcamlist
C.camera.resolution = '1280x720';
C.camera.scale      = 0.5;          % frames are shrunk to 640x360 before processing
                                    % (0.25 = faster, but the small fire is only found within ~1 m)
C.camera.hfov       = deg2rad(65);  % CALIBRATE with tools/measure_fov.m

%% Fire detection (rule-based: colour layers + shape template) -----------
% Our printed flame (data/images/fire_template.jpg) has three colour layers.
% Hue runs 0..1 (red sits at BOTH ends):
%   red outer layer  hue ~0.00     orange layer  hue ~0.056     yellow core  hue ~0.118
% Colour mask: which pixels can belong to the flame
C.fire.mask.hueHigh      = 0.94;    % red if hue >= this ...
C.fire.mask.redMax       = 0.03;    % ... or hue < this
C.fire.mask.orangeMax    = 0.085;   % orange: redMax <= hue < orangeMax
C.fire.mask.hueLow       = 0.17;    % yellow: orangeMax <= hue <= hueLow
C.fire.mask.satMin       = 0.35;    % red/orange must be at least this saturated
C.fire.mask.satMinYellow = 0.25;    % the yellow core may look paler on camera
C.fire.mask.valMin       = 0.25;    % not too dark
C.fire.mask.openRadius   = 2;
C.fire.mask.closeRadius  = 3;
% Rules every candidate blob must pass (tune with vision/evaluate_fire.m).
% For reference, the picture itself: aspect 1.40, red 62%, orange 24%,
% yellow 14%, yellow core centred at 85% of the height (near the bottom).
C.fire.rules.minArea      = 0.0015; % fraction of the image
C.fire.rules.minSat       = 0.35;   % mean saturation of the blob
C.fire.rules.minShapeIoU  = 0.65;   % silhouette overlap with the template (0..1)
C.fire.rules.aspectMin    = 1.1;    % height / width
C.fire.rules.aspectMax    = 1.9;
C.fire.rules.minRed       = 0.30;   % fraction of the blob that is red ...
C.fire.rules.minOrange    = 0.08;   % ... orange ...
C.fire.rules.minYellow    = 0.04;   % ... yellow
C.fire.rules.minYellowPos = 0.60;   % yellow core in the lower part (0 = top, 1 = bottom)
% Search and confirmation
C.fire.templateSize  = 64;          % silhouettes are compared at 64x64 pixels
C.fire.maxBlobs      = 5;           % check the 5 biggest blobs, not only the biggest
C.fire.confirmFrames = 3;           % look at 3 frames ...
C.fire.confirmMin    = 2;           % ... a fire needs to pass in at least 2 of them
% Memory of fires on the map
C.fire.mergeRadius   = 0.30;        % m: closer than this = the same fire seen again
C.fire.visitedRadius = 0.40;        % m: ignore fires this close to a visited one

%% Fire scan and approach -----------------------------------------------
C.scan.step              = deg2rad(30);  % 12 stops per full turn
C.scan.listenSeconds     = 1.0;          % short listen at every stop (priority check)
C.approach.stopDistance  = 0.25;         % m: stop this far in front of the fire
C.approach.tolerance     = 0.05;
C.approach.segment       = 0.40;         % m: drive at most this far between checks
C.approach.maxSteps      = 15;

%% Sound ----------------------------------------------------------------
C.sound.Fs            = 16000;
C.sound.micID         = -1;         % -1 = default input; use audiodevinfo to pick the LifeCam
C.sound.listenSeconds = 1.5;        % normal listening at the start of a cycle
C.sound.useHelpDetector = true;     % stage 2 (template matching), needs models/help_model.mat
% Stage 1 rules (cry/scream), tune with sound/evaluate_rules.m
C.sound.cryRules.minRms    = 0.01;
C.sound.cryRules.fLo       = 300;
C.sound.cryRules.fHi       = 2000;
C.sound.cryRules.maxFlat   = 0.3;
C.sound.cryRules.minVoiced = 0.5;
C.sound.cryRules.minBand   = 0.6;
% Following a sound
C.sound.scanStep      = deg2rad(45);  % 8 headings per direction scan
C.sound.scanSeconds   = 1.0;
C.sound.minLevel      = 0.005;      % CALIBRATE with tools/sound_level_meter.m: below = silence
C.sound.closeLevel    = 0.05;       % CALIBRATE: above = we are next to the source
C.sound.stopDistance  = 0.30;       % m
C.sound.segment       = 0.50;       % m
C.sound.maxSteps      = 10;
C.sound.muteAfterHandled = 30;      % s: ignore sounds right after reaching a source

%% Mission --------------------------------------------------------------
C.mission.maxCycles = 10;           % safety limit on LISTEN -> ... -> HOME cycles
end
