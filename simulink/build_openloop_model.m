function mdl = build_openloop_model(outdir, withSps)
%BUILD_OPENLOOP_MODEL  Section III / Fig. 7: the three model types in open loop.
%   boost_openloop_models.slx drives, with the same PWM at D = BM.duty_ol:
%     - the circuit model (Specialized Power Systems, if withSps)
%     - the differential-equation model of Fig. 6 with the diode limit
%     - the differential-equation model of Fig. 6 as drawn (no limit)
%   and feeds the duty to the transfer function of Eq. 31 (Table 3 values).
%   Logged every Ts: v_sps, iL_sps, v_de_diode, iL_de_diode, v_de_bidir,
%   iL_de_bidir, v_tf.
if nargin < 2
    withSps = true;
end
mdl = 'boost_openloop_models';
file = new_model(mdl, outdir, ['Open-loop comparison of the model types of ' ...
    'Section III (Fig. 7), Yanarates & Zhou (2022).']);

sl_add(mdl, 'simulink/Sources/Constant', 'duty D', [30 150 90 180], 'Value', 'BM.duty_ol');
add_pwm(mdl, 'PWM modulator', [150 145 230 185]);
sl_add(mdl, 'simulink/Sources/Constant', 'V_in', [30 330 90 360], 'Value', 'BM.vin(1)');
sl_add(mdl, 'simulink/Sources/Constant', 'R_load', [30 400 90 430], 'Value', 'BM.rload(1)');
sl_line(mdl, 'duty D/1', 'PWM modulator/1', 'd');

logs = {};
row = 0;
if withSps
    add_plant_sps(mdl, 'circuit model', [380 30 520 130]);
    sl_add(mdl, 'simulink/Sources/Constant', 'load switch A', [250 80 310 100], ...
        'Value', 'BM.g_a(1)');
    sl_add(mdl, 'simulink/Sources/Constant', 'load switch B', [250 110 310 130], ...
        'Value', 'BM.g_b(1)');
    sl_line(mdl, 'PWM modulator/1', 'circuit model/1', 'gate');
    sl_line(mdl, 'V_in/1', 'circuit model/2');
    sl_line(mdl, 'load switch A/1', 'circuit model/3');
    sl_line(mdl, 'load switch B/1', 'circuit model/4');
    sl_add(mdl, 'sps_lib/powergui', 'powergui', [30 30 110 70]);
    sl_setp([mdl '/powergui'], 'SimulationMode', 'Continuous');
    logs(end + 1, :) = {'v_sps', 'circuit model/1'};
    logs(end + 1, :) = {'iL_sps', 'circuit model/2'};
end
add_plant_diffeq(mdl, 'Fig. 6 equations with diode limit', [380 170 520 270]);
add_plant_diffeq(mdl, 'Fig. 6 equations as drawn', [380 310 520 410], '-Inf');
for b = {'Fig. 6 equations with diode limit', 'Fig. 6 equations as drawn'}
    sl_line(mdl, 'PWM modulator/1', [b{1} '/1']);
    sl_line(mdl, 'V_in/1', [b{1} '/2']);
    sl_line(mdl, 'R_load/1', [b{1} '/3']);
end
logs(end + 1, :) = {'v_de_diode', 'Fig. 6 equations with diode limit/1'};
logs(end + 1, :) = {'iL_de_diode', 'Fig. 6 equations with diode limit/2'};
logs(end + 1, :) = {'v_de_bidir', 'Fig. 6 equations as drawn/1'};
logs(end + 1, :) = {'iL_de_bidir', 'Fig. 6 equations as drawn/2'};

% transfer-function model: Eq. 31 with the Table 3 values
num = '[-BM.L*BM.Vin_nom, BM.R_nom*BM.Vin_nom*(1-BM.D)^2]';
den = '[BM.L*BM.R_nom*BM.C*(1-BM.D)^2, BM.L*(1-BM.D)^2, BM.R_nom*(1-BM.D)^4]';
sl_add(mdl, 'simulink/Continuous/Transfer Fcn', 'Eq. 31 transfer function', ...
    [380 450 520 490], 'Numerator', num, 'Denominator', den);
sl_line(mdl, 'duty D/1', 'Eq. 31 transfer function/1');
logs(end + 1, :) = {'v_tf', 'Eq. 31 transfer function/1'};

for k = 1:size(logs, 1)
    row = row + 1;
    y = 30 + 50 * (row - 1);
    blk = ['log ' logs{k, 1}];
    sl_add(mdl, 'simulink/Sinks/To Workspace', blk, [700 y 780 y + 26], ...
        'VariableName', logs{k, 1}, 'MaxDataPoints', 'inf', ...
        'SaveFormat', 'Timeseries', 'SampleTime', 'BM.Ts');
    sl_line(mdl, logs{k, 2}, [blk '/1']);
end
finish_model(mdl, file, ['Fig. 7 recreated: circuit, differential-equation and ' ...
    'transfer-function models driven by the same duty D = BM.duty_ol.'], [30 520 700 540]);
end
