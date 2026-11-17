function [S, idx] = map_add_fire(S, x, y, area)
% MAP_ADD_FIRE  Add a fire sighting to the map, or merge it with a known fire.
%
%   [S, idx] = map_add_fire(S, x, y, area)
%
%   idx = index in S.M.fires of the (unvisited) fire, or 0 if the sighting
%   belongs to a fire that was already visited (it is then ignored).
%
%   1. Within C.fire.visitedRadius of a VISITED fire  -> ignore (idx = 0)
%   2. Within C.fire.mergeRadius of an UNVISITED fire -> same fire seen again:
%      average its position and size with the new sighting
%   3. Otherwise                                      -> new fire

C = S.C;
idx = 0;
fires = S.M.fires;

for k = 1:numel(fires)
    dist = hypot(fires(k).x - x, fires(k).y - y);
    if fires(k).visited && dist < C.fire.visitedRadius
        return
    end
end

for k = 1:numel(fires)
    if ~fires(k).visited && hypot(fires(k).x - x, fires(k).y - y) < C.fire.mergeRadius
        n = fires(k).seen;
        fires(k).x    = (n*fires(k).x    + x)    / (n + 1);   % running average
        fires(k).y    = (n*fires(k).y    + y)    / (n + 1);
        fires(k).area = (n*fires(k).area + area) / (n + 1);
        fires(k).seen = n + 1;
        S.M.fires = fires;
        idx = k;
        return
    end
end

idx = numel(fires) + 1;
S.M.fires(idx) = struct('id', idx, 'x', x, 'y', y, 'area', area, 'visited', false, 'seen', 1);
end
