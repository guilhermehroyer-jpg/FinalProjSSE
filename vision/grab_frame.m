function img = grab_frame(cam, scale)
% GRAB_FRAME  Newest camera frame, shrunk for fast processing.
%
%   img = grab_frame(cam, scale)
%
%   The first snapshot after the robot has moved can be an old, buffered
%   frame, so we take two and keep the second.

snapshot(cam);
img = imresize(snapshot(cam), scale);
end
