function m = scenario_metrics(name, t, v, iL, theta, ym, Ts) %#ok<INUSL>
%SCENARIO_METRICS  Metrics of one scenario run; twin of python/scenarios.py.
%   m = scenario_metrics(name, t, v, iL, theta, ym) with column vectors sampled
%   at t_k = k*Ts, k = 0..N-1. A window [t0, t1) is samples round(t0/Ts) ..
%   round(t1/Ts)-1 (0-based), i.e. MATLAB indices round(t0/Ts)+1 : round(t1/Ts).
if nargin < 7
    Ts = 5e-6;
end
kind = strtok(name, '_');
t = t(:);
v = v(:);
m = struct();
switch kind
    case 'ol'
        w = win(0, 0.05, Ts);
        [m.peak, k] = max(v(w));
        m.tpeak = t(w(k));
        e = win(0.04, 0.05, Ts);
        m.vmean_end = mean(v(e));
        m.ripple_end = 0.5 * (max(v(e)) - min(v(e)));
    case 'lr'
        for tq = [0.199 0.399 0.599]
            m.(sprintf('theta_t%04d', round(tq * 1000))) = theta(round(tq / Ts) + 1);
        end
        tail = win(0.5, 0.6, Ts);
        m.vmin_tail = min(v(tail));
        m.vmax_tail = max(v(tail));
        s = win(0.2, 0.215, Ts);
        e = v(s) - ym(s);
        m.emax_step = max(e);
        m.emin_step = min(e);
    case {'f16', 'f17'}
        w = win(0, 0.03, Ts);
        [m.su_peak, k] = max(v(w));
        m.su_tpeak = t(w(k));
        k50 = round(0.05 / Ts);
        m.su_min = min(v(w(k):k50));
        if strcmp(kind, 'f16')
            s = win(0.2, 0.215, Ts);
            m.ls_min = min(v(s));
            m.ls_max = max(v(s));
            o = win(0.15, 0.2, Ts);
        else
            s = win(0.2, 0.25, Ts);
            m.vs_min = min(v(s));
            m.vs_max = max(v(s));
            o = win(0.45, 0.5, Ts);
        end
        m.osc_amp = 0.5 * (max(v(o)) - min(v(o)));
    case 'f18'
        s = win(0.2, 0.4, Ts);
        S = step_metrics(t(s) - 0.2, v(s), 40, 0);          % Table 10 definitions
        for key = {'RiseTime', 'SettlingTime', 'SettlingMin', 'SettlingMax', ...
                'Overshoot', 'Peak', 'PeakTime'}
            m.(key{1}) = S.(key{1});
        end
        m.step3_peak = max(v(win(0.4, 0.45, Ts)));
    case 'exp'
        s = win(0.1, 0.2, Ts);
        S = step_metrics(t(s) - 0.1, v(s), 40, 25, 'final');
        for key = {'RiseTime', 'SettlingTime', 'Overshoot', 'Peak', 'PeakTime'}
            m.(key{1}) = S.(key{1});
        end
    otherwise
        error('scenario_metrics:name', 'Unknown scenario %s', name);
end
end

function idx = win(t0, t1, Ts)
idx = (round(t0 / Ts) + 1):round(t1 / Ts);
end
