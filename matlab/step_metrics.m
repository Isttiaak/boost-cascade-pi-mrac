function S = step_metrics(t, y, yfinal, yinit, settle_ref)
%STEP_METRICS  MATLAB-stepinfo-style metrics (definitions of MATLAB stepinfo).
%   S = step_metrics(t, y, yfinal, yinit, settle_ref)
%   settle_ref = 'peak_error' (default): settling band = 2% of max|y - yfinal|.
%                This is the definition that reproduces the paper's Table 6 exactly.
%   settle_ref = 'final'               : band = 2% of |yfinal - yinit|.
%   Overshoot/Undershoot are percentages of |yfinal - yinit|.
if nargin < 3 || isempty(yfinal), yfinal = y(end); end
if nargin < 4 || isempty(yinit),  yinit = 0; end
if nargin < 5, settle_ref = 'peak_error'; end
t = t(:); y = y(:);
dy = yfinal - yinit;  s = sign(dy);  if s == 0, s = 1; end
yn = (y - yinit) * s;  D = abs(dy);

tlo = first_cross(t, yn, 0.1*D);
thi = first_cross(t, yn, 0.9*D);
S.RiseTime = thi - tlo;

err = abs(y - yfinal);
if strcmp(settle_ref, 'peak_error'), thr = 0.02*max(err); else, thr = 0.02*D; end
out = find(err > thr);
if isempty(out)
    S.SettlingTime = t(1);
elseif out(end) == numel(t)
    S.SettlingTime = NaN;
else
    i = out(end);
    frac = (err(i) - thr) / (err(i) - err(i+1));
    S.SettlingTime = t(i) + frac*(t(i+1) - t(i));
end

if isnan(thi)
    S.SettlingMin = NaN; S.SettlingMax = NaN;
else
    m = t >= thi;
    S.SettlingMin = min(y(m)); S.SettlingMax = max(y(m));
end
S.Overshoot  = max(0, (max(yn) - D) / D * 100);
S.Undershoot = max(0, -min(yn) / D * 100);
[S.Peak, ipk] = max(abs(y));
S.PeakTime = t(ipk);
end

function tc = first_cross(t, yn, level)
i = find(yn >= level, 1, 'first');
if isempty(i), tc = NaN; return; end
if i == 1, tc = t(1); return; end
tc = t(i-1) + (level - yn(i-1)) * (t(i) - t(i-1)) / (yn(i) - yn(i-1));
end
