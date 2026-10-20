%SEC5_6_SIMULATIONS  Recreation of Sections V-VI (closed-loop simulations).
%   Figs. 13-15 learning-rate study, Figs. 16-18 controller comparison,
%   Table 10, simulated version of the experiment (Figs. 22-24) and a
%   single-PI loss-sensitivity check.
%   Plant: switching converter, Table 3 values, ideal switch + diode, cold start.
clear; close all;
P = paper_values();  S = viz_style();
prm = boost_params();
plant = 'switching';
nper = round(1/(P.fsw*P.Ts));
VREF  = @(t) piecewise(t, [0 0.2 0.4], [30 40 50]);
LOAD  = @(t) piecewise(t, [0 0.2 0.4], [16 10 20]);
VIN   = @(t) piecewise(t, [0 0.2], [15 25]);

%% ---------------- learning-rate study (Figs. 13-15) -------------------------
g = P.gammas_study;  cols = {S.c1, S.c2, S.c3};
R = cell(1, 3);
for k = 1:3
    R{k} = boost_sim(0.6, plant, 'mrac', prm, struct('vref', VREF, 'gamma', g(k)));
    fprintf('gamma = %.1f: theta before 0.2 s = %.3f, before 0.4 s = %.3f, at 0.6 s = %.3f\n', g(k), ...
        R{k}.theta(round(0.199/P.Ts)), R{k}.theta(round(0.399/P.Ts)), R{k}.theta(end));
end
lbl = arrayfun(@(x) sprintf('\\gamma = %g', x), g, 'UniformOutput', false);

f = figure('Position', [100 100 860 420], 'Color', 'w'); ax = axes; hold on; grid on;
for k = 1:3, plot(R{k}.t, R{k}.v - R{k}.ym, 'Color', cols{k}, 'LineWidth', 0.8); end
xlabel('Time (s)'); ylabel('Tracking error e = V_{out} - V_{ref(out)} (V)'); xlim([0 0.6]); ylim([-15 15]);
legend(lbl, 'Location', 'northwest', 'Orientation', 'horizontal');
title('Fig. 13 recreated - tracking error for varying learning rates');
add_inset(ax, [0.09 0.06 0.38 0.32], [0.2 0.215], [-6 8], cellfun(@(r) r.t, R, 'UniformOutput', false), ...
          cellfun(@(r) r.v - r.ym, R, 'UniformOutput', false), cols, {'-','-','-'});
print(f, fullfile(S.figdir, 'fig13_tracking_error_learning_rates'), '-dpng', '-r150');

f = figure('Position', [100 100 860 380], 'Color', 'w'); hold on; grid on;
for k = 1:3
    m = R{k}.t >= 0.19 & R{k}.t <= 0.26;
    plot(R{k}.t(m), R{k}.theta(m), 'Color', cols{k}, 'LineWidth', 1.2);
end
xlabel('Time (s)'); ylabel('Adaptation parameter \theta'); xlim([0.19 0.26]);
legend(lbl, 'Location', 'northeast', 'Orientation', 'horizontal');
title('Fig. 14 recreated - adaptation parameter \theta around the 30\rightarrow40 V step');
print(f, fullfile(S.figdir, 'fig14_theta_learning_rates'), '-dpng', '-r150');

f = figure('Position', [100 100 860 420], 'Color', 'w'); ax = axes; hold on; grid on;
for k = 1:3
    m = R{k}.t >= 0.1;
    plot(R{k}.t(m), R{k}.v(m), 'Color', cols{k}, 'LineWidth', 0.8);
end
xlabel('Time (s)'); ylabel('Plant output voltage (V)'); xlim([0.1 0.6]); ylim([25 80]);
legend(lbl, 'Location', 'southeast', 'Orientation', 'horizontal');
title('Fig. 15 recreated - plant output voltage for varying learning rates');
add_inset(ax, [0.06 0.52 0.42 0.44], [0.4 0.42], [38 70], cellfun(@(r) r.t, R, 'UniformOutput', false), ...
          cellfun(@(r) r.v, R, 'UniformOutput', false), cols, {'-','-','-'});
print(f, fullfile(S.figdir, 'fig15_output_voltage_learning_rates'), '-dpng', '-r150');

%% ---------------- controller comparisons (Figs. 16-18) ------------------------
res16 = compare(plant, prm, S, P, 0.5, struct('vref', 40, 'rload', LOAD), ...
    'Fig. 16 recreated - load steps 16 \Omega \rightarrow 10 \Omega (0.2 s) \rightarrow 20 \Omega (0.4 s)', ...
    'fig16_load_variation', {[0.13 0.08 0.3 0.42], [0 0.03], [24 54]; [0.55 0.08 0.3 0.42], [0.2 0.215], [36 44]}, [0 55]);
compare(plant, prm, S, P, 0.5, struct('vref', 40, 'rload', LOAD, 'vin', VIN), ...
    'Fig. 17 recreated - V_{in} 15 \rightarrow 25 V (0.2 s), load 16 \rightarrow 10 \rightarrow 20 \Omega', ...
    'fig17_load_and_input_variation', {[0.13 0.08 0.3 0.42], [0 0.05], [18 54]; [0.55 0.08 0.3 0.42], [0.4 0.43], [38 44]}, [0 60]);
res18 = compare(plant, prm, S, P, 0.5, struct('vref', VREF), ...
    'Fig. 18 recreated - reference steps 30 \rightarrow 40 V (0.2 s) \rightarrow 50 V (0.4 s)', ...
    'fig18_reference_variation', {[0.10 0.08 0.25 0.4], [0 0.06], [18 54]; [0.40 0.08 0.25 0.4], [0.2 0.24], [28 46]; ...
                                  [0.71 0.08 0.25 0.4], [0.4 0.44], [38 58]}, [0 60]);

%% ---------------- Table 10 (30 -> 40 V step, stepinfo defaults: yinit = 0) ----
fid = fopen(fullfile(S.tabdir, 'table10_closed_loop_step.csv'), 'w');
fprintf(fid, 'Source,Controller,%s\n', strjoin(P.metric_names, ','));
for k = 1:3
    fprintf(fid, 'PAPER Table 10,%s,%s\n', P.table10_names{k}, num2str(P.table10(k,:), '%g,'));
end
for k = 1:4
    r = res18{k};  m = r.t >= 0.2 & r.t < 0.4;
    Si = step_metrics(r.t(m) - 0.2, r.v(m), 40, 0);
    vals = cellfun(@(n) Si.(n), P.metric_names);
    fprintf(fid, 'Recreated,%s,%s\n', S.ctrl_labels{k}, num2str(vals, '%.5g,'));
    fprintf('%-44s %s\n', S.ctrl_labels{k}, num2str(vals, '%10.4g'));
end
fclose(fid);

%% ---------------- simulated experiment 25 V -> 40 V (Figs. 22-24) ---------------
f = figure('Position', [100 100 1400 520], 'Color', 'w');
for k = 1:4
    r = boost_sim(0.2, plant, S.ctrl_names{k}, prm, struct('vref', @(t) piecewise(t, [0 0.1], [25 40])));
    m = r.t >= 0.09 & r.t <= 0.14;
    subplot(2,4,k); plot((r.t(m)-0.1)*1e3, r.v(m), 'Color', S.ctrl_colors{k}); grid on; ylim([20 50]);
    title(S.ctrl_labels{k}, 'FontSize', 8); if k == 1, ylabel('Output voltage (V)'); end
    subplot(2,4,k+4); plot((r.t(m)-0.1)*1e3, r.iL(m), 'Color', S.ctrl_colors{k}); grid on; ylim([-1 45]);
    xlabel('Time after step (ms)'); if k == 1, ylabel('Inductor current (A)'); end
    mm = r.t >= 0.1 & r.t < 0.2 - nper*P.Ts;
    vavg = movmean(r.v, nper);
    Si = step_metrics(r.t(mm) - 0.1, vavg(mm), 40, 25);
    fprintf('%-44s rise %.2f ms, settling %.2f ms, overshoot %.1f %%\n', S.ctrl_labels{k}, ...
            Si.RiseTime*1e3, Si.SettlingTime*1e3, Si.Overshoot);
end
sgtitle('Figs. 22-24 recreated in simulation - reference step 25 V \rightarrow 40 V');
print(f, fullfile(S.figdir, 'fig22_24_simulated_experiment'), '-dpng', '-r150');

%% ---------------- single-PI sensitivity to device losses -----------------------
r0 = boost_sim(0.5, plant, 'pi', prm, struct('vref', VREF));
r1 = boost_sim(0.5, plant, 'pi', boost_params('Ron', 0.1, 'Rd', 0.001, 'Vf', 0.8), struct('vref', VREF));
f = figure('Position', [100 100 920 400], 'Color', 'w'); hold on; grid on;
plot(r0.t, r0.v, 'Color', S.c1, 'LineWidth', 0.8);
plot(r1.t, r1.v, 'Color', S.c2, 'LineWidth', 0.8);
xlabel('Time (s)'); ylabel('Output voltage (V)'); xlim([0 0.5]); ylim([0 55]);
legend('Lossless switch and diode', 'Simulink default devices (R_{on} = 0.1 \Omega, V_f = 0.8 V)', 'Location', 'southeast');
title('Single PI (Eq. 33) under reference steps: effect of small device losses');
print(f, fullfile(S.figdir, 'extra_single_pi_loss_sensitivity'), '-dpng', '-r150');

%% ---------------- local function -------------------------------------------------
function res = compare(plant, prm, S, P, T, opts, ttl, fname, insets, yl)
opts.gamma = P.gamma_design;
res = cell(1, 4);
f = figure('Position', [100 100 940 480], 'Color', 'w'); ax = axes; hold on; grid on;
for k = 1:4
    res{k} = boost_sim(T, plant, S.ctrl_names{k}, prm, opts);
    plot(res{k}.t, res{k}.v, S.ctrl_styles{k}, 'Color', S.ctrl_colors{k}, 'LineWidth', 0.9);
end
xlabel('Time (s)'); ylabel('Output voltage (V)'); xlim([0 T]); ylim(yl);
legend(S.ctrl_labels, 'Location', 'southoutside', 'NumColumns', 2);
title(ttl);
for j = 1:size(insets, 1)
    add_inset(ax, insets{j,1}, insets{j,2}, insets{j,3}, cellfun(@(r) r.t, res, 'UniformOutput', false), ...
              cellfun(@(r) r.v, res, 'UniformOutput', false), S.ctrl_colors, S.ctrl_styles);
end
print(f, fullfile(S.figdir, fname), '-dpng', '-r150');
end
