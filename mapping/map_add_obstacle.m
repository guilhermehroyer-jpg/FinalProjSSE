function S = map_add_obstacle(S, r)
% MAP_ADD_OBSTACLE  Turn an ultrasonic reading into a point on the map.
%
%   The sensor looks straight ahead, so the object is at
%     robot position + (r + sensorOffset) * [cos(theta), sin(theta)]
%   Readings of Inf (nothing in range) are skipped.

if isinf(r) || isnan(r)
    return
end
d = r + S.C.ev3.sensorOffset;
p = S.pose(1:2) + d * [cos(S.pose(3)), sin(S.pose(3))];
S.M.obstacles(end+1, :) = p;
end
