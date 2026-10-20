function plot_study_figures(R, plant, figdir, pyTraceDir)
%PLOT_STUDY_FIGURES  Paper figures from a run_simulink_study result map.
%   plot_study_figures(R, plant, figdir)              Figs. 7, 13-18, 22-24
%   plot_study_figures(R, plant, figdir, pyTraceDir)  plus Simulink-vs-Python overlays
if ~exist(figdir, 'dir')
    mkdir(figdir);
end
C = colors();
tag = upper(plant);
ctrls = {'pi', 'cascade', 'mrac', 'mrac_mf'};
labels = {'Single PI', 'Cascade PI', 'Cascade PI-MRAC (as written)', ...
    'Cascade PI-MRAC, model-following'};
ccol = {C.c1, C.c2, C.c3, C.c4};
csty = {'-', '-', '-', '--'};

%% Fig. 7 -------------------------------------------------------------------
if isKey(R, 'ol_diode')
    r = R('ol_diode');
    f = newfig(900, 420);
    hold on; grid on; box on;
    names = {};
    if all(isfinite(r.v_sps))
        plot(r.t, r.v_sps, 'Color', C.c1, 'LineWidth', 1.3);
        names{end + 1} = 'Circuit model (Specialized Power Systems)';
    else
        plot(r.t, r.v, 'Color', C.c1, 'LineWidth', 1.3);
        names{end + 1} = 'Fig. 6 equations with diode limit';
    end
    plot(r.t, r.v_de_bidir, 'Color', C.c2);
    plot(r.t, r.v_tf, 'Color', C.ink2);
    names = [names, {'Differential-equation model (Fig. 6 as drawn)', ...
        'Transfer-function model (Eq. 31)'}];
    xlabel('Time (s)'); ylabel('Voltage (V)'); xlim([0 0.05]); ylim([-2 82]);
    legend(names, 'Location', 'southeast');
    title(sprintf('Fig. 7 in Simulink (%s run) - open loop, D = 0.5, cold start', tag));
    save_fig(f, figdir, 'fig07_openloop_models');
end

%% Figs. 13-15 ---------------------------------------------------------------
lr = {'lr_g0.1', 'lr_g0.5', 'lr_g1'};
if all(cellfun(@(k) isKey(R, k), lr))
    gl = {'\gamma = 0.1', '\gamma = 0.5', '\gamma = 1'};
    gc = {C.c1, C.c2, C.c3};
    f = newfig(860, 420); ax = gca; hold on; grid on; box on;
    X = cell(1, 3); Y = cell(1, 3);
    for k = 1:3
        r = R(lr{k});
        X{k} = r.t; Y{k} = r.v - r.ym;
        plot(r.t, Y{k}, 'Color', gc{k}, 'LineWidth', 0.8);
    end
    xlabel('Time (s)'); ylabel('Tracking error V_{out} - V_{ref(out)} (V)');
    xlim([0 0.6]); ylim([-15 15]);
    legend(gl, 'Location', 'northwest', 'Orientation', 'horizontal');
    title(sprintf('Fig. 13 in Simulink (%s) - tracking error for varying learning rates', tag));
    add_inset(ax, [0.09 0.06 0.38 0.32], [0.2 0.215], [-6 8], X, Y, gc, {'-', '-', '-'});
    save_fig(f, figdir, 'fig13_tracking_error');

    f = newfig(860, 380); hold on; grid on; box on;
    for k = 1:3
        r = R(lr{k});
        m = r.t >= 0.19 & r.t <= 0.26;
        plot(r.t(m), r.theta(m), 'Color', gc{k}, 'LineWidth', 1.2);
    end
    xlabel('Time (s)'); ylabel('Adaptation parameter \theta'); xlim([0.19 0.26]);
    legend(gl, 'Location', 'northeast', 'Orientation', 'horizontal');
    title(sprintf('Fig. 14 in Simulink (%s) - \\theta around the 30 \\rightarrow 40 V step', tag));
    save_fig(f, figdir, 'fig14_theta');

    f = newfig(860, 420); ax = gca; hold on; grid on; box on;
    for k = 1:3
        r = R(lr{k});
        m = r.t >= 0.1;
        X{k} = r.t; Y{k} = r.v;
        plot(r.t(m), r.v(m), 'Color', gc{k}, 'LineWidth', 0.8);
    end
    xlabel('Time (s)'); ylabel('Plant output voltage (V)'); xlim([0.1 0.6]); ylim([25 80]);
    legend(gl, 'Location', 'southeast', 'Orientation', 'horizontal');
    title(sprintf('Fig. 15 in Simulink (%s) - output voltage for varying learning rates', tag));
    add_inset(ax, [0.06 0.52 0.42 0.44], [0.4 0.42], [38 70], X, Y, gc, {'-', '-', '-'});
    save_fig(f, figdir, 'fig15_output_voltage');
end

%% Figs. 16-18 ----------------------------------------------------------------
figs = {'f16', 'fig16_load_steps', [0 55], ...
    'Fig. 16 in Simulink (%s) - load 16 \\rightarrow 10 \\rightarrow 20 \\Omega', ...
    {[0.13 0.08 0.3 0.42], [0 0.03], [24 54]; [0.55 0.08 0.3 0.42], [0.2 0.215], [36 44]};
    'f17', 'fig17_load_and_vin_steps', [0 60], ...
    'Fig. 17 in Simulink (%s) - V_{in} 15 \\rightarrow 25 V and load steps', ...
    {[0.13 0.08 0.3 0.42], [0 0.05], [18 54]; [0.55 0.08 0.3 0.42], [0.4 0.43], [38 44]};
    'f18', 'fig18_reference_steps', [0 60], ...
    'Fig. 18 in Simulink (%s) - reference 30 \\rightarrow 40 \\rightarrow 50 V', ...
    {[0.10 0.08 0.25 0.4], [0 0.06], [18 54]; [0.40 0.08 0.25 0.4], [0.2 0.24], [28 46]; ...
    [0.71 0.08 0.25 0.4], [0.4 0.44], [38 58]}};
for i = 1:size(figs, 1)
    keys = cellfun(@(c) [figs{i, 1} '_' c], ctrls, 'UniformOutput', false);
    if ~all(cellfun(@(k) isKey(R, k), keys))
        continue
    end
    f = newfig(940, 480); ax = gca; hold on; grid on; box on;
    X = cell(1, 4); Y = cell(1, 4);
    for k = 1:4
        r = R(keys{k});
        X{k} = r.t; Y{k} = r.v;
        plot(r.t, r.v, csty{k}, 'Color', ccol{k}, 'LineWidth', 0.9);
    end
    xlabel('Time (s)'); ylabel('Output voltage (V)'); xlim([0 0.5]); ylim(figs{i, 3});
    legend(labels, 'Location', 'southoutside', 'NumColumns', 2);
    title(sprintf(figs{i, 4}, tag));
    ins = figs{i, 5};
    for j = 1:size(ins, 1)
        add_inset(ax, ins{j, 1}, ins{j, 2}, ins{j, 3}, X, Y, ccol, csty);
    end
    save_fig(f, figdir, figs{i, 2});
end

%% Figs. 22-24 (simulation of the experiment) ---------------------------------
keys = cellfun(@(c) ['exp_' c], ctrls, 'UniformOutput', false);
if all(cellfun(@(k) isKey(R, k), keys))
    f = newfig(1400, 520);
    for k = 1:4
        r = R(keys{k});
        m = r.t >= 0.09 & r.t <= 0.14;
        subplot(2, 4, k);
        plot((r.t(m) - 0.1) * 1e3, r.v(m), 'Color', ccol{k}); grid on; ylim([20 50]);
        title(labels{k}, 'FontSize', 8);
        if k == 1, ylabel('Output voltage (V)'); end
        subplot(2, 4, k + 4);
        plot((r.t(m) - 0.1) * 1e3, r.iL(m), 'Color', ccol{k}); grid on; ylim([-1 45]);
        xlabel('Time after the step (ms)');
        if k == 1, ylabel('Inductor current (A)'); end
    end
    sgtitle(sprintf('Figs. 22-24 in Simulink (%s) - reference step 25 \\rightarrow 40 V', tag));
    save_fig(f, figdir, 'fig22_24_experiment');
end

%% overlays with the Python reference --------------------------------------------
if nargin > 3 && exist(pyTraceDir, 'dir')
    plot_overlays(R, plant, figdir, pyTraceDir, C, ctrls, labels, ccol);
end
end

% -------------------------------------------------------------------------
function plot_overlays(R, plant, figdir, pyTraceDir, C, ctrls, labels, ccol)
f = newfig(1200, 700);
for k = 1:4
    key = ['f18_' ctrls{k}];
    file = fullfile(pyTraceDir, [key '.csv']);
    if ~isKey(R, key) || ~exist(file, 'file')
        continue
    end
    py = readmatrix(file);
    r = R(key);
    subplot(2, 2, k); hold on; grid on; box on;
    plot(r.t, r.v, 'Color', ccol{k}, 'LineWidth', 1.4);
    plot(py(:, 1), py(:, 2), '--', 'Color', C.ink, 'LineWidth', 0.9);
    xlim([0.195 0.24]); ylim([28 47]);
    title(labels{k}, 'FontSize', 9);
    xlabel('Time (s)'); ylabel('V_{out} (V)');
    legend({sprintf('Simulink (%s)', upper(plant)), 'Python reference'}, 'Location', 'southeast');
end
sgtitle('30 \rightarrow 40 V reference step: Simulink against the Python recreation');
save_fig(f, figdir, 'verify_overlay_f18');

f = newfig(900, 420); hold on; grid on; box on;
lr = {'lr_g0.1', 'lr_g0.5', 'lr_g1'};
gc = {C.c1, C.c2, C.c3};
h = gobjects(0);
for k = 1:3
    file = fullfile(pyTraceDir, [lr{k} '.csv']);
    if ~isKey(R, lr{k}) || ~exist(file, 'file')
        continue
    end
    py = readmatrix(file);
    r = R(lr{k});
    h(end + 1) = plot(r.t, r.theta, 'Color', gc{k}, 'LineWidth', 1.6); %#ok<AGROW>
    plot(py(:, 1), py(:, 4), '--', 'Color', C.ink, 'LineWidth', 0.9);
end
xlabel('Time (s)'); ylabel('\theta'); xlim([0 0.6]); ylim([-1.5 1.1]);
legend(h, {'\gamma = 0.1 Simulink', '\gamma = 0.5 Simulink', '\gamma = 1 Simulink'}, ...
    'Location', 'southwest');
title('Adaptation parameter: Simulink (solid) against the Python recreation (dashed)');
save_fig(f, figdir, 'verify_overlay_theta');
end

function C = colors()
h = @(s) sscanf(s(2:end), '%2x%2x%2x', [1 3]) / 255;
C.c1 = h('#2a78d6'); C.c2 = h('#eb6834'); C.c3 = h('#1baf7a'); C.c4 = h('#eda100');
C.ink = h('#0b0b0b'); C.ink2 = h('#52514e');
end

function f = newfig(w, hgt)
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 w hgt]);
end

function save_fig(f, figdir, name)
file = fullfile(figdir, [name '.png']);
try
    exportgraphics(f, file, 'Resolution', 150);
catch
    print(f, file, '-dpng', '-r150');
end
close(f);
fprintf('  figure %s\n', file);
end
