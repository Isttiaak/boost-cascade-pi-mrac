function [num, den] = ref_model_tf(variant)
%REF_MODEL_TF  Closed-loop reference model T_m(s) = C G / (1 + C G).
%   G = Eq. 51 reference boost converter, C = Eq. 52 PI.
%   variant = 'derived' : Eq. 51 numerator recomputed from Eq. 31 + Table 8 (-0.00625 s + 50)
%   variant = 'printed' : Eq. 51 exactly as printed (-0.0625 s + 50) -> unstable loop
if nargin < 1, variant = 'derived'; end
P = paper_values();
if strcmp(variant, 'derived')
    nG = [-0.00625 50];
else
    nG = P.eq51_num;
end
dG = P.eq51_den;
nC = [P.eq52.Kp P.eq52.Ki];  dC = [1 0];
nOL = conv(nC, nG);  dOL = conv(dC, dG);
nOL = [zeros(1, numel(dOL) - numel(nOL)) nOL];
num = nOL;
den = dOL + nOL;
% strip leading zeros of the numerator
while numel(num) > 1 && num(1) == 0, num(1) = []; end
end
