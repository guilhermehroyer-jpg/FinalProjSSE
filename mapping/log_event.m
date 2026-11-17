function S = log_event(S, msg)
% LOG_EVENT  Print a time-stamped message, keep it in S.log, show it on the map.
line = sprintf('[%s] %s', char(datetime('now', 'Format', 'HH:mm:ss')), msg);
fprintf('%s\n', line);
S.log{end+1} = line;
map_draw(S, msg);
end
