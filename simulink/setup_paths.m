function root = setup_paths()
%SETUP_PATHS  Put this repository's simulink/ and matlab/ folders on the path.
%   root = setup_paths() also returns the repository root folder.
here = fileparts(mfilename('fullpath'));
root = fileparts(here);
addpath(here);
addpath(fullfile(root, 'matlab'));
end
