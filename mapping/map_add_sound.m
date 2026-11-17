function S = map_add_sound(S, x, y, type)
% MAP_ADD_SOUND  Record the position of a sound source that the robot reached.
S.M.sounds(end+1) = struct('x', x, 'y', y, 'type', type);
end
