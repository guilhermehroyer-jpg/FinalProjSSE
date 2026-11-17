function [bearing, realArea] = fire_geometry(F, r, hfov)
% FIRE_GEOMETRY  Direction and real size of a detected fire.
%
%   [bearing, realArea] = fire_geometry(F, r, hfov)
%
%   F     features from fire_features (needs .steer, .area, .imgSize)
%   r     distance to the fire in metres (ultrasonic), or NaN if unknown
%   hfov  horizontal field of view of the camera in radians
%
%   bearing   angle from the robot's heading to the fire, radians,
%             positive = fire is to the LEFT (counter-clockwise)
%   realArea  area of the fire in m^2 (NaN if r is unknown)
%
%   Pinhole camera model:
%     a point at normalised image position u = (x - W/2)/(W/2) lies at
%     angle atan(u * tan(hfov/2)) from the optical axis. Right of centre
%     means clockwise, hence the minus sign.
%
%     At distance r the image covers  2*r*tan(hfov/2)  metres horizontally
%     and  2*r*tan(vfov/2) = 2*r*tan(hfov/2)*H/W  metres vertically, so a
%     blob covering a fraction F.area of the pixels has a real area of
%     F.area * (2*r*tan(hfov/2))^2 * H/W.
%     This is what lets us compare a small fire close by with a big fire
%     far away.

bearing = -atan(F.steer * tan(hfov/2));

H = F.imgSize(1);
W = F.imgSize(2);
if isnan(r) || isinf(r)
    realArea = NaN;
else
    realArea = F.area * (2*r*tan(hfov/2))^2 * H/W;
end
end
