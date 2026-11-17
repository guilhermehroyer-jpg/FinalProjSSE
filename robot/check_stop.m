function check_stop(S)
% CHECK_STOP  Safety: abort everything if STOP was pressed or the map was closed.
%
%   Called inside every motor loop. Throws the error 'rescue:stop', which
%   main.m catches; the motors are stopped first.

if isempty(S.fig)
    return                       % no map window (e.g. a test without a map)
end
drawnow limitrate;               % lets MATLAB process the button click
if ~isgraphics(S.fig) || getappdata(S.fig, 'stop')
    stop_motors(S);
    error('rescue:stop', 'STOP pressed (or map window closed).');
end
end
