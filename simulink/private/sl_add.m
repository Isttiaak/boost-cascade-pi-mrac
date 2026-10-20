function path = sl_add(sys, lib, name, pos, varargin)
%SL_ADD  add_block at a position, then set its parameters one by one.
%   path = sl_add(sys, lib, name, pos, 'Param', 'value', ...)
%   Parameters are set in the order given, so dependent mask parameters can
%   follow the parameter that enables them. Returns the block path.
path = [sys '/' name];
add_block(lib, path, 'Position', pos);
for k = 1:2:numel(varargin)
    try
        set_param(path, varargin{k}, varargin{k + 1});
    catch err
        error('sl_add:param', 'Could not set %s = %s on %s (%s): %s', ...
            varargin{k}, varargin{k + 1}, path, lib, err.message);
    end
end
end
