function ok = sl_setp(blk, varargin)
%SL_SETP  Set mask parameters that a block has; warn about the others.
%   ok = sl_setp(blk, 'Name', value, ...) returns false if any parameter was
%   missing or rejected. Used for Specialized Power Systems blocks, whose
%   parameter names have changed between releases.
ok = true;
dp = get_param(blk, 'DialogParameters');
for k = 1:2:numel(varargin)
    name = varargin{k};
    if ~(isstruct(dp) && isfield(dp, name))
        warning('sl_setp:missing', '%s has no parameter "%s"; left at its default.', ...
            blk, name);
        ok = false;
        continue
    end
    try
        set_param(blk, name, varargin{k + 1});
    catch err
        warning('sl_setp:rejected', '%s: %s = %s rejected (%s); left at its default.', ...
            blk, name, varargin{k + 1}, err.message);
        ok = false;
    end
end
end
