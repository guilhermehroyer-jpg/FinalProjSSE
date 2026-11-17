function r = read_distance(S, n)
% READ_DISTANCE  Ultrasonic distance in metres (median of n readings).
%
%   r = read_distance(S)       3 readings
%   r = read_distance(S, 1)    1 reading (faster, used while driving)
%
%   Returns Inf when nothing is in range (reading >= C.ev3.sonicMax).

if nargin < 2, n = 3; end
v = zeros(n, 1);
for k = 1:n
    v(k) = double(readDistance(S.sonic));
end
r = median(v);
if r >= S.C.ev3.sonicMax
    r = Inf;
end
end
