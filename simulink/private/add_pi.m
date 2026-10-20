function path = add_pi(sys, name, kpExpr, kiExpr, pos)
%ADD_PI  Discrete PI as drawn in Figs. 8-10: u = Kp e + Ki * Ts z/(z-1) e  (Eq. 54).
%   The integrator is a Discrete-Time Integrator (backward Euler, sample
%   time BM.Ts), which is exactly Ts z/(z-1).
path = [sys '/' name];
add_block('built-in/Subsystem', path, 'Position', pos);
sl_add(path, 'built-in/Inport', 'e', [20 68 50 82], 'Port', '1');
sl_add(path, 'simulink/Math Operations/Gain', 'Kp', [120 20 170 50], 'Gain', kpExpr);
sl_add(path, 'simulink/Math Operations/Gain', 'Ki', [120 100 170 130], 'Gain', kiExpr);
sl_add(path, 'simulink/Discrete/Discrete-Time Integrator', 'integral Ts z over (z-1)', ...
    [210 98 250 132], 'IntegratorMethod', 'Integration: Backward Euler', ...
    'gainval', '1', 'InitialCondition', '0', 'SampleTime', 'BM.Ts');
sl_add(path, 'simulink/Math Operations/Sum', 'sum', [300 60 320 90], ...
    'Inputs', '++', 'IconShape', 'round');
sl_add(path, 'built-in/Outport', 'u', [370 68 400 82], 'Port', '1');
sl_line(path, 'e/1', 'Kp/1');
sl_line(path, 'e/1', 'Ki/1');
sl_line(path, 'Ki/1', 'integral Ts z over (z-1)/1');
sl_line(path, 'Kp/1', 'sum/1');
sl_line(path, 'integral Ts z over (z-1)/1', 'sum/2');
sl_line(path, 'sum/1', 'u/1');
end
