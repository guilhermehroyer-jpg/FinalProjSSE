function map_draw(S, statusText)
% MAP_DRAW  Redraw the live map: path, obstacles, fires (true size), sounds, robot.
%
%   map_draw(S, statusText)
%
%   Fires are drawn as circles with their estimated REAL area, so the big
%   and small fire can be compared at a glance. Red = not visited yet,
%   grey = visited. A thick ring marks the current target.

if isempty(S.ax) || ~isgraphics(S.ax)
    return
end
if nargin < 2, statusText = ''; end
ax = S.ax;
M  = S.M;
cla(ax); hold(ax, 'on'); grid(ax, 'on'); box(ax, 'on');

% Obstacles and path
if ~isempty(M.obstacles)
    plot(ax, M.obstacles(:,1), M.obstacles(:,2), '.', 'Color', [0.35 0.35 0.35], 'MarkerSize', 12);
end
plot(ax, M.path(:,1), M.path(:,2), '-', 'Color', [0.15 0.45 0.85], 'LineWidth', 1.5);

% Home
plot(ax, 0, 0, 's', 'MarkerSize', 11, 'MarkerFaceColor', 'k', 'MarkerEdgeColor', 'k');
text(ax, 0.04, -0.06, 'home', 'FontSize', 9);

% Fires, drawn at their real size
for k = 1:numel(M.fires)
    f  = M.fires(k);
    rr = max(sqrt(f.area/pi), 0.03);                 % radius of a circle with that area
    if f.visited, col = [0.6 0.6 0.6]; else, col = [0.9 0.2 0.1]; end
    rectangle(ax, 'Position', [f.x-rr, f.y-rr, 2*rr, 2*rr], 'Curvature', [1 1], ...
        'FaceColor', col, 'EdgeColor', 'none');
    if k == S.targetIdx
        rectangle(ax, 'Position', [f.x-rr-0.04, f.y-rr-0.04, 2*rr+0.08, 2*rr+0.08], ...
            'Curvature', [1 1], 'EdgeColor', [0.9 0.2 0.1], 'LineWidth', 2.5);
    end
    text(ax, f.x, f.y + rr + 0.06, sprintf('F%d  %.0f cm^2', f.id, f.area*1e4), ...
        'HorizontalAlignment', 'center', 'FontSize', 9, 'FontWeight', 'bold');
end

% Sound sources
for k = 1:numel(M.sounds)
    s = M.sounds(k);
    plot(ax, s.x, s.y, 'p', 'MarkerSize', 16, 'MarkerFaceColor', [0.55 0.2 0.75], ...
        'MarkerEdgeColor', 'k');
    text(ax, s.x, s.y + 0.09, s.type, 'HorizontalAlignment', 'center', 'FontSize', 9);
end

% Robot: dot + arrow for its heading
x = S.pose(1); y = S.pose(2); th = S.pose(3);
plot(ax, x, y, 'o', 'MarkerSize', 10, 'MarkerFaceColor', [0.1 0.65 0.3], 'MarkerEdgeColor', 'k');
quiver(ax, x, y, 0.2*cos(th), 0.2*sin(th), 0, 'Color', [0.1 0.65 0.3], ...
    'LineWidth', 2, 'MaxHeadSize', 2);

% Limits: everything visible, at least 2 m wide, equal scale on both axes
pts = [M.path; M.obstacles; 0 0; x y];
if ~isempty(M.fires),  pts = [pts; [M.fires.x]'  [M.fires.y]'];  end
if ~isempty(M.sounds), pts = [pts; [M.sounds.x]' [M.sounds.y]']; end
lo = min(pts, [], 1) - 0.4;
hi = max(pts, [], 1) + 0.4;
c  = (lo + hi)/2;
half = max([(hi - lo)/2, 1]);
axis(ax, 'equal');
xlim(ax, c(1) + [-half half]);
ylim(ax, c(2) + [-half half]);
xlabel(ax, 'x (m)'); ylabel(ax, 'y (m)');
title(ax, sprintf('(%.2f, %.2f) m, %.0f%s   |   %s', x, y, rad2deg(wrap_angle(th)), ...
    char(176), statusText), 'FontWeight', 'normal');
drawnow limitrate;
end
