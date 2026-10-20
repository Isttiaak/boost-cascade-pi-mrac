function [nv, ni, den, IL, V] = averaged_linear_tf(prm, Vin, R, D)
%AVERAGED_LINEAR_TF  Small-signal TFs v/d = nv/den and iL/d = ni/den of the
%   averaged boost model at duty D (with optional parasitics in prm).
%   With zero parasitics this is exactly Eq. (31) and Eq. (39).
%   For the 2x2 model x' = A x + B d, y = c x:
%       den = s^2 - trace(A) s + det(A),
%       num = (c B) s + c [-a22 a12; a21 -a11] B      (no toolbox needed)
P = paper_values();
if nargin < 2, Vin = P.Vdc; end
if nargin < 3, R = P.R; end
if nargin < 4, D = P.D; end
Dp = 1 - D;
rs = prm.rL + D*prm.Ron + Dp*prm.Rd;
V  = (Vin - Dp*prm.Vf) / (Dp + rs/(R*Dp));
IL = V / (R*Dp);
A = [-rs/prm.L, -Dp/prm.L; Dp/prm.C, -1/(R*prm.C)];
B = [(-(prm.Ron - prm.Rd)*IL + V + prm.Vf)/prm.L; -IL/prm.C];
den = [1, -trace(A), det(A)];
K = [-A(2,2), A(1,2); A(2,1), -A(1,1)];
nv = strip([[0 1]*B, [0 1]*K*B]);
ni = strip([[1 0]*B, [1 0]*K*B]);
end

function p = strip(p)
while numel(p) > 1 && abs(p(1)) < 1e-14*max(abs(p)), p(1) = []; end
end
