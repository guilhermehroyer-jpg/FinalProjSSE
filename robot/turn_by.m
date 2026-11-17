function S = turn_by(S, angle)
% TURN_BY  Turn on the spot by a relative angle (radians, positive = left).
S = turn_to(S, get_heading(S) + angle);
end
