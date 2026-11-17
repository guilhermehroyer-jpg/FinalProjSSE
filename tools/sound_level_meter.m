%% SOUND_LEVEL_METER  Print the 300-3000 Hz sound level once per second.
%
% Use it to calibrate C.sound.minLevel and C.sound.closeLevel in config.m:
%   1. Room quiet (robot motors on if you like)  -> note the level
%      C.sound.minLevel   = about 2x this "silence" level
%   2. Cry looping on the speaker, mic about 30 cm away -> note the level
%      C.sound.closeLevel = about 0.8x this level
%   3. Also try 1 m and 2 m away, to check the level drops with distance.
% Press Ctrl+C to stop.

run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths
C   = config();
rec = audiorecorder(C.sound.Fs, 16, 1, C.sound.micID);
disp('Measuring... (Ctrl+C to stop)');
while true
    recordblocking(rec, 1);
    lev = band_level(getaudiodata(rec), C.sound.Fs);
    bar = repmat('#', 1, min(60, round(lev / C.sound.closeLevel * 40)));
    fprintf('level %.4f  %s\n', lev, bar);
end
