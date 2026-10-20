function file = export_metrics_matlab_scripts(outdir)
%EXPORT_METRICS_MATLAB_SCRIPTS  Run every scenario of scenario_list with the
%   plain-MATLAB simulator matlab/boost_sim.m (switching plant, ideal devices)
%   and write <outdir>/metrics_matlab_scripts.csv for compare_metrics.
setup_paths();
if ~exist(outdir, 'dir')
    mkdir(outdir);
end
ctrlMap = struct('open', 'open', 'pi', 'pi', 'cascade', 'cascade', 'mrac', 'mrac', ...
    'mrac_mf', 'mrac_ms');
S = scenario_list();
file = fullfile(outdir, 'metrics_matlab_scripts.csv');
fid = fopen(file, 'w');
fprintf(fid, 'scenario,metric,value\n');
for i = 1:numel(S)
    s = S(i);
    prm = boost_params();
    if isinf(s.iL_min)
        prm.unidirectional = 0;
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
    fprintf('  %-14s %5.1f s\n', s.name, toc);
end
fclose(fid);
fprintf('  wrote %s\n', file);
end

function x = prof(vals, times, N, Ts)
k = (0:N - 1).';
k1 = round(times(1) / Ts);
k2 = round(times(2) / Ts);
x = vals(1) + (vals(2) - vals(1)) * (k >= k1) + (vals(3) - vals(2)) * (k >= k2);
end
