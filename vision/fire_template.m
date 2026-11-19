function T = fire_template(C, rebuild)
% FIRE_TEMPLATE  Silhouette of our printed flame, used for template matching.
%
%   T = fire_template()            load it (build it the first time)
%   T = fire_template(C, true)     rebuild from C.paths.fireTemplateImage
%
%   T is a TxT logical image (C.fire.templateSize, 64 by default): the
%   flame's silhouette cut to its bounding box and resized. It is built from
%   the same picture we print, using the same colour mask as the live
%   detector, and saved to models/fire_template.mat.
%   It is kept in memory after the first call, so live loops stay fast.
%   Rebuild it if you print a different picture.

persistent cachedT cachedPath

if nargin < 1 || isempty(C), C = config(); end
if nargin < 2, rebuild = false; end

if ~rebuild && ~isempty(cachedT) && strcmp(cachedPath, C.paths.fireTemplate)
    T = cachedT;
    return
end

if rebuild || ~exist(C.paths.fireTemplate, 'file')
    img   = imread(C.paths.fireTemplateImage);
    mask  = fire_mask(img, C.fire.mask);
    stats = regionprops(mask, 'Area', 'Image');
    if isempty(stats)
        error('fire_template: no flame found in %s', C.paths.fireTemplateImage);
    end
    [~, i] = max([stats.Area]);
    T = imresize(double(stats(i).Image), C.fire.templateSize*[1 1]) > 0.5;
    if ~exist(fileparts(C.paths.fireTemplate), 'dir')
        mkdir(fileparts(C.paths.fireTemplate));
    end
    save(C.paths.fireTemplate, 'T');
    fprintf('Built the fire template from %s\n', C.paths.fireTemplateImage);
else
    data = load(C.paths.fireTemplate, 'T');
    T = data.T;
end

cachedT    = T;
cachedPath = C.paths.fireTemplate;
end
