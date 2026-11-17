function h = get_heading(S)
% GET_HEADING  Robot heading in radians from the gyro.
%   0 = direction at the start, positive = turned left (counter-clockwise).
%   The EV3 gyro counts clockwise as positive, so C.ev3.gyroSign = -1 flips it.
h = S.C.ev3.gyroSign * deg2rad(double(readRotationAngle(S.gyro)));
end
