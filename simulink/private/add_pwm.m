function path = add_pwm(sys, name, pos)
%ADD_PWM  PWM modulator: gate = 1 while duty > sawtooth carrier (0 -> 1 at f_sw).
%   The carrier restarts at the beginning of every switching period, so the
%   switch turns on at the start of the period and off when the carrier
%   reaches the duty command (trailing-edge modulation). The comparison is
%   continuous; zero-crossing detection places every edge exactly.
path = [sys '/' name];
add_block('built-in/Subsystem', path, 'Position', pos);
sl_add(path, 'built-in/Inport', 'duty', [20 38 50 52], 'Port', '1');
sl_add(path, 'simulink/Sources/Repeating Sequence', 'carrier (sawtooth at f_sw)', ...
    [20 95 70 125], 'rep_seq_t', '[0 BM.Tsw]', 'rep_seq_y', '[0 1]');
sl_add(path, 'simulink/Logic and Bit Operations/Relational Operator', 'duty > carrier', ...
    [130 40 170 90], 'Operator', '>');
sl_add(path, 'simulink/Signal Attributes/Data Type Conversion', 'to double', ...
    [210 50 260 80], 'OutDataTypeStr', 'double');
sl_add(path, 'built-in/Outport', 'gate', [300 58 330 72], 'Port', '1');
sl_line(path, 'duty/1', 'duty > carrier/1');
sl_line(path, 'carrier (sawtooth at f_sw)/1', 'duty > carrier/2', 'carrier');
sl_line(path, 'duty > carrier/1', 'to double/1');
sl_line(path, 'to double/1', 'gate/1');
end
