function path = add_controller(sys, name, ctrl, pos)
%ADD_CONTROLLER  Discrete controller subsystem, sample time BM.Ts.
%   Inputs : 1 V_ref, 2 v_out, 3 i_L  (sampled by the A-D blocks, Fig. 19)
%   Outputs: 1 u      duty command before the limiter
%            2 theta  adaptation parameter (1 without MRAC)
%            3 y_m    reference-model output V_ref(out) (0 without MRAC)
%            4 i_ref  inner-loop set-point (0 for the single PI)
%
%   ctrl = 'single_pi'           Fig. 8, Eq. 33
%          'cascade_pi'          Fig. 9, Eqs. 42-43
%          'cascade_pi_mrac'     Figs. 10, 12 and 19, Eqs. 44, 54-56 as written:
%                                outer loop e = V_ref - v_out,
%                                theta = -gamma Ts z/(z-1) [(v_out - y_m) y_m],
%                                u = theta * u_pi
%          'cascade_pi_mrac_mf'  same, but the outer loop tracks y_m
%                                (model-following set-point)
path = [sys '/' name];
add_block('built-in/Subsystem', path, 'Position', pos);

ins = {'V_ref', 'v_out', 'i_L'};
for k = 1:3
    y = 40 + 90 * (k - 1);
    sl_add(path, 'built-in/Inport', ins{k}, [20 y 50 y + 14], 'Port', num2str(k));
    sl_add(path, 'simulink/Discrete/Zero-Order Hold', ['A-D ' ins{k}], ...
        [90 y - 8 130 y + 22], 'SampleTime', 'BM.Ts');
    sl_line(path, [ins{k} '/1'], ['A-D ' ins{k} '/1']);
end
outs = {'u', 'theta', 'y_m', 'i_ref'};
for k = 1:4
    y = 40 + 80 * (k - 1);
    sl_add(path, 'built-in/Outport', outs{k}, [1010 y 1040 y + 14], 'Port', num2str(k));
end

isMrac = any(strcmp(ctrl, {'cascade_pi_mrac', 'cascade_pi_mrac_mf'}));
switch ctrl
    case 'single_pi'
        sl_add(path, 'simulink/Math Operations/Sum', 'e', [200 37 220 57], ...
            'Inputs', '+-', 'IconShape', 'round');
        add_pi(path, 'PI controller (Eq. 33)', 'BM.Kp_s', 'BM.Ki_s', [270 25 380 70]);
        sl_line(path, 'A-D V_ref/1', 'e/1');
        sl_line(path, 'A-D v_out/1', 'e/2');
        sl_line(path, 'e/1', 'PI controller (Eq. 33)/1', 'e');
        sl_line(path, 'PI controller (Eq. 33)/1', 'u/1', 'u');
        constant_out(path, 'no adaptation', '1', 'theta', [870 115 930 135]);
        constant_out(path, 'no reference model', '0', 'y_m', [870 195 930 215]);
        constant_out(path, 'no inner loop', '0', 'i_ref', [870 275 930 295]);
    case {'cascade_pi', 'cascade_pi_mrac', 'cascade_pi_mrac_mf'}
        sl_add(path, 'simulink/Math Operations/Sum', 'e_v', [200 37 220 57], ...
            'Inputs', '+-', 'IconShape', 'round');
        add_pi(path, 'Outer loop PI (Eq. 42)', 'BM.Kp_o', 'BM.Ki_o', [260 25 370 70]);
        sl_add(path, 'simulink/Math Operations/Sum', 'e_i', [420 37 440 57], ...
            'Inputs', '+-', 'IconShape', 'round');
        add_pi(path, 'Inner loop PI (Eq. 43)', 'BM.Kp_i', 'BM.Ki_i', [480 25 590 70]);
        if strcmp(ctrl, 'cascade_pi_mrac_mf')
            setpoint = 'Reference model T_m(z)/1';
        else
            setpoint = 'A-D V_ref/1';
        end
        sl_line(path, 'A-D v_out/1', 'e_v/2');
        sl_line(path, 'e_v/1', 'Outer loop PI (Eq. 42)/1', 'e_v');
        sl_line(path, 'Outer loop PI (Eq. 42)/1', 'e_i/1', 'i_ref');
        sl_line(path, 'Outer loop PI (Eq. 42)/1', 'i_ref/1');
        sl_line(path, 'A-D i_L/1', 'e_i/2');
        sl_line(path, 'e_i/1', 'Inner loop PI (Eq. 43)/1', 'e_i');
        if isMrac
            % reference model (Eqs. 51-53): closed loop of Eq. 52 PI and Eq. 51, Tustin
            sl_add(path, 'simulink/Discrete/Discrete Transfer Fcn', 'Reference model T_m(z)', ...
                [200 290 330 340], 'Numerator', 'BM.ref_bz', 'Denominator', 'BM.ref_az', ...
                'SampleTime', 'BM.Ts');
            sl_line(path, 'A-D V_ref/1', 'Reference model T_m(z)/1');
            % adaptation mechanism (Eqs. 44, 55, 56)
            sl_add(path, 'simulink/Math Operations/Sum', 'e_t', [420 380 440 400], ...
                'Inputs', '+-', 'IconShape', 'round');
            sl_add(path, 'simulink/Math Operations/Product', 'e_t times y_m', ...
                [490 372 520 408], 'Inputs', '**');
            sl_add(path, 'simulink/Math Operations/Gain', 'learning rate (-gamma)', ...
                [560 375 620 405], 'Gain', '-BM.gamma');
            sl_add(path, 'simulink/Discrete/Discrete-Time Integrator', ...
                'adaptation parameter theta', [670 372 720 408], ...
                'IntegratorMethod', 'Integration: Backward Euler', 'gainval', '1', ...
                'InitialCondition', 'BM.theta0', 'SampleTime', 'BM.Ts');
            sl_add(path, 'simulink/Math Operations/Product', 'u = theta u_pi', ...
                [790 30 820 70], 'Inputs', '**');
            sl_line(path, setpoint, 'e_v/1');
            sl_line(path, 'A-D v_out/1', 'e_t/1');
            sl_line(path, 'Reference model T_m(z)/1', 'e_t/2', 'y_m');
            sl_line(path, 'e_t/1', 'e_t times y_m/1', 'e_t');
            sl_line(path, 'Reference model T_m(z)/1', 'e_t times y_m/2');
            sl_line(path, 'e_t times y_m/1', 'learning rate (-gamma)/1');
            sl_line(path, 'learning rate (-gamma)/1', 'adaptation parameter theta/1');
            sl_line(path, 'adaptation parameter theta/1', 'u = theta u_pi/1', 'theta');
            sl_line(path, 'Inner loop PI (Eq. 43)/1', 'u = theta u_pi/2', 'u_pi');
            sl_line(path, 'u = theta u_pi/1', 'u/1', 'u');
            sl_line(path, 'adaptation parameter theta/1', 'theta/1');
            sl_line(path, 'Reference model T_m(z)/1', 'y_m/1');
        else
            sl_line(path, setpoint, 'e_v/1');
            sl_line(path, 'Inner loop PI (Eq. 43)/1', 'u/1', 'u');
            constant_out(path, 'no adaptation', '1', 'theta', [870 115 930 135]);
            constant_out(path, 'no reference model', '0', 'y_m', [870 195 930 215]);
        end
    otherwise
        error('add_controller:ctrl', 'Unknown controller %s', ctrl);
end
end

function constant_out(path, name, value, outport, pos)
sl_add(path, 'simulink/Sources/Constant', name, pos, 'Value', value);
sl_line(path, [name '/1'], [outport '/1']);
end
