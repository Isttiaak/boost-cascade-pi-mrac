function sl_wire(sys, varargin)
%SL_WIRE  Join physical (electrical) ports into one node.
%   sl_wire(sys, blkA, 'R1', blkB, 'L1', blkC, 'L1', ...) connects every
%   listed port to the first one. Port tags: 'L1', 'L2' (LConn), 'R1' (RConn).
%   blk is the block name inside sys.
assert(mod(numel(varargin), 2) == 0 && numel(varargin) >= 4, ...
    'sl_wire:args', 'Need at least two block/port pairs.');
h0 = port(sys, varargin{1}, varargin{2});
for k = 3:2:numel(varargin)
    hk = port(sys, varargin{k}, varargin{k + 1});
    add_line(sys, h0, hk, 'autorouting', 'on');
end
end

function h = port(sys, blk, tag)
ph = get_param([sys '/' blk], 'PortHandles');
idx = str2double(tag(2:end));
switch upper(tag(1))
    case 'L'
        list = ph.LConn;
    case 'R'
        list = ph.RConn;
    otherwise
        error('sl_wire:tag', 'Unknown port tag %s', tag);
end
assert(numel(list) >= idx, 'sl_wire:port', '%s/%s has no port %s (LConn %d, RConn %d).', ...
    sys, blk, tag, numel(ph.LConn), numel(ph.RConn));
h = list(idx);
end
