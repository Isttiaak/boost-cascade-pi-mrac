%VERIFY_EQUATIONS  Step 1: recompute the paper's printed numbers from its own formulas.
%   Prints a report and writes ../results_matlab/tables/equation_check.txt
clear; clc;
P = paper_values();
outdir = fullfile('..', 'results_matlab', 'tables');
if ~exist(outdir, 'dir'), mkdir(outdir); end
fid = fopen(fullfile(outdir, 'equation_check.txt'), 'w');
say = @(varargin) say_both(fid, varargin{:});

Vdc = P.Vdc; L = P.L; C = P.C; R = P.R; D = P.D; Dp = 1 - D;

say('1) Operating point and averaged model (Eqs. 1, 3-18)\n');
A = [0 -Dp/L; Dp/C -1/(R*C)];  B = [1/L; 0];
X = -A \ (B*Vdc);
say('   D = %.3f,  I_L = %.4f A,  V_C = %.4f V\n\n', D, X(1), X(2));

say('2) Control-to-output TF v/d (Eq. 31 -> numbers)\n');
num31 = [-L*Vdc, R*Vdc*Dp^2];
den31 = [L*R*C*Dp^2, L*Dp^2, R*Dp^4];
describe(say, 'Eq. 31 with Table 3 values (correct)', num31, den31);
describe(say, 'Eq. 31 normalised (num constant = 1)', num31/num31(2), den31/num31(2));
describe(say, 'Eq. 32 AS PRINTED', P.eq32_num, P.eq32_den);
describe(say, 'Eq. 2 AS PRINTED', P.eq2_num, P.eq2_den);
say('   -> Eq. 32 divides only the s^2 term and constants by 80; RHP zero 40000 -> 500 rad/s.\n\n');

say('3) Duty -> inductor current (Eq. 39 -> numbers)\n');
num39 = [R*C*Vdc, 2*Vdc];  den39 = [L*R*C*Dp, L*Dp, R*Dp^3];
describe(say, 'Eq. 39 evaluated (correct)', num39, den39);
describe(say, 'Eq. 40 AS PRINTED', P.eq40_num, P.eq40_den);
say('   -> Eq. 40 DC gain 1600 A/duty instead of 20 A/duty.\n\n');

say('4) Inductor current -> output voltage (Eq. 41)\n');
describe(say, 'Gvd/Gid after cancellation (correct)', [-L, R*Dp^2], [Dp*R*C, 2*Dp]);
describe(say, 'printed expression after Eq. 41', P.eq41_num, P.eq41_den);
say('   -> printed = Eq.32/Eq.40 multiplied out without cancelling.\n\n');

say('5) Reference model (Table 8, Eq. 51)\n');
Rmin = P.ref_Rmin; Dr = P.ref_D;
ILmax = P.Vout^2/(Rmin*Vdc); dIL = 0.2*ILmax; Lr = Vdc*Dr/(P.fsw*dIL);
dV = 0.04*P.Vout; Cr = Vdc*Dr/(Rmin*P.fsw*dV*(1-Dr));
say('   I_L,max = %.3f A, dI_L = %.3f A, L = %.4f mH, dV = %.3f V, C = %.2f uF\n', ...
    ILmax, dIL, Lr*1e3, dV, Cr*1e6);
Drp = 1 - Dr;
describe(say, 'Eq. 31 with Table 8 values (correct)', [-Lr*Vdc, Rmin*Vdc*Drp^2], ...
         [Lr*Rmin*Cr*Drp^2, Lr*Drp^2, Rmin*Drp^4]);
describe(say, 'Eq. 51 AS PRINTED', P.eq51_num, P.eq51_den);
[nT, dT] = ref_model_tf('derived');  [nTp, dTp] = ref_model_tf('printed');
say('   closed-loop reference model poles, derived : %s\n', mat2str(roots(dT).', 5));
say('   closed-loop reference model poles, printed : %s  (unstable)\n\n', mat2str(roots(dTp).', 5));

say('6) Controllers\n');
g = {P.pi_single, P.pi_outer, P.pi_inner, P.eq52};
nm = {'single PI Eq.33', 'outer PI Eq.42', 'inner PI Eq.43', 'reference PI Eq.52'};
for k = 1:4
    say('   %-20s Kp = %-10g Ki = %-8g zero at %.4g rad/s\n', nm{k}, g{k}.Kp, g{k}.Ki, g{k}.Ki/g{k}.Kp);
end
say('   inner-loop crossover ~ Kp_i*Vout/L = %.3g rad/s (%.1f kHz) > fsw = 20 kHz\n', ...
    P.pi_inner.Kp*P.Vout/L, P.pi_inner.Kp*P.Vout/L/2/pi/1e3);
fclose(fid);

function describe(say, name, num, den)
z = roots(num); p = roots(den);
dc = polyval(num, 0) / polyval(den, 0);
say('   %s\n      num = %s\n      den = %s\n      DC gain = %.6g   zeros = %s   poles = %s\n', ...
    name, mat2str(num, 5), mat2str(den, 5), dc, mat2str(z.', 5), mat2str(p.', 5));
end

function say_both(fid, varargin)
% print to the command window and to the report file
fprintf(1, varargin{:});
fprintf(fid, varargin{:});
end
