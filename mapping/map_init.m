function M = map_init()
% MAP_INIT  Empty map. All positions in metres, start (home) = (0, 0).
%
%   M.path       Nx2 robot positions after every movement
%   M.obstacles  Nx2 points where the ultrasonic sensor saw something
%   M.fires      struct array: id, x, y, area (m^2), visited, seen (times detected)
%   M.sounds     struct array: x, y, type ('cry' / 'help')
M.path      = [0 0];
M.obstacles = zeros(0, 2);
M.fires     = struct('id', {}, 'x', {}, 'y', {}, 'area', {}, 'visited', {}, 'seen', {});
M.sounds    = struct('x', {}, 'y', {}, 'type', {});
end
