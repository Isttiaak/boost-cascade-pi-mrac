function path = add_plant_average(sys, name, pos)
%ADD_PLANT_AVERAGE  Large-signal state-space averaged model, Eqs. 3-9:
%   L diL/dt = V_in - (1 - d) v_out,    C dv/dt = (1 - d) i_L - v_out/R_load
%   (inductor current limited at BM.iL_min, 0 = diode).
%   Inputs : 1 duty, 2 V_in, 3 R_load      Outputs: 1 v_out, 2 i_L
path = [sys '/' name];
add_block('built-in/Subsystem', path, 'Position', pos);
sl_add(path, 'built-in/Inport', 'duty', [20 38 50 52], 'Port', '1');
sl_add(path, 'built-in/Inport', 'V_in', [20 118 50 132], 'Port', '2');
sl_add(path, 'built-in/Inport', 'R_load', [20 288 50 302], 'Port', '3');
sl_add(path, 'built-in/Outport', 'v_out', [900 198 930 212], 'Port', '1');
sl_add(path, 'built-in/Outport', 'i_L', [900 98 930 112], 'Port', '2');

sl_add(path, 'simulink/Sources/Constant', 'one', [20 70 50 90], 'Value', '1');
sl_add(path, 'simulink/Math Operations/Sum', '1 - d', [100 45 120 65], ...
    'Inputs', '+-', 'IconShape', 'round');
sl_add(path, 'simulink/Math Operations/Product', '(1 - d) v_out', [170 140 200 170], ...
    'Inputs', '**');
sl_add(path, 'simulink/Math Operations/Sum', 'v_L', [250 110 270 130], ...
    'Inputs', '+-', 'IconShape', 'round');
sl_add(path, 'simulink/Math Operations/Gain', 'inv L', [310 105 350 135], 'Gain', '1/BM.L');
sl_add(path, 'simulink/Continuous/Integrator', 'i_L integrator', [400 105 430 135], ...
    'InitialCondition', 'BM.iL0', 'LimitOutput', 'on', ...
    'UpperSaturationLimit', 'inf', 'LowerSaturationLimit', 'BM.iL_min');
sl_add(path, 'simulink/Math Operations/Product', '(1 - d) i_L', [490 185 520 215], ...
    'Inputs', '**');
sl_add(path, 'simulink/Math Operations/Product', 'v_out div R', [490 260 520 290], ...
    'Inputs', '*/');
sl_add(path, 'simulink/Math Operations/Sum', 'i_C', [570 195 590 215], ...
    'Inputs', '+-', 'IconShape', 'round');
sl_add(path, 'simulink/Math Operations/Gain', 'inv C_out', [630 190 670 220], ...
    'Gain', '1/BM.C');
sl_add(path, 'simulink/Continuous/Integrator', 'v_out integrator', [720 190 750 220], ...
    'InitialCondition', 'BM.v0');

sl_line(path, 'one/1', '1 - d/1');
sl_line(path, 'duty/1', '1 - d/2');
sl_line(path, '1 - d/1', '(1 - d) v_out/1');
sl_line(path, 'v_out integrator/1', '(1 - d) v_out/2');
sl_line(path, 'V_in/1', 'v_L/1');
sl_line(path, '(1 - d) v_out/1', 'v_L/2');
sl_line(path, 'v_L/1', 'inv L/1');
sl_line(path, 'inv L/1', 'i_L integrator/1');
sl_line(path, '1 - d/1', '(1 - d) i_L/1');
sl_line(path, 'i_L integrator/1', '(1 - d) i_L/2');
sl_line(path, 'v_out integrator/1', 'v_out div R/1');
sl_line(path, 'R_load/1', 'v_out div R/2');
sl_line(path, '(1 - d) i_L/1', 'i_C/1');
sl_line(path, 'v_out div R/1', 'i_C/2');
sl_line(path, 'i_C/1', 'inv C_out/1');
sl_line(path, 'inv C_out/1', 'v_out integrator/1');
sl_line(path, 'v_out integrator/1', 'v_out/1', 'v_out');
sl_line(path, 'i_L integrator/1', 'i_L/1', 'i_L');
end
