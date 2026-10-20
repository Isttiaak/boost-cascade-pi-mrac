function mdl = build_frest_model(plant, outdir)
%BUILD_FREST_MODEL  Open-loop plant for the frequency-response estimate of
%   Section II-A (Fig. 1, Eq. 2): duty operating point -> PWM -> plant.
%   Linear-analysis points: input at the output of block 'duty operating
%   point', output at port 1 (v_out) of block 'Plant'. Start it in steady
%   state by setting BM.iL0 and BM.v0 (run_frestimate_study does this).
mdl = sprintf('boost_frest_%s', plant);
file = new_model(mdl, outdir, ['Duty-to-output plant for frestimate (Section II-A ' ...
    'of Yanarates & Zhou 2022).']);
sl_add(mdl, 'simulink/Sources/Constant', 'duty operating point', [30 40 110 70], ...
    'Value', 'BM.duty_ol');
add_pwm(mdl, 'PWM modulator', [170 35 250 75]);
sl_add(mdl, 'simulink/Sources/Constant', 'V_in', [30 120 90 150], 'Value', 'BM.vin(1)');
sl_line(mdl, 'duty operating point/1', 'PWM modulator/1', 'd');
switch plant
    case 'sps'
        add_plant_sps(mdl, 'Plant', [330 30 470 170]);
        sl_add(mdl, 'simulink/Sources/Constant', 'load switch A', [200 180 260 200], ...
            'Value', 'BM.g_a(1)');
        sl_add(mdl, 'simulink/Sources/Constant', 'load switch B', [200 220 260 240], ...
            'Value', 'BM.g_b(1)');
        sl_line(mdl, 'load switch A/1', 'Plant/3');
        sl_line(mdl, 'load switch B/1', 'Plant/4');
        sl_add(mdl, 'sps_lib/powergui', 'powergui', [30 250 110 290]);
        sl_setp([mdl '/powergui'], 'SimulationMode', 'Continuous');
    case 'diffeq'
        add_plant_diffeq(mdl, 'Plant', [330 30 470 170]);
        sl_add(mdl, 'simulink/Sources/Constant', 'R_load', [200 180 260 210], ...
            'Value', 'BM.rload(1)');
        sl_line(mdl, 'R_load/1', 'Plant/3');
    otherwise
        error('build_frest_model:plant', 'Unknown plant %s', plant);
end
sl_line(mdl, 'PWM modulator/1', 'Plant/1', 'gate');
sl_line(mdl, 'V_in/1', 'Plant/2');
sl_add(mdl, 'built-in/Outport', 'v_out', [560 63 590 77], 'Port', '1');
sl_add(mdl, 'built-in/Outport', 'i_L', [560 123 590 137], 'Port', '2');
sl_line(mdl, 'Plant/1', 'v_out/1', 'v_out');
sl_line(mdl, 'Plant/2', 'i_L/1', 'i_L');
finish_model(mdl, file, ['Frequency-response estimation plant: linear input at the ' ...
    'duty operating point, linear output at Plant/1.'], [30 320 600 340]);
end
