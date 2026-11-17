function d = dtw_distance(A, B)
% DTW_DISTANCE  Dynamic Time Warping distance between two MFCC sequences.
%
%   d = dtw_distance(A, B)   A is coef x n frames, B is coef x m frames.
%
%   People never say a word at exactly the same speed, so we cannot compare
%   frame 1 with frame 1, frame 2 with frame 2, and so on. DTW finds the
%   alignment ("warping path") with the lowest total distance, allowing
%   either sequence to stretch or compress in time.
%
%   d is the average frame distance along that best path: small = similar.

n = size(A, 2);
m = size(B, 2);

% Distance between every frame of A and every frame of B
cost = zeros(n, m);
for i = 1:n
    cost(i, :) = sqrt(sum((B - A(:, i)).^2, 1));   % Euclidean distance
end

% Accumulated cost: D(i+1,j+1) = cost(i,j) + cheapest way to get there
D = inf(n+1, m+1);
D(1, 1) = 0;
L = zeros(n+1, m+1);                   % length of the path so far
for i = 1:n
    for j = 1:m
        [best, from] = min([D(i, j), D(i, j+1), D(i+1, j)]);   % diagonal, down, right
        D(i+1, j+1) = cost(i, j) + best;
        prevL = [L(i, j), L(i, j+1), L(i+1, j)];
        L(i+1, j+1) = prevL(from) + 1;
    end
end

d = D(n+1, m+1) / L(n+1, m+1);         % normalise by path length
end
