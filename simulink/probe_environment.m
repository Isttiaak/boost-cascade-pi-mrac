function txt = probe_environment()
%PROBE_ENVIRONMENT  Print the MATLAB release, products and the library blocks
%   this repository uses (with their parameter names), to make CI logs
%   self-explanatory when a release renames something. Under GitHub Actions
%   the block list is also posted as a notice annotation.
entries = {};
fprintf('==== environment ====\n');
fprintf('MATLAB %s on %s\n', version, computer);
v = ver;
for k = 1:numel(v)
    fprintf('  %-45s %s\n', v(k).Name, v(k).Version);
end
lic = {'Simulink', 'Simscape', 'Power_System_Blocks', 'Control_Toolbox', ...
    'Simulink_Control_Design'};
for k = 1:numel(lic)
    fprintf('  license %-26s %d\n', lic{k}, license('test', lic{k}));
end
blocks = {'simulink/Discrete/Discrete-Time Integrator', ...
    'simulink/Discrete/Discrete Transfer Fcn', 'simulink/Discrete/Zero-Order Hold', ...
    'simulink/Sources/Repeating Sequence', 'simulink/Sources/Step', ...
    'simulink/Logic and Bit Operations/Relational Operator', ...
    'simulink/Signal Routing/Switch', 'simulink/Continuous/Integrator', ...
    'simulink/Sinks/To Workspace'};
load_system('simulink');
spsBlocks = {'sps_lib/powergui', 'sps_lib/Sources/Controlled Voltage Source', ...
    'sps_lib/Passives/Series RLC Branch', 'sps_lib/Power Electronics/Mosfet', ...
    'sps_lib/Power Electronics/Diode', 'sps_lib/Power Electronics/Ideal Switch', ...
    'sps_lib/Sensors and Measurements/Voltage Measurement', ...
    'sps_lib/Sensors and Measurements/Current Measurement'};
try
    load_system('sps_lib');
    blocks = [blocks, spsBlocks];
catch err
    fprintf('  sps_lib not loadable: %s\n', err.message);
end
for k = 1:numel(blocks)
    b = blocks{k};
    if getSimulinkBlockHandle(b) == -1
        fprintf('  MISSING block %s\n', b);
        entries{end + 1} = ['MISSING ' b]; %#ok<AGROW>
        continue
    end
    ph = get_param(b, 'PortHandles');
    dp = get_param(b, 'DialogParameters');
    names = {};
    if isstruct(dp)
        names = fieldnames(dp).';
    end
    entry = sprintf('%s  [in %d out %d L %d R %d]  %s', b, numel(ph.Inport), ...
        numel(ph.Outport), numel(ph.LConn), numel(ph.RConn), strjoin(names, ', '));
    fprintf('  %s\n', entry);
    entries{end + 1} = entry; %#ok<AGROW>
end
fprintf('==== end environment ====\n');
txt = strjoin([{sprintf('MATLAB %s', version)}, entries], newline);
if ~isempty(getenv('GITHUB_ACTIONS'))
    msg = strrep(txt, '%', '%25');
    msg = strrep(msg, newline, '%0A');
    fprintf('::notice title=probe_environment::%s\n', msg(1:min(end, 6000)));
end
end
