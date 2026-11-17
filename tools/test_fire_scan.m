%% TEST_FIRE_SCAN  One 360 degree fire scan with the live map (no driving to fires).
%
% Place the big and the small fire print around the robot (0.5-2 m away,
% each on something flat like a box, facing the robot), then run this.
% Checks: are both fires found, at about the right positions, and is the
% big one reported as bigger? Measure the true positions with a tape to
% fill in your accuracy table.

run(fullfile(fileparts(mfilename('fullpath')), '..', 'setup.m'));   % project paths
C = config();
S = robot_init(C);
cleaner = onCleanup(@() robot_shutdown(S));

[S, seen, status] = scan_for_fires(S);
fprintf('\nScan status: %s\n', status);
for i = seen
    f = S.M.fires(i);
    fprintf('F%d at (%.2f, %.2f) m, real area %.0f cm^2, seen %d times\n', ...
        f.id, f.x, f.y, f.area*1e4, f.seen);
end
if ~isempty(seen)
    [~, k] = max([S.M.fires(seen).area]);
    S.targetIdx = seen(k);
    map_draw(S, sprintf('Biggest fire: F%d', S.targetIdx));
end
save_results(S);
