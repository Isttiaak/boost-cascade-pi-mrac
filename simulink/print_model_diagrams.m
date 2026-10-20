function print_model_diagrams(modeldir, figdir)
%PRINT_MODEL_DIAGRAMS  Save each model in modeldir (top level and its main
%   subsystems) as PNG block diagrams in figdir.
if ~exist(figdir, 'dir')
    mkdir(figdir);
end
files = dir(fullfile(modeldir, '*.slx'));
for k = 1:numel(files)
    [~, mdl] = fileparts(files(k).name);
    try
        load_system(fullfile(modeldir, files(k).name));
        systems = [{mdl}; find_system(mdl, 'SearchDepth', 1, 'BlockType', 'SubSystem')];
        for j = 1:numel(systems)
            sysName = systems{j};
            if j > 1 && ~any(contains(sysName, {'Controller', 'Boost converter', ...
                    'circuit model', 'Fig. 6', 'Plant', 'PWM'}))
                continue
            end
            name = regexprep(sysName, '[^A-Za-z0-9_]+', '_');
            print(['-s' sysName], '-dpng', '-r110', fullfile(figdir, [name '.png']));
        end
        close_system(mdl, 0);
    catch err
        fprintf('  diagram of %s not printed: %s\n', mdl, err.message);
    end
end
fprintf('  model diagrams in %s\n', figdir);
end
