function stop_motors(S)
% STOP_MOTORS  Stop both wheels (does nothing if the EV3 is not connected).
if isfield(S, 'mL') && ~isempty(S.mL)
    stop(S.mL);
    stop(S.mR);
end
end
