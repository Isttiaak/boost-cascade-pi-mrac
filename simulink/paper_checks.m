function [T, ok] = paper_checks(kind, label, outdir, dataFile)
%PAPER_CHECKS  Check the recreation against the numbers printed in the paper.
%
%   [T, ok] = paper_checks('analysis', 'analysis', outdir)
%       Sections II-IV with the Control System Toolbox: Table 6 recomputed
%       with MATLAB's own stepinfo on the printed Eq. 2 and Eq. 32, Table 8
%       from Eqs. 45-50, the printed transfer functions that disagree with the
%       paper's own formulas, and the stability of the paper's loops.
%   [T, ok] = paper_checks('simulation', label, outdir, metricsFile)
%       one implementation's scenario metrics (SCENARIO_METRICS) against
%       Fig. 7, Figs. 13-16 and Table 10.
%   [T, ok] = paper_checks('frestimate', 'frestimate', outdir, fitsFile)
%       the frequency-response fits of RUN_FRESTIMATE_STUDY against Eq. 2.
%
%   Every check has an expectation:
%     match     the recreation reproduces the paper within the tolerance
%     differs   the printed number contradicts the paper's own model and the
%               recreation confirms the difference (|value - paper| > tol)
%     positive / negative / at_least   property checks
%     info      reported only (figure details the paper does not define)
%   Paper values marked "(fig.)" are read off the paper's figures.
%   Writes <outdir>/paper_checks_<label>.csv and .md; ok = every check other
%   than info passes.
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
switch kind
    case 'analysis'
        rows = analysis_checks();
    case 'simulation'
        rows = simulation_checks(read_metrics(dataFile));
    case 'frestimate'
        rows = frestimate_checks(dataFile);
    otherwise
        error('paper_checks:kind', 'Unknown kind %s', kind);
end
T = cell2table(rows, 'VariableNames', {'id', 'item', 'paper', 'value', 'tol', 'expect', 'note'});
n = height(T);
pass = false(n, 1);
for i = 1:n
    pass(i) = judge(T.expect{i}, T.paper(i), T.value(i), T.tol(i));
end
T.gating = ~strcmp(T.expect, 'info');
T.pass = pass;
ok = all(T.pass(T.gating));
writetable(T, fullfile(outdir, sprintf('paper_checks_%s.csv', label)));
write_markdown(T, label, ok, fullfile(outdir, sprintf('paper_checks_%s.md', label)));
fprintf('paper_checks(%s): %d/%d checks as expected, %d informational\n', label, ...
    sum(T.pass & T.gating), sum(T.gating), sum(~T.gating));
for i = find(T.gating & ~T.pass).'
    fprintf('   NOT AS EXPECTED %-22s paper %.6g  recreated %.6g  (%s, tol %g)\n', ...
        T.id{i}, T.paper(i), T.value(i), T.expect{i}, T.tol(i));
end
end

% =========================================================================
function rows = analysis_checks()
P = paper_values();
rows = {};
% ---- Table 6: stepinfo on the printed transfer functions ------------------
tfs = {P.eq2_num, P.eq2_den, 'eq2', 'Eq. 2'; P.eq32_num, P.eq32_den, 'eq32', 'Eq. 32'};
for i = 1:2
    S = stepinfo(tf(tfs{i, 1}, tfs{i, 2}));
    for j = 1:numel(P.metric_names)
        nm = P.metric_names{j};
        note = '';
        if strcmp(nm, 'SettlingTime') && isfield(S, 'TransientTime')
            % Since R2021b the old SettlingTime definition (error below 2 % of
            % its peak) is reported as TransientTime.
            v = S.TransientTime;
            note = sprintf('stepinfo TransientTime; SettlingTime = %.4g s', S.SettlingTime);
        else
            v = S.(nm);
        end
        switch nm
            case {'RiseTime', 'SettlingTime'}
                tol = 1e-4; expect = 'match';
            case 'PeakTime'
                tol = 5e-4; expect = 'info';
                note = 'end of the step-plot horizon (monotone approach)';
            case 'SettlingMin'
                tol = 0.2; expect = 'match';
            otherwise
                tol = 0.05; expect = 'match';
        end
        rows(end + 1, :) = {sprintf('tab6_%s_%s', tfs{i, 3}, nm), ...
            sprintf('Table 6, %s: %s (stepinfo)', tfs{i, 4}, nm), P.table6(i, j), v, ...
            tol, expect, note}; %#ok<AGROW>
    end
end
% ---- Table 8: reference converter sized with Eqs. 45-50 --------------------
Rmin = P.ref_Rmin; Dr = P.ref_D; Vdc = P.Vdc; Vout = P.Vout; fsw = P.fsw;
ILmax = Vout^2 / (Rmin * Vdc);
dIL = 0.2 * ILmax;
Lr = Vdc * Dr / (fsw * dIL);
dV = 0.04 * Vout;
Cr = Vdc * Dr / (Rmin * fsw * dV * (1 - Dr));
rows = [rows;
    {'tab8_ILmax', 'Table 8: I_L,avg,max (A)', 8, ILmax, 1e-9, 'match', 'Eq. 46'};
    {'tab8_dIL', 'Table 8: inductor ripple (A)', 1.6, dIL, 1e-9, 'match', 'Eq. 47'};
    {'tab8_L', 'Table 8: L (mH)', 0.3125, Lr * 1e3, 1e-9, 'match', 'Eq. 48'};
    {'tab8_dV', 'Table 8: output ripple (V)', 1.6, dV, 1e-9, 'match', 'Eq. 49'};
    {'tab8_C', 'Table 8: C (uF)', 62.5, Cr * 1e6, 1e-9, 'match', 'Eq. 50'}];
% ---- printed transfer functions vs the paper's own formulas -----------------
D = P.D; L = P.L; C = P.C; R = P.R;
num31 = [-L * Vdc, R * Vdc * (1 - D)^2];
den31 = [L * R * C * (1 - D)^2, L * (1 - D)^2, R * (1 - D)^4];
num39 = [R * C * Vdc, 2 * Vdc];
den39 = [L * R * C * (1 - D), L * (1 - D), R * (1 - D)^3];
num51 = [-P.ref_L * Vdc, Rmin * Vdc * (1 - Dr)^2];
zeta = @(d) d(2) / (2 * sqrt(d(1) * d(3)));
rows = [rows;
    {'eq32_zero', 'Eq. 32 RHP zero (rad/s) vs Eq. 31 with Table 3', ...
     -P.eq32_num(2) / P.eq32_num(1), -num31(2) / num31(1), 50, 'differs', ...
     'only some coefficients of Eq. 31 were divided by 80'};
    {'eq32_zeta', 'Eq. 32 damping ratio vs Eq. 31 with Table 3', ...
     zeta(P.eq32_den), zeta(den31), 0.1, 'differs', 'Eq. 31: LC resonance at 2384 rad/s'};
    {'eq40_dc', 'Eq. 40 DC gain (A per unit duty) vs Eq. 39', ...
     P.eq40_num(end) / P.eq40_den(end), num39(end) / den39(end), 1, 'differs', ''};
    {'eq51_zero', 'Eq. 51 RHP zero (rad/s) vs Eq. 31 with Table 8', ...
     -P.eq51_num(2) / P.eq51_num(1), -num51(2) / num51(1), 50, 'differs', ...
     'printed s-coefficient 10x too large'};
    {'eq2_zero', 'Eq. 2 RHP zero (rad/s) vs Eq. 31 with Table 3', ...
     -P.eq2_num(2) / P.eq2_num(1), -num31(2) / num31(1), 50, 'differs', ...
     'see the frestimate checks'}];
% ---- stability of the paper's loops (largest real part of the poles) -------
maxre = @(ch) max(real(roots(ch)));
pich = @(Kp, Ki, n, d) polyadd(conv([1 0], d), conv([Kp Ki], n));
[~, dref] = pi_unity_feedback(P.eq52.Kp, P.eq52.Ki, P.eq51_num, P.eq51_den);
[~, drefc] = pi_unity_feedback(P.eq52.Kp, P.eq52.Ki, [-0.00625 50], P.eq51_den);
Ks = P.pi_single;
rows = [rows;
    {'ref_printed', 'Reference loop, printed Eq. 51 + Eq. 52: max Re(pole) (rad/s)', ...
     NaN, max(real(roots(dref))), 0, 'positive', 'unstable reference model'};
    {'ref_corrected', 'Reference loop, Eq. 51 from Table 8 + Eq. 52: max Re(pole) (rad/s)', ...
     NaN, max(real(roots(drefc))), 0, 'negative', 'used in the recreation'};
    {'pi_eq2', 'Single PI (Eq. 33) on printed Eq. 2: max Re(pole) (rad/s)', ...
     NaN, maxre(pich(Ks.Kp, Ks.Ki, P.eq2_num, P.eq2_den)), 0, 'negative', ''};
    {'pi_eq32', 'Single PI (Eq. 33) on printed Eq. 32: max Re(pole) (rad/s)', ...
     NaN, maxre(pich(Ks.Kp, Ks.Ki, P.eq32_num, P.eq32_den)), 0, 'negative', ''};
    {'pi_eq31', 'Single PI (Eq. 33) on Eq. 31 (Table 3): max Re(pole) (rad/s)', ...
     NaN, maxre(pich(Ks.Kp, Ks.Ki, num31, den31)), 0, 'positive', ...
     'unstable on the lossless converter'}];
end

function c = polyadd(a, b)
n = max(numel(a), numel(b));
c = [zeros(1, n - numel(a)) a] + [zeros(1, n - numel(b)) b];
end

% =========================================================================
function rows = simulation_checks(M)
P = paper_values();
t10 = @(r, nm) P.table10(r, strcmp(P.metric_names, nm));
g = @(scen, met) get_metric(M, scen, met);
rows = {
    'fig7_peak', 'Fig. 7: circuit model, cold-start peak (V) (fig.)', 76, ...
        g('ol_diode', 'peak'), 1.5, 'match', '';
    'fig7_final', 'Fig. 7: circuit model, mean over 40-50 ms (V) (fig.)', 40, ...
        g('ol_diode', 'vmean_end'), 0.5, 'match', '';
    'fig13_emax_g01', 'Fig. 13: tracking-error peak after 0.2 s, gamma = 0.1 (V) (fig.)', 7, ...
        g('lr_g0.1', 'emax_step'), 1, 'match', '';
    'fig13_emax_g1', 'Fig. 13: tracking-error peak after 0.2 s, gamma = 1 (V) (fig.)', 6, ...
        g('lr_g1', 'emax_step'), 1, 'match', '';
    'fig14_th_g01_a', 'Fig. 14: theta before 0.2 s, gamma = 0.1 (fig.)', 0.95, ...
        g('lr_g0.1', 'theta_t0199'), 0.1, 'match', '';
    'fig14_th_g05_a', 'Fig. 14: theta before 0.2 s, gamma = 0.5 (fig.)', 0.755, ...
        g('lr_g0.5', 'theta_t0199'), 0.1, 'match', '';
    'fig14_th_g1_a', 'Fig. 14: theta before 0.2 s, gamma = 1 (fig.)', 0.505, ...
        g('lr_g1', 'theta_t0199'), 0.1, 'match', '';
    'fig14_th_g01_b', 'Fig. 14: theta at 0.26 s, gamma = 0.1 (fig.)', 0.90, ...
        g('lr_g0.1', 'theta_t0260'), 0.1, 'match', '';
    'fig14_th_g05_b', 'Fig. 14: theta at 0.26 s, gamma = 0.5 (fig.)', 0.50, ...
        g('lr_g0.5', 'theta_t0260'), 0.1, 'match', '';
    'fig14_th_g1_b', 'Fig. 14: theta at 0.26 s, gamma = 1 (fig.)', 0.12, ...
        g('lr_g1', 'theta_t0260'), 0.1, 'match', '';
    'fig15_g1_min', 'Fig. 15: gamma = 1 diverges after 0.4 s, minimum over 0.5-0.6 s (V) (fig.)', ...
        33, g('lr_g1', 'vmin_tail'), 3, 'match', '';
    'fig15_g1_max', 'Fig. 15: gamma = 1, maximum over 0.5-0.6 s (V) (fig., axis ends at 70 V)', ...
        68, g('lr_g1', 'vmax_tail'), 0, 'at_least', '';
    'fig15_g05_max', 'Fig. 15: gamma = 0.5 stays regulated near 50 V, maximum over 0.5-0.6 s (V) (fig.)', ...
        50, g('lr_g0.5', 'vmax_tail'), 1, 'match', '';
    'fig16_pi_peak', 'Fig. 16: single PI, start-up peak (V) (fig.)', 52.5, ...
        g('f16_pi', 'su_peak'), 2.5, 'match', '';
    'fig16_pi_min', 'Fig. 16: single PI, start-up dip (V) (fig.)', 28, ...
        g('f16_pi', 'su_min'), 2.5, 'match', '';
    'fig16_cas_peak', 'Fig. 16: cascade PI, start-up peak (V) (fig.)', 46.5, ...
        g('f16_cascade', 'su_peak'), 2, 'match', '';
    'fig16_cas_min', 'Fig. 16: cascade PI, start-up dip (V) (fig.)', 38.5, ...
        g('f16_cascade', 'su_min'), 2, 'match', '';
    'fig16_cas_lsmin', 'Fig. 16: cascade PI, dip after 16 -> 10 Ohm (V) (fig.)', 37.8, ...
        g('f16_cascade', 'ls_min'), 0.5, 'match', '';
    'fig16_cas_lsmax', 'Fig. 16: cascade PI, peak after 16 -> 10 Ohm (V) (fig.)', 40.9, ...
        g('f16_cascade', 'ls_max'), 0.5, 'match', '';
    'fig16_mrac_lsmin', 'Fig. 16: MRAC as written, dip after 16 -> 10 Ohm (V) (fig.)', 38.6, ...
        g('f16_mrac', 'ls_min'), 0.5, 'info', 'paper MRAC dips less than its cascade PI';
    'tab10_cas_peak', 'Table 10: cascade PI, peak (V)', t10(2, 'Peak'), ...
        g('f18_cascade', 'Peak'), 0.5, 'match', '30 -> 40 V step at 0.2 s';
    'tab10_cas_os', 'Table 10: cascade PI, overshoot (% of 40 V)', t10(2, 'Overshoot'), ...
        g('f18_cascade', 'Overshoot'), 1.5, 'match', '';
    'tab10_cas_tpk', 'Table 10: cascade PI, peak time (s)', t10(2, 'PeakTime'), ...
        g('f18_cascade', 'PeakTime'), 5e-4, 'match', '';
    'tab10_cas_rise', 'Table 10: cascade PI, rise time (s)', t10(2, 'RiseTime'), ...
        g('f18_cascade', 'RiseTime'), 3e-4, 'info', '';
    'tab10_cas_settle', 'Table 10: cascade PI, settling time (s)', t10(2, 'SettlingTime'), ...
        g('f18_cascade', 'SettlingTime'), 2e-3, 'info', 'definition not stated';
    'tab10_mrac_peak', 'Table 10: MRAC peak (V) vs MRAC as written (Eqs. 54-56)', ...
        t10(3, 'Peak'), g('f18_mrac', 'Peak'), 0.5, 'differs', ...
        'as written it behaves like the cascade PI';
    'tab10_mf_peak', 'Table 10: MRAC peak (V) vs model-following set-point', ...
        t10(3, 'Peak'), g('f18_mrac_mf', 'Peak'), 0.5, 'match', '';
    'tab10_mf_os', 'Table 10: MRAC overshoot (% of 40 V) vs model-following set-point', ...
        t10(3, 'Overshoot'), g('f18_mrac_mf', 'Overshoot'), 1.5, 'match', '';
    'tab10_pi_peak', 'Table 10: single PI, peak (V)', t10(1, 'Peak'), ...
        g('f18_pi', 'Peak'), 0.5, 'info', 'limit cycle with lossless devices'};
end

function v = get_metric(M, scen, met)
key = [scen '|' met];
if isKey(M, key)
    v = M(key);
else
    v = NaN;
end
end

% =========================================================================
function rows = frestimate_checks(fitsFile)
P = paper_values();
F = readtable(fitsFile, 'TextType', 'char', 'Delimiter', ',');
pick = @(src, col) first_or_nan(F.(col)(strcmp(F.source, src)));
src03 = sprintf('frestimate amplitude %g', P.perturb_amp);
srcSS = 'frestimate amplitude 0.0005';
eq2zero = -P.eq2_num(2) / P.eq2_num(1);
eq2zeta = P.eq2_den(2) / (2 * sqrt(P.eq2_den(3)));
num31 = [-P.L * P.Vdc, P.R * P.Vdc * (1 - P.D)^2];
den31 = [P.L * P.R * P.C * (1 - P.D)^2, P.L * (1 - P.D)^2, P.R * (1 - P.D)^4];
rows = {
    'fr03_zero', 'Eq. 2 RHP zero (rad/s) vs frestimate, amplitude 0.03', eq2zero, ...
        pick(src03, 'zero_rad_s'), 0.5 * eq2zero, 'differs', 'paper procedure';
    'fr03_zeta', 'Eq. 2 damping ratio vs frestimate, amplitude 0.03', eq2zeta, ...
        pick(src03, 'zeta'), 0.5, 'differs', 'converter enters DCM near resonance';
    'fr03_dc', 'Eq. 2 DC gain vs frestimate, amplitude 0.03', ...
        P.eq2_num(2) / P.eq2_den(3), pick(src03, 'dc_gain'), 2, 'info', '';
    'frss_wn', 'Eq. 31 resonance (rad/s) vs frestimate, amplitude 0.0005', ...
        sqrt(den31(3) / den31(1)), pick(srcSS, 'wn'), 50, 'match', ...
        'paper''s own formula, not a printed number';
    'frss_zeta', 'Eq. 31 damping ratio vs frestimate, amplitude 0.0005', ...
        den31(2) / (2 * sqrt(den31(1) * den31(3))), pick(srcSS, 'zeta'), 0.01, 'match', ...
        'paper''s own formula';
    'frss_dc', 'Eq. 31 DC gain vs frestimate, amplitude 0.0005', ...
        num31(2) / den31(3), pick(srcSS, 'dc_gain'), 3, 'match', 'paper''s own formula'};
end

function v = first_or_nan(x)
if isempty(x)
    v = NaN;
else
    v = x(1);
end
end

% =========================================================================
function ok = judge(expect, paper, value, tol)
if isnan(value)
    ok = false;
    return
end
switch expect
    case {'match', 'info'}
        ok = abs(value - paper) <= tol * (1 + 1e-12) + 1e-12;
    case 'differs'
        ok = abs(value - paper) > tol;
    case 'positive'
        ok = value > 0;
    case 'negative'
        ok = value < 0;
    case 'at_least'
        ok = value >= paper;
    otherwise
        error('paper_checks:expect', 'Unknown expectation %s', expect);
end
end

function M = read_metrics(file)
fid = fopen(file, 'r');
assert(fid > 0, 'paper_checks:file', 'Cannot open %s', file);
c = textscan(fid, '%s %s %s', 'Delimiter', ',', 'HeaderLines', 1);
fclose(fid);
M = containers.Map();
for i = 1:numel(c{1})
    M([c{1}{i} '|' c{2}{i}]) = str2double(c{3}{i});
end
end

function write_markdown(T, label, ok, file)
fid = fopen(file, 'w');
status = 'all as expected';
if ~ok
    status = 'SOME NOT AS EXPECTED';
end
fprintf(fid, '## Paper checks (%s): %s\n\n', label, status);
fprintf(fid, '| Check | Paper | Recreated | Tolerance | Expected | Result | Note |\n');
fprintf(fid, '|---|---|---|---|---|---|---|\n');
for i = 1:height(T)
    fprintf(fid, '| %s | %s | %s | %g | %s | %s | %s |\n', T.item{i}, num(T.paper(i)), ...
        num(T.value(i)), T.tol(i), T.expect{i}, verdict(T.expect{i}, T.pass(i)), T.note{i});
end
fclose(fid);
end

function s = num(x)
if isnan(x)
    s = '-';
else
    s = sprintf('%.5g', x);
end
end

function s = verdict(expect, pass)
if strcmp(expect, 'info')
    if pass
        s = 'close';
    else
        s = 'differs';
    end
elseif pass
    s = 'as expected';
else
    s = '**NOT AS EXPECTED**';
end
end
