function [mask, H, S, V] = fire_mask(img, P)
% FIRE_MASK  Binary mask of pixels that could belong to our printed flame.
%
%   [mask, H, S, V] = fire_mask(img, P)      P = C.fire.mask from config.m
%
%   1. RGB -> HSV (book Ch. 4). Keep:
%        red or orange pixels that are saturated (S >= P.satMin), and
%        yellow pixels that are at least a little saturated (S >= P.satMinYellow)
%      and not too dark (V >= P.valMin). White paper, grey walls and
%      shadows have low saturation and drop out.
%   2. Opening removes specks, closing joins small gaps, and filling holes
%      makes the flame one solid silhouette.
%
%   H, S, V are returned so the colour layers can be measured afterwards.

hsv = rgb2hsv(img);
H = hsv(:, :, 1);  S = hsv(:, :, 2);  V = hsv(:, :, 3);

redOrange = (H < P.orangeMax | H >= P.hueHigh) & S >= P.satMin;
yellow    = (H >= P.orangeMax & H <= P.hueLow) & S >= P.satMinYellow;
mask = (redOrange | yellow) & V >= P.valMin;

mask = imopen(mask,  strel('disk', P.openRadius));
mask = imclose(mask, strel('disk', P.closeRadius));
mask = imfill(mask, 'holes');
end
