function set_speeds(S, left, right, doStart)
% SET_SPEEDS  Set wheel power (-100..100). Positive = forward.
%
%   set_speeds(S, left, right)            set power and start the motors
%   set_speeds(S, left, right, false)     only change power (motors already running)
%
%   C.ev3.motorSign fixes motors that are mounted the other way round.

if nargin < 4, doStart = true; end
sgn = S.C.ev3.motorSign;
S.mL.Speed = max(-100, min(100, sgn*left));
S.mR.Speed = max(-100, min(100, sgn*right));
if doStart
    start(S.mL);
    start(S.mR);
end
end
