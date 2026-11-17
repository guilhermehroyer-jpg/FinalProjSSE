function a = wrap_angle(a)
% WRAP_ANGLE  Wrap an angle (radians) into [-pi, pi], so turns take the short way.
a = atan2(sin(a), cos(a));
end
