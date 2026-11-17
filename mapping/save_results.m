function folder = save_results(S)
% SAVE_RESULTS  Save the map picture, map data and log of a run to results/run_<time>/.
stamp  = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
folder = fullfile(S.C.paths.results, ['run_' stamp]);
mkdir(folder);

M = S.M; pose = S.pose; runLog = S.log; C = S.C; %#ok<NASGU>
save(fullfile(folder, 'run.mat'), 'M', 'pose', 'runLog', 'C');

fid = fopen(fullfile(folder, 'log.txt'), 'w');
fprintf(fid, '%s\n', S.log{:});
fclose(fid);

if ~isempty(S.fig) && isgraphics(S.fig)
    exportgraphics(S.ax, fullfile(folder, 'map.png'), 'Resolution', 200);
end
fprintf('Results saved to %s\n', folder);
end
