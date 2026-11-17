function robot_shutdown(S)
% ROBOT_SHUTDOWN  Stop the motors and release the camera. Safe to call twice.
try
    stop_motors(S);
catch
end
try
    if isfield(S, 'cam') && ~isempty(S.cam)
        delete(S.cam);
    end
catch
end
end
