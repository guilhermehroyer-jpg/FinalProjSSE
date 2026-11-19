function [F, mask, cands] = fire_features(img, C)
% FIRE_FEATURES  Find candidate blobs and describe their shape and colour layers.
%
%   [F, mask, cands] = fire_features(img)        settings from config.m
%   [F, mask, cands] = fire_features(img, C)
%
%   F      the best candidate: the biggest blob that passes all rules of
%          classify_fire, or (if none passes) the one whose shape is closest
%          to the flame. F.found = false if there is no blob at all.
%   mask   the cleaned colour mask (fire_mask)
%   cands  features of every candidate checked (the C.fire.maxBlobs biggest)
%
%   Checking several blobs matters: a big red jacket in view must not hide
%   a smaller fire behind it.
%
%   Features of a blob:
%     area        fraction of the image covered (also a distance proxy)
%     meanSat     mean saturation
%     shapeIoU    TEMPLATE MATCHING (book 6.4.2): the blob's silhouette, cut to
%                 its bounding box and resized to the template size, compared
%                 with the flame template as intersection / union
%                 (1 = identical shape, ~0.6 for circles and rectangles)
%     aspect      bounding-box height / width (the flame is ~1.4)
%     fracRed, fracOrange, fracYellow   share of the blob in each colour layer
%     yellowPos   vertical position of the yellow core inside the blob
%                 (0 = top, 1 = bottom; ~0.85 for our flame)
%     circularity, extent, solidity     extra shape descriptors (book 6.2.1)
%     centroid, bbox, steer             where it is (steer: -1 left .. +1 right)
%     imgSize, shape                    image size, normalised silhouette

if nargin < 2, C = config(); end
P = C.fire.mask;
T = fire_template(C);

[mask, H, S] = fire_mask(img, P);
[h, w] = size(mask);

stats = regionprops(mask, 'Area', 'Centroid', 'BoundingBox', 'Perimeter', ...
                    'Extent', 'Solidity', 'PixelIdxList', 'Image');
[~, order] = sort([stats.Area], 'descend');
order = order(1:min(C.fire.maxBlobs, numel(order)));

list = {};
for k = order
    if stats(k).Area / (h*w) < C.fire.rules.minArea
        break                                % sorted by size: the rest is smaller
    end
    list{end+1} = blob_features(stats(k), H, S, T, h, w, P); %#ok<AGROW>
end

if isempty(list)
    F = make_F(false, 0, NaN, NaN, NaN, NaN, 0, NaN, 0, 0, 0, 0, ...
               [NaN NaN], [NaN NaN NaN NaN], NaN, [h w], false(size(T)));
    cands = F([]);
    return
end

cands = [list{:}];
pass  = arrayfun(@(f) classify_fire(f, C.fire.rules), cands);
if any(pass)
    F = cands(find(pass, 1));                % biggest blob that passes
else
    [~, i] = max([cands.shapeIoU]);          % closest shape, for feedback
    F = cands(i);
end
end

%% ------------------------------------------------------------------------
function f = blob_features(b, H, S, T, h, w, P)
hb = H(b.PixelIdxList);
isRed    = hb >= P.hueHigh | hb < P.redMax;
isOrange = hb >= P.redMax  & hb < P.orangeMax;
isYellow = hb >= P.orangeMax & hb <= P.hueLow;

top = b.BoundingBox(2);
hgt = b.BoundingBox(4);
if any(isYellow)
    [rows, ~] = ind2sub([h w], b.PixelIdxList(isYellow));
    yellowPos = (mean(rows) - top) / hgt;
else
    yellowPos = 0;
end

shape = imresize(double(b.Image), size(T)) > 0.5;      % normalised silhouette
iou   = nnz(shape & T) / max(nnz(shape | T), 1);

f = make_F(true, b.Area/(h*w), 4*pi*b.Area/max(b.Perimeter, 1)^2, b.Extent, ...
    b.Solidity, mean(S(b.PixelIdxList)), iou, hgt/b.BoundingBox(3), ...
    mean(isRed), mean(isOrange), mean(isYellow), yellowPos, ...
    b.Centroid, b.BoundingBox, (b.Centroid(1) - w/2)/(w/2), [h w], shape);
end

function F = make_F(found, area, circ, extent, solidity, meanSat, iou, aspect, ...
                    fr, fo, fy, ypos, centroid, bbox, steer, imgSize, shape)
% One place that builds the struct, so every F has the same fields in the same order.
F = struct('found', found, 'area', area, 'circularity', circ, 'extent', extent, ...
    'solidity', solidity, 'meanSat', meanSat, 'shapeIoU', iou, 'aspect', aspect, ...
    'fracRed', fr, 'fracOrange', fo, 'fracYellow', fy, 'yellowPos', ypos, ...
    'centroid', centroid, 'bbox', bbox, 'steer', steer, 'imgSize', imgSize, 'shape', shape);
end
