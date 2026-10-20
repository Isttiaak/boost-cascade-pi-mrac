function path = add_profile(sys, name, valueExpr, timeExpr, pos)
%ADD_PROFILE  Subsystem that outputs x(1), then x(2) from t(1), x(3) from t(2).
%   valueExpr / timeExpr are workspace expressions such as 'BM.vref' and
%   'BM.t_vref'. Built from a Constant and two Step blocks, so the switching
%   instants are exact solver breakpoints.
path = [sys '/' name];
add_block('built-in/Subsystem', path, 'Position', pos);
v = valueExpr;
sl_add(path, 'simulink/Sources/Constant', 'initial value', [30 25 110 55], ...
    'Value', sprintf('%s(1)', v));
sl_add(path, 'simulink/Sources/Step', 'change at t1', [55 85 85 115], ...
    'Time', sprintf('%s(1)', timeExpr), 'Before', '0', ...
    'After', sprintf('%s(2)-%s(1)', v, v), 'SampleTime', '0');
sl_add(path, 'simulink/Sources/Step', 'change at t2', [55 145 85 175], ...
    'Time', sprintf('%s(2)', timeExpr), 'Before', '0', ...
    'After', sprintf('%s(3)-%s(2)', v, v), 'SampleTime', '0');
sl_add(path, 'simulink/Math Operations/Sum', 'add', [170 80 200 120], ...
    'Inputs', '+++', 'IconShape', 'rectangular');
sl_add(path, 'built-in/Outport', 'out', [250 93 280 107], 'Port', '1');
sl_line(path, 'initial value/1', 'add/1');
sl_line(path, 'change at t1/1', 'add/2');
sl_line(path, 'change at t2/1', 'add/3');
sl_line(path, 'add/1', 'out/1');
end
