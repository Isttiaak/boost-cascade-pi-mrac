%SEC2_3_MODELLING  Recreation of Sections II-III (plant modelling).
%   Fig. 1  frequency response duty -> v_out of the switching converter measured
%           with a 0.03 sinusoidal duty perturbation (and a small-signal check)
%   Eq. 2   1-zero/2-pole TF fitted to the points
%   Table 6 and Fig. 5  printed TFs vs Eq. 31 evaluated correctly
%   Fig. 7  circuit, differential-equation and transfer-function models
clear; close all;
P = paper_values();  S = viz_style();
prm = boost_params();                 % Table 3, ideal switch and diode
W_MAX = 2*pi*P.fsw/10;  AMP_SMALL = 0.0005;
w0 = (1 - P.D)/sqrt(P.L*P.C);
w = sort([logspace(1, log10(W_MAX), 20), w0*[0.92 0.97 1 1.03 1.08]]);
wd = logspace(1, 6, 600);

%% ---------------- Fig. 1 / Eq. 2 -------------------------------------------
fprintf('estimating frequency response (takes a few minutes in MATLAB) ...\n');
H03  = fr_estimate(prm, P.perturb_amp, w, P);
Hss  = fr_estimate(prm, AMP_SMALL, w, P);
[n03, d03, fit03] = fit_tf_1z2p(w, H03);
[nss, dss, fitss] = fit_tf_1z2p(w, Hss);
[nv, ~, dv] = averaged_linear_tf(prm);
fprintf('fit amp 0.03  : num %s den %s (fit %.1f%%)\n', mat2str(n03, 5), mat2str(d03, 5), fit03);
fprintf('fit amp %g: num %s den %s (fit %.1f%%)\n', AMP_SMALL, mat2str(nss, 5), mat2str(dss, 5), fitss);

f = figure('Position', [100 100 1100 620], 'Color', 'w');
data = {H03, Hss}; fits = {{n03, d03}, {nss, dss}}; amps = [P.perturb_amp AMP_SMALL];
for c = 1:2
    subplot(2, 2, c); hold on; grid on;
    semilogx(wd, mag_db(frf(P.eq2_num, P.eq2_den, wd)), '--', 'Color', S.ink2);
    semilogx(wd, mag_db(frf(nv, dv, wd)), 'Color', S.c3);
    semilogx(wd, mag_db(frf(fits{c}{1}, fits{c}{2}, wd)), 'Color', S.c2, 'LineWidth', 1.4);
    semilogx(w, mag_db(data{c}), 'o', 'Color', S.c1, 'MarkerFaceColor', S.c1, 'MarkerSize', 4);
    set(gca, 'XScale', 'log'); ylim([-10 75]); ylabel('Magnitude (dB)');
    title(sprintf('Perturbation amplitude %g', amps(c)));
    if c == 1, legend('Paper Eq. 2 (printed)', 'Averaged model = Eq. 31', 'Fitted 1-zero/2-pole TF', ...
                      'Measured points (switching model)', 'Location', 'southwest'); end
    subplot(2, 2, c + 2); hold on; grid on;
    semilogx(wd, ph(frf(P.eq2_num, P.eq2_den, wd)), '--', 'Color', S.ink2);
    semilogx(wd, ph(frf(nv, dv, wd)), 'Color', S.c3);
    semilogx(wd, ph(frf(fits{c}{1}, fits{c}{2}, wd)), 'Color', S.c2, 'LineWidth', 1.4);
    semilogx(w, ph(data{c}), 'o', 'Color', S.c1, 'MarkerFaceColor', S.c1, 'MarkerSize', 4);
    set(gca, 'XScale', 'log'); ylim([-280 20]); yticks([-270 -180 -90 0]);
    ylabel('Phase (deg)'); xlabel('Frequency (rad/s)');
end
sgtitle('Fig. 1 recreated - duty-to-output frequency response at D = 0.5');
print(f, fullfile(S.figdir, 'fig01_frequency_response_estimation'), '-dpng', '-r150');

%% ---------------- Table 6 / Fig. 5 ----------------------------------------
num31 = [-P.L*P.Vdc, P.R*P.Vdc*(1-P.D)^2];
den31 = [P.L*P.R*P.C*(1-P.D)^2, P.L*(1-P.D)^2, P.R*(1-P.D)^4];
models = {'Paper Eq. 2 (printed)',  P.eq2_num,  P.eq2_den,  0.0305;
          'Paper Eq. 32 (printed)', P.eq32_num, P.eq32_den, 0.0151;
          'Eq. 31 with Table 3 values (correct)', num31, den31, 0.1;
          'Fitted TF, amp 0.03', n03, d03, 0.1;
          sprintf('Fitted TF, amp %g', AMP_SMALL), nss, dss, 0.1};
fid = fopen(fullfile(S.tabdir, 'table06_open_loop_step.csv'), 'w');
fprintf(fid, 'Model,%s\n', strjoin(P.metric_names, ','));
for k = 1:2
    fprintf(fid, 'PAPER Table 6: %s,%s\n', P.table6_names{k}, num2str(P.table6(k,:), '%g,'));
end
for k = 1:size(models, 1)
    t = linspace(0, models{k,4}, 200001)';
    y = step(tf(models{k,2}, models{k,3}), t);
    Si = step_metrics(t, y, polyval(models{k,2}, 0)/polyval(models{k,3}, 0), 0);
    vals = cellfun(@(n) Si.(n), P.metric_names);
    fprintf(fid, '%s,%s\n', models{k,1}, num2str(vals, '%.5g,'));
    fprintf('%-38s %s\n', models{k,1}, num2str(vals, '%10.4g'));
end
fclose(fid);

f = figure('Position', [100 100 1250 380], 'Color', 'w');
t = linspace(0, 0.02, 20001)';
cols = {S.ink2, S.muted, S.c1};  sty = {'--', ':', '-'};
for k = 1:3
    subplot(1,3,1); hold on; grid on; plot(t*1e3, step(tf(models{k,2}, models{k,3}), t), sty{k}, 'Color', cols{k});
    subplot(1,3,2); hold on; grid on; semilogx(wd, mag_db(frf(models{k,2}, models{k,3}, wd)), sty{k}, 'Color', cols{k});
    subplot(1,3,3); hold on; grid on; semilogx(wd, ph(frf(models{k,2}, models{k,3}, wd)), sty{k}, 'Color', cols{k});
end
subplot(1,3,1); title('(a) Open-loop unit-step response'); xlabel('Time (ms)'); ylabel('V per unit duty');
legend(models(1:3,1), 'Location', 'southeast');
subplot(1,3,2); set(gca, 'XScale', 'log'); title('(b) Magnitude'); xlabel('Frequency (rad/s)'); ylabel('dB');
subplot(1,3,3); set(gca, 'XScale', 'log'); title('(c) Phase'); xlabel('Frequency (rad/s)'); ylabel('deg');
print(f, fullfile(S.figdir, 'fig05_tf_step_and_bode'), '-dpng', '-r150');

%% ---------------- Fig. 7 ------------------------------------------------------
T7 = 0.05;
r_blk = boost_sim(T7, 'switching', 'open', prm, struct('duty', 0.5));
r_dif = boost_sim(T7, 'switching', 'open', boost_params('unidirectional', 0), struct('duty', 0.5));
y_tf = 0.5 * step(tf(num31, den31), r_blk.t);
f = figure('Position', [100 100 900 420], 'Color', 'w'); hold on; grid on;
plot(r_blk.t, r_blk.v, 'Color', S.c1, 'LineWidth', 1.3);
plot(r_dif.t, r_dif.v, 'Color', S.c2);
plot(r_blk.t, y_tf, 'Color', S.ink2);
xlabel('Time (s)'); ylabel('Voltage (V)'); xlim([0 T7]); ylim([-2 82]);
legend('Block-diagram (circuit) model: switch + diode', 'Differential-equation model: ideal switched (Fig. 6)', ...
       'Transfer-function model: Eq. 31, d = 0.5 step', 'Location', 'southeast');
title('Fig. 7 recreated - open-loop output voltage of three model types (cold start, D = 0.5)');
print(f, fullfile(S.figdir, 'fig07_model_comparison'), '-dpng', '-r150');

%% ---------------- local functions ------------------------------------------------
function H = fr_estimate(prm, amp, w, P)
% steady state at D = 0.5 (0.4 s = integer number of PWM periods)
r0 = boost_sim(0.4, 'switching', 'open', prm, struct('duty', P.D));
prm.iL0 = r0.x_end(1);  prm.v0 = r0.x_end(2);
nper = round(1/(P.fsw*P.Ts));
H = zeros(size(w));
for k = 1:numel(w)
    Tp = 2*pi/w(k);
    nset = max(1, ceil(0.15/Tp));
    nmeas = max(4 - (w(k) < 100), ceil(0.02/Tp));
    r = boost_sim((nset + nmeas)*Tp, 'switching', 'open', prm, ...
                  struct('duty', @(t) P.D + amp*sin(w(k)*t)));
    t = r.t + 0.5*P.Ts;
    v = per_period(r.v_avg, nper);  d = per_period(r.d, nper);
    m = t >= nset*Tp;
    ex = exp(-1i*w(k)*t(m));
    H(k) = sum((v(m) - mean(v(m))) .* ex) / sum((d(m) - mean(d(m))) .* ex);
    fprintf('  w = %8.1f rad/s  |H| = %6.2f dB\n', w(k), 20*log10(abs(H(k))));
end
end

function xs = per_period(x, nper)
n = floor(numel(x)/nper)*nper;
xm = mean(reshape(x(1:n), nper, []), 1);
xs = repelem(xm(:), nper);
xs = [xs; xs(end)*ones(numel(x) - n, 1)];
end

function H = frf(num, den, w)
H = polyval(num, 1i*w) ./ polyval(den, 1i*w);
end

function y = mag_db(H)
y = 20*log10(abs(H));
end

function p = ph(H)
p = unwrap(angle(H))*180/pi;
p = p - 360*round(p(1)/360);
end
