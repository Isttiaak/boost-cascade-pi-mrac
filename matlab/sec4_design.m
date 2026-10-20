%SEC4_DESIGN  Recreation of Section IV (controller and reference-model design).
%   Tustin discretisation of the controllers (Eq. 53), reference model (Table 8,
%   Eqs. 51-52) and loop analysis of the paper's gains on printed vs correct plants.
clear; close all;
P = paper_values();  S = viz_style();  Ts = P.Ts;

%% controllers
names = {'Single PI, Eq. 33', 'Outer PI, Eq. 42', 'Inner PI, Eq. 43', 'Reference-model PI, Eq. 52'};
gains = {P.pi_single, P.pi_outer, P.pi_inner, P.eq52};
fid = fopen(fullfile(S.tabdir, 'sec4_discretised_controllers.csv'), 'w');
fprintf(fid, 'Controller,Kp,Ki,b0,b1,a0,a1\n');
for k = 1:4
    Cz = c2d(tf([gains{k}.Kp gains{k}.Ki], [1 0]), Ts, 'tustin');
    [b, a] = tfdata(Cz, 'v');
    fprintf(fid, '%s,%g,%g,%.8g,%.8g,%.8g,%.8g\n', names{k}, gains{k}.Kp, gains{k}.Ki, b(1), b(2), a(1), a(2));
    fprintf('%-28s C(z) = (%.8g + %.8g z^-1)/(1 - z^-1)\n', names{k}, b(1), b(2));
end
fclose(fid);

%% reference model
[nT, dT] = ref_model_tf('derived');  [nTp, dTp] = ref_model_tf('printed');
fprintf('reference model poles (derived Eq. 51): %s\n', mat2str(roots(dT).', 5));
fprintf('reference model poles (printed Eq. 51): %s  -> unstable\n', mat2str(roots(dTp).', 5));
t = linspace(0, 0.02, 20001)';
y = step(tf(nT, dT), t);  yp = step(tf(nTp, dTp), t);
Si = step_metrics(t, y, 1, 0);
fprintf('derived reference-model step: rise %.4g s, settling %.4g s, overshoot %.3g %%\n', ...
        Si.RiseTime, Si.SettlingTime, Si.Overshoot);

f = figure('Position', [100 100 1100 380], 'Color', 'w');
subplot(1,2,1); hold on; grid on;
plot(t*1e3, y, 'Color', S.c3, 'LineWidth', 1.5);
plot(t*1e3, yp, '--', 'Color', S.c2);
ylim([-1.5 2.5]); xlabel('Time (ms)'); ylabel('V_{ref(out)} / V_{ref}');
title('(a) Closed-loop reference model, unit step');
legend('Eq. 51 derived from Table 8 (-0.00625 s + 50)', 'Eq. 51 as printed (-0.0625 s + 50)');

%% loop analysis of the single PI
[nv, ni, den] = averaged_linear_tf(boost_params());
plants = {'Printed Eq. 2', P.eq2_num, P.eq2_den; 'Printed Eq. 32', P.eq32_num, P.eq32_den; ...
          'Correct Eq. 31 (lossless)', nv, den};
Cpi = tf([P.pi_single.Kp P.pi_single.Ki], [1 0]);
subplot(1,2,2); hold on; grid on;
wd = logspace(1, 6, 4000);  cols = {S.ink2, S.muted, S.c1};  sty = {'--', ':', '-'};
fid = fopen(fullfile(S.tabdir, 'sec4_loop_analysis.csv'), 'w');
fprintf(fid, 'Controller,Plant,Stable,Gm_dB,Pm_deg\n');
for k = 1:3
    Lk = Cpi * tf(plants{k,2}, plants{k,3});
    [mag, ~] = bode(Lk, wd);
    semilogx(wd, 20*log10(squeeze(mag)), sty{k}, 'Color', cols{k});
    cl = feedback(Lk, 1);  stable = all(real(pole(cl)) < 0);
    [Gm, Pm] = margin(Lk);
    fprintf(fid, 'Single PI,%s,%d,%.2f,%.2f\n', plants{k,1}, stable, 20*log10(Gm), Pm);
    fprintf('single PI on %-28s stable = %d, poles %s\n', plants{k,1}, stable, mat2str(pole(cl).', 5));
end
for r = [0.01 0.02 0.05]
    [nvr, ~, denr] = averaged_linear_tf(boost_params('rL', r));
    cl = feedback(Cpi * tf(nvr, denr), 1);
    fprintf('single PI on Eq. 31 + %2.0f mOhm loss: stable = %d\n', r*1e3, all(real(pole(cl)) < 0));
    fprintf(fid, 'Single PI,Eq. 31 + %g mOhm,%d,,\n', r*1e3, all(real(pole(cl)) < 0));
end
% cascade (continuous time): characteristic polynomial
Ki_ = [P.pi_inner.Kp P.pi_inner.Ki];  Ko_ = [P.pi_outer.Kp P.pi_outer.Ki];
ch = conv([1 0 0], den) + [0 conv(conv([1 0], Ki_), ni)] + [0 conv(conv(Ki_, Ko_), nv)];
fprintf('cascade PI on correct model: poles %s\n', mat2str(roots(ch).', 5));
fprintf(fid, 'Cascade PI,Correct Eqs. 31/39,%d,,\n', all(real(roots(ch)) < 0));
fclose(fid);
yline(0, 'Color', S.ink2);
set(gca, 'XScale', 'log'); ylim([-60 60]); xlabel('Frequency (rad/s)'); ylabel('dB');
title('(b) Single-PI loop gain |C(j\omega)G(j\omega)|');
legend(plants(:,1), 'Location', 'southwest');
print(f, fullfile(S.figdir, 'sec4_reference_model_and_loop_gain'), '-dpng', '-r150');
