function path = add_plant_sps(sys, name, pos)
%ADD_PLANT_SPS  Boost converter circuit with Specialized Power Systems blocks
%   (the paper's "block diagram model", Figs. 3 and 10): controlled DC source,
%   L, MOSFET, diode, C and a switched-resistor load (LOAD_NETWORK).
%   Inputs : 1 gate, 2 V_in, 3 gate of load branch A, 4 gate of load branch B
%   Outputs: 1 v_out (across C), 2 i_L (inductor current)
%   Needs a powergui block at the top level of the model.
%
%   Port polarities follow a working R2025a model: source "+" = RConn1,
%   diode anode = LConn1, switch drain/collector = LConn1, voltage
%   measurement "+" = LConn1 and "-" = LConn2. Vertical elements are drawn
%   between a top rail (input/switching/output nodes) and a bottom rail.
path = [sys '/' name];
add_block('built-in/Subsystem', path, 'Position', pos);

% Simulink ports
sl_add(path, 'built-in/Inport', 'V_in', [20 318 50 332], 'Port', '2');
sl_add(path, 'built-in/Inport', 'gate', [250 48 280 62], 'Port', '1');
sl_add(path, 'built-in/Inport', 'gate load A', [600 48 630 62], 'Port', '3');
sl_add(path, 'built-in/Inport', 'gate load B', [740 48 770 62], 'Port', '4');
sl_add(path, 'built-in/Outport', 'v_out', [1000 208 1030 222], 'Port', '1');
sl_add(path, 'built-in/Outport', 'i_L', [1000 18 1030 32], 'Port', '2');

lib = 'sps_lib';
% source: "+" (RConn) on top, "-" (LConn) at the bottom
src = sl_add(path, [lib '/Sources/Controlled Voltage Source'], 'V_dc', [80 190 120 250]);
set_param(src, 'Orientation', 'up');
sl_setp(src, 'Initialize', 'on', 'Source_Type', 'DC', 'Amplitude', 'BM.vin(1)', ...
    'Measurements', 'None');
% top rail
Lb = sl_add(path, [lib '/Passives/Series RLC Branch'], 'L', [150 110 210 140]);
sl_setp(Lb, 'BranchType', 'L', 'Inductance', 'BM.L', 'SetiL0', 'on', ...
    'InitialCurrent', 'BM.iL0', 'Measurements', 'None');
sl_add(path, [lib '/Sensors and Measurements/Current Measurement'], 'i_L sensor', ...
    [240 110 270 140]);
d = sl_add(path, [lib '/Power Electronics/Diode'], 'D', [400 110 450 140]);
sl_setp(d, 'Ron', 'BM.Ron_d', 'Lon', '0', 'Vf', 'BM.Vf_d', 'IC', '0', ...
    'Rs', 'inf', 'Cs', '0', 'Measurements', 'off');
% vertical elements: LConn on top, RConn at the bottom
sw = sl_add(path, [lib '/Power Electronics/Mosfet'], 'SW', [310 190 370 250]);
set_param(sw, 'Orientation', 'down');
sl_setp(sw, 'Ron', 'BM.Ron_sw', 'Lon', '0', 'IC', '0', 'Rs', '1e5', 'Cs', 'inf', ...
    'Measurements', 'off');
Cb = sl_add(path, [lib '/Passives/Series RLC Branch'], 'C_out', [490 190 530 250]);
set_param(Cb, 'Orientation', 'down');
sl_setp(Cb, 'BranchType', 'C', 'Capacitance', 'BM.C', 'Setx0', 'on', ...
    'InitialVoltage', 'BM.v0', 'Measurements', 'None');
Rb = sl_add(path, [lib '/Passives/Series RLC Branch'], 'R_base', [560 190 600 250]);
set_param(Rb, 'Orientation', 'down');
sl_setp(Rb, 'BranchType', 'R', 'Resistance', 'BM.R_base', 'Measurements', 'None');
names = {'A', 'B'};
rexpr = {'BM.R_a', 'BM.R_b'};
x0 = [650 790];
for k = 1:2
    s = sl_add(path, [lib '/Power Electronics/Ideal Switch'], ['S_' names{k}], ...
        [x0(k) 170 x0(k) + 40 220]);
    set_param(s, 'Orientation', 'down');
    sl_setp(s, 'Ron', '1e-3', 'IC', '0', 'Rs', '1e5', 'Cs', 'inf', 'Measurements', 'off');
    r = sl_add(path, [lib '/Passives/Series RLC Branch'], ['R_' names{k}], ...
        [x0(k) 250 x0(k) + 40 300]);
    set_param(r, 'Orientation', 'down');
    sl_setp(r, 'BranchType', 'R', 'Resistance', rexpr{k}, 'Measurements', 'None');
end
sl_add(path, [lib '/Sensors and Measurements/Voltage Measurement'], 'v_out sensor', ...
    [920 195 950 235]);

% nodes
sl_wire(path, 'V_dc', 'R1', 'L', 'L1');                                   % input +
sl_wire(path, 'L', 'R1', 'i_L sensor', 'L1');
sl_wire(path, 'i_L sensor', 'R1', 'D', 'L1', 'SW', 'L1');                 % switching node
sl_wire(path, 'D', 'R1', 'C_out', 'L1', 'R_base', 'L1', 'S_A', 'L1', ...  % output +
    'S_B', 'L1', 'v_out sensor', 'L1');
sl_wire(path, 'S_A', 'R1', 'R_A', 'L1');
sl_wire(path, 'S_B', 'R1', 'R_B', 'L1');
sl_wire(path, 'V_dc', 'L1', 'SW', 'R1', 'C_out', 'R1', 'R_base', 'R1', ... % return rail
    'R_A', 'R1', 'R_B', 'R1', 'v_out sensor', 'L2');

% signals
sl_line(path, 'V_in/1', 'V_dc/1');
sl_line(path, 'gate/1', 'SW/1');
sl_line(path, 'gate load A/1', 'S_A/1');
sl_line(path, 'gate load B/1', 'S_B/1');
sl_line(path, 'i_L sensor/1', 'i_L/1', 'i_L');
sl_line(path, 'v_out sensor/1', 'v_out/1', 'v_out');
end
