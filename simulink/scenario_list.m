function S = scenario_list()
%SCENARIO_LIST  Test scenarios shared by every implementation of the recreation.
%   Run by matlab/boost_sim.m (EXPORT_REFERENCE) and by the Simulink models
%   (RUN_SIMULINK_STUDY), and scored by SCENARIO_METRICS. Fields:
%   name, ctrl ('open' | 'pi' | 'cascade' | 'mrac' | 'mrac_mf'), T [s],
%   gamma, vref/t_vref, vin/t_vin, rload/t_rload (value triples with two
%   switching times), duty (open loop), iL_min (diode limit, -Inf = none).
never = [1e3 2e3];
base = struct('name', '', 'ctrl', '', 'T', 0, 'gamma', 0.04, ...
    'vref', [40 40 40], 't_vref', never, 'vin', [20 20 20], 't_vin', never, ...
    'rload', [16 16 16], 't_rload', never, 'duty', 0.5, 'iL_min', 0);
S = base([]);
% Fig. 7: open loop, D = 0.5, cold start
S(end + 1) = mk(base, 'name', 'ol_diode', 'ctrl', 'open', 'T', 0.05);
S(end + 1) = mk(base, 'name', 'ol_bidir', 'ctrl', 'open', 'T', 0.05, 'iL_min', -Inf);
% Figs. 13-15: learning rates
for g = [0.1 0.5 1]
    S(end + 1) = mk(base, 'name', sprintf('lr_g%g', g), 'ctrl', 'mrac', 'T', 0.6, ...
        'gamma', g, 'vref', [30 40 50], 't_vref', [0.2 0.4]); %#ok<AGROW>
end
for c = {'pi', 'cascade', 'mrac', 'mrac_mf'}
    % Fig. 16: load 16 -> 10 -> 20 Ohm
    S(end + 1) = mk(base, 'name', ['f16_' c{1}], 'ctrl', c{1}, 'T', 0.5, ...
        'rload', [16 10 20], 't_rload', [0.2 0.4]); %#ok<AGROW>
    % Fig. 17: the same loads and Vin 15 -> 25 V
    S(end + 1) = mk(base, 'name', ['f17_' c{1}], 'ctrl', c{1}, 'T', 0.5, ...
        'rload', [16 10 20], 't_rload', [0.2 0.4], ...
        'vin', [15 25 25], 't_vin', [0.2 1e3]); %#ok<AGROW>
    % Fig. 18 and Table 10: reference 30 -> 40 -> 50 V
    S(end + 1) = mk(base, 'name', ['f18_' c{1}], 'ctrl', c{1}, 'T', 0.5, ...
        'vref', [30 40 50], 't_vref', [0.2 0.4]); %#ok<AGROW>
    % Figs. 22-24 in simulation: reference 25 -> 40 V
    S(end + 1) = mk(base, 'name', ['exp_' c{1}], 'ctrl', c{1}, 'T', 0.2, ...
        'vref', [25 40 40], 't_vref', [0.1 1e3]); %#ok<AGROW>
end
end

function s = mk(base, varargin)
s = base;
for k = 1:2:numel(varargin)
    s.(varargin{k}) = varargin{k + 1};
end
end
