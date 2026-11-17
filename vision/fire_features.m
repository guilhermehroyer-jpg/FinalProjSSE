function [F, mask] = fire_features(img, P)
% FIRE_FEATURES  Find the largest red blob in an image and measure it.
%
%   [F, mask] = fire_features(img)        colour thresholds from config.m (C.fire.mask)
%   [F, mask] = fire_features(img, P)     your own thresholds
%
%   Steps (book Ch. 4):
%     1. RGB -> HSV, threshold hue (red sits at BOTH ends of the hue circle,
%        orange just above 0), saturation and brightness -> binary mask
%     2. Morphological opening (removes specks) and closing (fills gaps), fill
%        holes (the yellow centre of a cartoon flame becomes part of the blob)
%     3. Label connected components, keep the largest blob
%     4. Measure the blob
%
%   F.found        true if any red blob was found
%   F.area         blob area as a FRACTION of the image (0..1), so it does not
%                  depend on the camera resolution; also a distance proxy
%   F.circularity  4*pi*area/perimeter^2  (1 = perfect circle, small = ragged/thin)
%   F.extent       blob area / bounding-box area (how "solid" the shape is)
%   F.meanSat      mean saturation of the blob (printed red is very saturated)
%   F.centroid     [x y] in pixels
%   F.bbox         [x y width height] in pixels
%   F.steer        horizontal offset of the centroid: -1 = far left, 0 = centre, +1 = far right
%   F.imgSize      [height width] of the processed image

if nargin < 2
    C = config();
    P = C.fire.mask;
end

%% 1. Colour threshold in HSV
hsv = rgb2hsv(img);
H = hsv(:, :, 1);  S = hsv(:, :, 2);  V = hsv(:, :, 3);
mask = (H <= P.hueLow | H >= P.hueHigh) & S >= P.satMin & V >= P.valMin;

%% 2. Clean the mask
mask = imopen(mask,  strel('disk', P.openRadius));
mask = imclose(mask, strel('disk', P.closeRadius));
mask = imfill(mask, 'holes');

%% 3. Largest connected component
stats = regionprops(mask, 'Area', 'Centroid', 'BoundingBox', 'Perimeter', ...
                    'Extent', 'PixelIdxList');
[h, w] = size(mask);

if isempty(stats)
    F = struct('found', false, 'area', 0, 'circularity', NaN, 'extent', NaN, ...
               'meanSat', NaN, 'centroid', [NaN NaN], 'bbox', [NaN NaN NaN NaN], ...
               'steer', NaN, 'imgSize', [h w]);
    return
end
[~, i] = max([stats.Area]);
b = stats(i);

%% 4. Measurements
F.found       = true;
F.area        = b.Area / (h*w);
F.circularity = 4*pi*b.Area / max(b.Perimeter, 1)^2;
F.extent      = b.Extent;
F.meanSat     = mean(S(b.PixelIdxList));
F.centroid    = b.Centroid;
F.bbox        = b.BoundingBox;
F.steer       = (b.Centroid(1) - w/2) / (w/2);
F.imgSize     = [h w];
end

