function path = add_plant_diffeq(sys, name, pos, iLminExpr)
%ADD_PLANT_DIFFEQ  Differential-equation model of the converter, Fig. 6.
%   ON  (gate = 1): L diL/dt = V_in,           i_D = 0
%   OFF (gate = 0): L diL/dt = V_in - v_out,   i_D = i_L
%   C dv/dt = i_D - v_out/R_load
%   The switch block selects the inductor voltage, "NOT" gives (1 - gate).
%   The inductor-current integrator is limited below by iLminExpr
%   (default 'BM.iL_min' = 0: the diode blocks reverse current, so the model
%   enters discontinuous conduction like the circuit; '-Inf' = Fig. 6 as drawn).
%   Inputs : 1 gate, 2 V_in, 3 R_load      Outputs: 1 v_out, 2 i_L
if nargin < 4
    iLminExpr = 'BM.iL_min';
end
path = [sys '/' name];
add_block('built-in/Subsystem', path, 'Position', pos);
sl_add(path, 'built-in/Inport', 'gate', [20 58 50 72], 'Port', '1');
sl_add(path, 'built-in/Inport', 'V_in', [20 128 50 142], 'Port', '2');
sl_add(path, 'built-in/Inport', 'R_load', [20 318 50 332], 'Port', '3');
sl_add(path, 'built-in/Outport', 'v_out', [960 128 990 142], 'Port', '1');
sl_add(path, 'built-in/Outport', 'i_L', [960 48 990 62], 'Port', '2');

sl_add(path, 'simulink/Math Operations/Sum', 'Vdc - Vout', [110 175 130 195], ...
    'Inputs', '+-', 'IconShape', 'round');
sl_add(path, 'simulink/Signal Routing/Switch', 'switch between states', [180 40 230 160], ...
    'Criteria', 'u2 > Threshold', 'Threshold', '0');
sl_add(path, 'simulink/Math Operations/Gain', 'inv L', [280 85 320 115], 'Gain', '1/BM.L');
sl_add(path, 'simulink/Continuous/Integrator', 'i_L integrator', [370 85 400 115], ...
    'InitialCondition', 'BM.iL0', 'LimitOutput', 'on', ...
    'UpperSaturationLimit', 'inf', 'LowerSaturationLimit', iLminExpr);
sl_add(path, 'simulink/Sources/Constant', 'one', [180 235 210 255], 'Value', '1');
sl_add(path, 'simulink/Math Operations/Sum', 'NOT', [260 230 280 250], ...
    'Inputs', '+-', 'IconShape', 'round');
sl_add(path, 'simulink/Math Operations/Product', 'i_D', [460 90 490 120], 'Inputs', '**');
sl_add(path, 'simulink/Math Operations/Sum', 'i_C', [540 95 560 115], ...
    'Inputs', '+-', 'IconShape', 'round');
sl_add(path, 'simulink/Continuous/Integrator', 'charge integrator', [610 90 640 120], ...
    'InitialCondition', 'BM.C*BM.v0');
sl_add(path, 'simulink/Math Operations/Gain', 'inv C_out', [690 90 730 120], ...
    'Gain', '1/BM.C');
sl_add(path, 'simulink/Math Operations/Product', 'i_out = v_out div R', [600 200 630 230], ...
    'Inputs', '*/');

sl_line(path, 'V_in/1', 'switch between states/1');
sl_line(path, 'gate/1', 'switch between states/2');
sl_line(path, 'Vdc - Vout/1', 'switch between states/3');
sl_line(path, 'V_in/1', 'Vdc - Vout/1');
sl_line(path, 'switch between states/1', 'inv L/1', 'v_L');
sl_line(path, 'inv L/1', 'i_L integrator/1', 'diL_dt');
sl_line(path, 'i_L integrator/1', 'i_D/1', 'i_L');
sl_line(path, 'one/1', 'NOT/1');
sl_line(path, 'gate/1', 'NOT/2');
sl_line(path, 'NOT/1', 'i_D/2');
sl_line(path, 'i_D/1', 'i_C/1', 'i_D');
sl_line(path, 'i_out = v_out div R/1', 'i_C/2', 'i_out');
sl_line(path, 'i_C/1', 'charge integrator/1', 'i_C');
sl_line(path, 'charge integrator/1', 'inv C_out/1');
sl_line(path, 'inv C_out/1', 'v_out/1', 'v_out');
sl_line(path, 'inv C_out/1', 'Vdc - Vout/2');
sl_line(path, 'inv C_out/1', 'i_out = v_out div R/1');
sl_line(path, 'R_load/1', 'i_out = v_out div R/2');
sl_line(path, 'i_L integrator/1', 'i_L/1');
end
