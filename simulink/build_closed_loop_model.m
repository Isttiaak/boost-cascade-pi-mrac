function mdl = build_closed_loop_model(ctrl, plant, outdir)
%BUILD_CLOSED_LOOP_MODEL  One closed-loop model of the paper, built with the Simulink API.
%   mdl = build_closed_loop_model(ctrl, plant, outdir) creates
%   <outdir>/boost_<ctrl>_<plant>.slx
%
%   ctrl  : 'single_pi' | 'cascade_pi' | 'cascade_pi_mrac' | 'cascade_pi_mrac_mf'
%   plant : 'sps'     circuit with Specialized Power Systems blocks
%           'diffeq'  differential-equation model of Fig. 6 (Simulink only)
%           'average' state-space averaged model (Simulink only, no PWM)
%
%   Top level (left to right): V_ref / V_in / load profiles -> Controller
%   (discrete, Ts = 1/(10 fsw)) -> duty-cycle limiter -> PWM modulator ->
%   plant -> v_out, i_L fed back to the controller. To Workspace blocks log
%   v, iL, d, theta, ym, iref and vref every Ts as timeseries.
%   All parameters come from the base-workspace struct BM (boost_mrac_params).
mdl = sprintf('boost_%s_%s', ctrl, plant);
titles = struct('single_pi', 'single PI (Fig. 8, Eq. 33)', ...
    'cascade_pi', 'cascade PI (Fig. 9, Eqs. 42-43)', ...
    'cascade_pi_mrac', 'cascade PI-based MRAC (Figs. 10, 12, 19; Eqs. 44, 54-56)', ...
    'cascade_pi_mrac_mf', ['cascade PI-based MRAC, outer loop tracks the ' ...
    'reference-model output (model-following variant)']);
plants = struct('sps', 'circuit model (Specialized Power Systems)', ...
    'diffeq', 'differential-equation model (Fig. 6)', ...
    'average', 'state-space averaged model (Eqs. 3-9)');
descr = sprintf(['DC-DC boost converter, %s, %s. Recreation of Yanarates & Zhou, ' ...
    'IEEE Access 10 (2022) 44909. Parameters: struct BM from boost_mrac_params.m.'], ...
    titles.(ctrl), plants.(plant));
file = new_model(mdl, outdir, descr);

% ---- sources -------------------------------------------------------------
add_profile(mdl, 'V_ref profile', 'BM.vref', 'BM.t_vref', [30 47 110 83]);
add_profile(mdl, 'V_in profile', 'BM.vin', 'BM.t_vin', [520 237 600 273]);
if strcmp(plant, 'sps')
    add_profile(mdl, 'load switch A', 'BM.g_a', 'BM.t_rload', [520 307 600 343]);
    add_profile(mdl, 'load switch B', 'BM.g_b', 'BM.t_rload', [520 377 600 413]);
else
    add_profile(mdl, 'R_load profile', 'BM.rload', 'BM.t_rload', [520 307 600 343]);
end

% ---- controller, limiter, modulator ---------------------------------------
add_controller(mdl, 'Controller', ctrl, [200 30 340 170]);
sl_add(mdl, 'simulink/Discontinuities/Saturation', 'duty cycle limiter', ...
    [400 45 440 75], 'UpperLimit', 'BM.dmax', 'LowerLimit', 'BM.dmin');
sl_line(mdl, 'V_ref profile/1', 'Controller/1', 'V_ref');
sl_line(mdl, 'Controller/1', 'duty cycle limiter/1', 'u');

switch plant
    case 'sps'
        add_pwm(mdl, 'PWM modulator', [500 40 580 80]);
        add_plant_sps(mdl, 'Boost converter (circuit)', [680 30 820 220]);
        plantBlk = 'Boost converter (circuit)';
        sl_line(mdl, 'duty cycle limiter/1', 'PWM modulator/1', 'd');
        sl_line(mdl, 'PWM modulator/1', [plantBlk '/1'], 'gate');
        sl_line(mdl, 'V_in profile/1', [plantBlk '/2'], 'V_in');
        sl_line(mdl, 'load switch A/1', [plantBlk '/3'], 'g_A');
        sl_line(mdl, 'load switch B/1', [plantBlk '/4'], 'g_B');
        sl_add(mdl, 'sps_lib/powergui', 'powergui', [30 330 110 370]);
        sl_setp([mdl '/powergui'], 'SimulationMode', 'Continuous');
    case 'diffeq'
        add_pwm(mdl, 'PWM modulator', [500 40 580 80]);
        add_plant_diffeq(mdl, 'Boost converter (Fig. 6 equations)', [680 30 820 220]);
        plantBlk = 'Boost converter (Fig. 6 equations)';
        sl_line(mdl, 'duty cycle limiter/1', 'PWM modulator/1', 'd');
        sl_line(mdl, 'PWM modulator/1', [plantBlk '/1'], 'gate');
        sl_line(mdl, 'V_in profile/1', [plantBlk '/2'], 'V_in');
        sl_line(mdl, 'R_load profile/1', [plantBlk '/3'], 'R_load');
    case 'average'
        add_plant_average(mdl, 'Boost converter (averaged)', [680 30 820 220]);
        plantBlk = 'Boost converter (averaged)';
        sl_line(mdl, 'duty cycle limiter/1', [plantBlk '/1'], 'd');
        sl_line(mdl, 'V_in profile/1', [plantBlk '/2'], 'V_in');
        sl_line(mdl, 'R_load profile/1', [plantBlk '/3'], 'R_load');
    otherwise
        error('build_closed_loop_model:plant', 'Unknown plant %s', plant);
end

% ---- feedback ----------------------------------------------------------------
sl_line(mdl, [plantBlk '/1'], 'Controller/2', 'v_out');
sl_line(mdl, [plantBlk '/2'], 'Controller/3', 'i_L');

% ---- logging (every Ts, like the A-D sampling of the controller) -------------
logs = {'v', [plantBlk '/1']; 'iL', [plantBlk '/2']; 'd', 'duty cycle limiter/1'; ...
    'theta', 'Controller/2'; 'ym', 'Controller/3'; 'iref', 'Controller/4'; ...
    'vref', 'V_ref profile/1'};
for k = 1:size(logs, 1)
    y = 30 + 50 * (k - 1);
    blk = ['log ' logs{k, 1}];
    sl_add(mdl, 'simulink/Sinks/To Workspace', blk, [960 y 1040 y + 26], ...
        'VariableName', logs{k, 1}, 'MaxDataPoints', 'inf', ...
        'SaveFormat', 'Timeseries', 'SampleTime', 'BM.Ts');
    sl_line(mdl, logs{k, 2}, [blk '/1']);
end
sl_add(mdl, 'simulink/Sinks/Scope', 'Scope v_out and i_L', [960 400 1000 450], ...
    'NumInputPorts', '2');
sl_line(mdl, [plantBlk '/1'], 'Scope v_out and i_L/1');
sl_line(mdl, [plantBlk '/2'], 'Scope v_out and i_L/2');

finish_model(mdl, file, sprintf(['Yanarates & Zhou (2022) recreation: %s with the ' ...
    '%s. All parameters: struct BM (boost_mrac_params.m).'], titles.(ctrl), plants.(plant)), ...
    [30 480 900 500]);
end
