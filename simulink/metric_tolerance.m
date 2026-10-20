function [tolAbs, tolRel, gating] = metric_tolerance(scen, metric)
%METRIC_TOLERANCE  Agreement required between two implementations.
%   A metric passes when |test - reference| <= max(tolAbs, tolRel*|reference|).
%   Non-gating metrics are reported but do not fail the check: settling
%   times (a 2 % band makes them jump), limit-cycle amplitudes and every
%   value after the first transient of the single PI, which is linearly
%   unstable on this converter and settles into a limit cycle whose phase
%   depends on tiny numerical details.
gating = true;
switch metric
    case {'theta_t0199', 'theta_t0260', 'theta_t0399', 'theta_t0599'}
        tolAbs = 0.01; tolRel = 0;
    case {'emax_step', 'emin_step'}
        tolAbs = 0.3; tolRel = 0;
    case {'tpeak', 'su_tpeak', 'PeakTime', 'RiseTime'}
        tolAbs = 1e-4; tolRel = 0.10;
    case 'SettlingTime'
        tolAbs = 1e-3; tolRel = 0.25; gating = false;
    case 'Overshoot'
        tolAbs = 1.5; tolRel = 0;
    case {'osc_amp', 'ripple_end'}
        tolAbs = 0.05; tolRel = 0.25; gating = false;
    otherwise   % voltages
        tolAbs = 0.5; tolRel = 0.015;
end
if strcmp(scen, 'lr_g1') && any(strcmp(metric, {'theta_t0599', 'vmin_tail', 'vmax_tail'}))
    gating = false;          % diverging oscillation; checked as a property instead
end
if endsWith(scen, '_pi') && ~any(strcmp(metric, {'su_peak', 'su_tpeak', 'RiseTime'}))
    gating = false;          % single-PI limit cycle
end
end
