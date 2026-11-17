%% SETUP  Add all project folders to the MATLAB path. Run once per MATLAB session.
root = fileparts(mfilename('fullpath'));
folders = {'', 'sound', 'vision', 'robot', 'behaviours', 'mapping', 'tools'};
for k = 1:numel(folders)
    addpath(fullfile(root, folders{k}));
end
fprintf('FinalProjSSE: project folders added to the path.\n');
clear root folders k
