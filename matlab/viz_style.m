function S = viz_style()
%VIZ_STYLE  Colours shared by all MATLAB figures (same palette as the Simulink study figures).
h = @(s) sscanf(s(2:end), '%2x%2x%2x', [1 3]) / 255;
S.c1 = h('#2a78d6');  S.c2 = h('#eb6834');  S.c3 = h('#1baf7a');  S.c4 = h('#eda100');
S.ink2 = h('#52514e'); S.muted = h('#898781'); S.grid = h('#e1e0d9');
S.ctrl_names  = {'pi', 'cascade', 'mrac', 'mrac_ms'};
S.ctrl_labels = {'Single PI', 'Cascade PI', 'Cascade PI-MRAC (as written)', ...
                 'Cascade PI-MRAC, model-following set-point'};
S.ctrl_colors = {S.c1, S.c2, S.c3, S.c4};
S.ctrl_styles = {'-', '-', '-', '--'};
S.figdir = fullfile('..', 'results_matlab', 'figures');
S.tabdir = fullfile('..', 'results_matlab', 'tables');
if ~exist(S.figdir, 'dir'), mkdir(S.figdir); end
if ~exist(S.tabdir, 'dir'), mkdir(S.tabdir); end
end
