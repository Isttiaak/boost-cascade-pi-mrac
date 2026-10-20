function h = sl_line(sys, src, dst, signalName)
%SL_LINE  Signal line 'Block/port' -> 'Block/port' with autorouting.
%   h = sl_line(sys, src, dst, signalName) also names the signal.
h = add_line(sys, src, dst, 'autorouting', 'on');
if nargin > 3 && ~isempty(signalName)
    set_param(h, 'Name', signalName);
end
end
