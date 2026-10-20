function res = run_frestimate_study(plant, outdir, varargin)
%RUN_FRESTIMATE_STUDY  Section II-A with Simulink Control Design (Fig. 1, Eq. 2).
%   res = run_frestimate_study('sps', outdir) estimates the duty-to-output
%   frequency response of the switching converter with frestimate and a
%   sinestream at D = 0.5: the paper's amplitude 0.03 and a small-signal
%   0.0005, from 10 rad/s to f_sw/10 plus five points around the LC
%   resonance. Each response is fitted with 1 zero and 2 poles (the structure
%   of Eq. 2) and compared with Eq. 2 and with Eq. 31.
%   Writes frestimate_points.csv, frestimate_fits.csv and a Bode figure.
%   Needs Simulink Control Design (and the Control System Toolbox).
root = setup_paths();
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
assert(license('test', 'Simulink_Control_Design') && ~isempty(which('frestimate')), ...
    'run_frestimate_study:product', 'Simulink Control Design is not available.');
modeldir = fullfile(root, 'models');
mdl = sprintf('boost_frest_%s', plant);
if ~exist(fullfile(modeldir, [mdl '.slx']), 'file')
    build_frest_model(plant, modeldir);
end
addpath(modeldir);
P = paper_values();
bm = boost_mrac_params('iL0', 5, 'v0', 40, 'duty_ol', P.D, varargin{:});  % start in steady state
load_system(mdl);
io(1) = linio([mdl '/duty operating point'], 1, 'input');
io(2) = linio([mdl '/Plant'], 1, 'output');

w0 = (1 - bm.D) / sqrt(bm.L * bm.C);
w = sort([logspace(1, log10(2 * pi * bm.fsw / 10), 20), w0 * [0.92 0.97 1 1.03 1.08]]);
nmeas = max(4, ceil(0.02 * w / (2 * pi)));      % >= 4 periods and >= 20 ms
nset = max(1, ceil(0.07 * w / (2 * pi)));       % >= 70 ms to settle (tau = 2RC = 14 ms)
amps = [P.perturb_amp 0.0005];
res = struct('amp', {}, 'w', {}, 'H', {}, 'num', {}, 'den', {}, 'fit', {}, 'wall', {});
for a = amps
    % NumPeriods counts the settling periods too
    in = frest.Sinestream('Frequency', w, 'Amplitude', a, 'SamplesPerPeriod', 40, ...
        'RampPeriods', 0, 'NumPeriods', nset + nmeas, 'SettlingPeriods', nset, ...
        'FreqUnits', 'rad/s');
    fprintf('frestimate %s, amplitude %g, %d frequencies ...\n', mdl, a, numel(w));
    tic;
    sysest = frestimate(mdl, io, in);
    wall = toc;
    H = squeeze(sysest.ResponseData);
    H = H(:);
    [num, den, fit] = fit_tf_1z2p(w(:), H);
    fprintf('  %.0f s: fit %.1f %%  num %s  den %s\n', wall, fit, mat2str(num, 5), mat2str(den, 5));
    res(end + 1) = struct('amp', a, 'w', w(:), 'H', H, 'num', num, 'den', den, ...
        'fit', fit, 'wall', wall); %#ok<AGROW>
end
close_system(mdl, 0);
write_points(fullfile(outdir, 'frestimate_points.csv'), res);
write_fits(fullfile(outdir, 'frestimate_fits.csv'), res, P);
plot_bode(fullfile(outdir, 'figures'), res, P, plant);
end

% -------------------------------------------------------------------------
function write_points(file, res)
fid = fopen(file, 'w');
fprintf(fid, 'amplitude,w_rad_s,mag_dB,phase_deg\n');
for r = res
    ph = phase_deg(r.H);
    for i = 1:numel(r.w)
        fprintf(fid, '%g,%.6g,%.6g,%.6g\n', r.amp, r.w(i), 20 * log10(abs(r.H(i))), ph(i));
    end
end
fclose(fid);
end

function write_fits(file, res, P)
fid = fopen(file, 'w');
fprintf(fid, 'source,b1,b0,a1,a0,dc_gain,zero_rad_s,pole1,pole2,wn,zeta,fit_pct\n');
rows = {'Paper Eq. 2', P.eq2_num, P.eq2_den, NaN};
num31 = [-P.L * P.Vdc, P.R * P.Vdc * (1 - P.D)^2];
den31 = [P.L * P.R * P.C * (1 - P.D)^2, P.L * (1 - P.D)^2, P.R * (1 - P.D)^4];
rows(end + 1, :) = {'Eq. 31 (Table 3 values)', num31 / den31(1), den31 / den31(1), NaN};
for r = res
    rows(end + 1, :) = {sprintf('frestimate amplitude %g', r.amp), r.num, r.den, r.fit}; %#ok<AGROW>
end
for i = 1:size(rows, 1)
    n = rows{i, 2}; d = rows{i, 3};
    n = n / d(1); d = d / d(1);
    p = roots(d);
    wn = sqrt(d(3));
    fprintf(fid, '%s,%.6g,%.6g,%.6g,%.6g,%.6g,%.6g,%s,%s,%.6g,%.4g,%.4g\n', rows{i, 1}, ...
        n(1), n(2), d(2), d(3), n(2) / d(3), -n(2) / n(1), cstr(p(1)), cstr(p(2)), ...
        wn, d(2) / (2 * wn), rows{i, 4});
end
fclose(fid);
end

function s = cstr(z)
s = sprintf('%.6g%+.6gj', real(z), imag(z));
end

function ph = phase_deg(H)
ph = unwrap(angle(H)) * 180 / pi;
ph = ph - 360 * round(ph(1) / 360);
end

function plot_bode(figdir, res, P, plant)
if ~exist(figdir, 'dir')
    mkdir(figdir);
end
h = @(s) sscanf(s(2:end), '%2x%2x%2x', [1 3]) / 255;
cpt = h('#2a78d6'); cfit = h('#eb6834'); c31 = h('#1baf7a'); ink = h('#52514e');
wd = logspace(1, 6, 600).';
num31 = [-P.L * P.Vdc, P.R * P.Vdc * (1 - P.D)^2];
den31 = [P.L * P.R * P.C * (1 - P.D)^2, P.L * (1 - P.D)^2, P.R * (1 - P.D)^4];
fr = @(n, d) polyval(n, 1i * wd) ./ polyval(d, 1i * wd);
f = figure('Visible', 'off', 'Color', 'w', 'Position', [100 100 1150 650]);
for c = 1:numel(res)
    r = res(c);
    subplot(2, numel(res), c); hold on; grid on; box on;
    semilogx(wd, 20 * log10(abs(fr(P.eq2_num, P.eq2_den))), '--', 'Color', ink);
    semilogx(wd, 20 * log10(abs(fr(num31, den31))), 'Color', c31);
    semilogx(wd, 20 * log10(abs(fr(r.num, r.den))), 'Color', cfit, 'LineWidth', 1.4);
    semilogx(r.w, 20 * log10(abs(r.H)), 'o', 'Color', cpt, 'MarkerFaceColor', cpt, 'MarkerSize', 4);
    set(gca, 'XScale', 'log'); ylim([-10 75]); ylabel('Magnitude (dB)');
    title(sprintf('frestimate, amplitude %g (fit %.0f %%)', r.amp, r.fit));
    if c == 1
        legend({'Paper Eq. 2', 'Eq. 31 (Table 3)', 'Fitted 1 zero / 2 poles', ...
            'frestimate points'}, 'Location', 'southwest');
    end
    subplot(2, numel(res), c + numel(res)); hold on; grid on; box on;
    semilogx(wd, phase_deg(fr(P.eq2_num, P.eq2_den)), '--', 'Color', ink);
    semilogx(wd, phase_deg(fr(num31, den31)), 'Color', c31);
    semilogx(wd, phase_deg(fr(r.num, r.den)), 'Color', cfit, 'LineWidth', 1.4);
    semilogx(r.w, phase_deg(r.H), 'o', 'Color', cpt, 'MarkerFaceColor', cpt, 'MarkerSize', 4);
    set(gca, 'XScale', 'log'); ylim([-280 20]); yticks([-270 -180 -90 0]);
    ylabel('Phase (deg)'); xlabel('Frequency (rad/s)');
end
sgtitle(sprintf(['Fig. 1 with Simulink Control Design frestimate (%s plant): ' ...
    'duty-to-output response at D = 0.5'], upper(plant)));
file = fullfile(figdir, 'fig01_frestimate.png');
try
    exportgraphics(f, file, 'Resolution', 150);
catch
    print(f, file, '-dpng', '-r150');
end
close(f);
fprintf('  figure %s\n', file);
end
