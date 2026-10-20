function file = export_reference(outdir)
%EXPORT_REFERENCE  Reference results of the plain-MATLAB simulator.
%   file = export_reference(outdir) runs every scenario of SCENARIO_LIST with
%   matlab/boost_sim.m (switching converter, ideal devices, fixed-step RK4 with
%   the PWM edges placed exactly inside each 5 us control interval) and writes
%
%     <outdir>/metrics_reference.csv            scenario, metric, value
%     <outdir>/traces_reference/<scenario>.csv  t, v, iL, theta, ym every 50 us
%
%   The Simulink models (block diagrams solved by a variable-step solver with
%   zero-crossing detection) are checked against this reference by
%   COMPARE_METRICS; the traces are overlaid on their figures.
setup_paths();
traceDir = fullfile(outdir, 'traces_reference');
if ~exist(traceDir, 'dir')
    mkdir(traceDir);
end
ctrlMap = struct('open', 'open', 'pi', 'pi', 'cascade', 'cascade', 'mrac', 'mrac', ...
    'mrac_mf', 'mrac_ms');
decim = 10;                         % one trace sample per switching period
S = scenario_list();
file = fullfile(outdir, 'metrics_reference.csv');
fid = fopen(file, 'w');
assert(fid > 0, 'export_reference:file', 'Cannot write %s', file);
fprintf(fid, 'scenario,metric,value\n');
tAll = tic;
for i = 1:numel(S)
    s = S(i);
    prm = boost_params();
    if isinf(s.iL_min)
        prm.unidirectional = 0;        % Fig. 6 as drawn: no diode limit
    end
    Ts = prm.Ts;
    N = round(s.T / Ts);
    opts = struct('vref', prof(s.vref, s.t_vref, N, Ts), 'vin', prof(s.vin, s.t_vin, N, Ts), ...
        'rload', prof(s.rload, s.t_rload, N, Ts), 'duty', s.duty, 'gamma', s.gamma);
    tic;
    r = boost_sim(s.T, 'switching', ctrlMap.(s.ctrl), prm, opts);
    m = scenario_metrics(s.name, r.t, r.v, r.iL, r.theta, r.ym, Ts);
    f = fieldnames(m);
    for j = 1:numel(f)
        fprintf(fid, '%s,%s,%.17g\n', s.name, f{j}, m.(f{j}));
    end
    k = 1:decim:N;
    tr = [r.t(k), r.v(k), r.iL(k), r.theta(k), r.ym(k)].';
    ft = fopen(fullfile(traceDir, [s.name '.csv']), 'w');
    fprintf(ft, 't,v,iL,theta,ym\n');
    fprintf(ft, '%.7g,%.6g,%.6g,%.7g,%.6g\n', tr);
    fclose(ft);
    fprintf('  reference %-14s %5.1f s\n', s.name, toc);
end
fclose(fid);
fprintf('export_reference: %d scenarios in %.1f min -> %s\n', numel(S), toc(tAll) / 60, file);
end

function x = prof(vals, times, N, Ts)
%PROF  Profile sampled every Ts: vals(1), vals(2) from times(1), vals(3) from times(2).
k = (0:N - 1).';
k1 = round(times(1) / Ts);
k2 = round(times(2) / Ts);
x = vals(1) + (vals(2) - vals(1)) * (k >= k1) + (vals(3) - vals(2)) * (k >= k2);
end
