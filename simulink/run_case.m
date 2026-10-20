function r = run_case(mdl, s, varargin)
%RUN_CASE  Simulate one scenario (see scenario_list) on a built model.
%   r = run_case(mdl, s, 'Field', value, ...) sets BM from the scenario plus
%   any extra overrides (e.g. 'Ron_sw', 0.1), simulates for s.T and returns
%   column vectors sampled every Ts: t, v, iL, d, theta, ym, iref, vref
%   (first N = round(T/Ts) samples, t = 0 .. T-Ts), plus wall time r.wall.
bm = boost_mrac_params('vref', s.vref, 't_vref', s.t_vref, 'vin', s.vin, ...
    't_vin', s.t_vin, 'rload', s.rload, 't_rload', s.t_rload, 'gamma', s.gamma, ...
    'duty_ol', s.duty, 'iL_min', s.iL_min, varargin{:});
if ~bdIsLoaded(mdl)
    load_system(mdl);
end
tic;
out = sim(mdl, 'StopTime', sprintf('%.12g', s.T));
r.wall = toc;
N = round(s.T / bm.Ts);
r.t = (0:N - 1).' * bm.Ts;
names = {'v', 'iL', 'd', 'theta', 'ym', 'iref', 'vref'};
for k = 1:numel(names)
    r.(names{k}) = grab(out, names{k}, N, bm.Ts);
end
end

function x = grab(out, name, N, Ts)
ts = out.get(name);
x = squeeze(ts.Data);
t = ts.Time;
assert(numel(x) >= N, 'run_case:short', '%s has %d samples, expected %d', name, numel(x), N);
assert(max(abs(t(1:N) - (0:N - 1).' * Ts)) < Ts / 100, 'run_case:time', ...
    '%s is not sampled every Ts', name);
x = x(1:N);
x = x(:);
end
