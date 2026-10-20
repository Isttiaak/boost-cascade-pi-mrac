"""
Step 1 of the recreation: recompute every printed number of the paper from its
own formulas (Eqs. 1, 3-18, 31, 39, 41, 45-52) and the Table 3 / Table 8 data,
and compare with what is printed.

Run:  python verify_equations.py
"""
import os
import numpy as np
import paper_values as P
from tftools import tf_info

OUT = os.path.join(os.path.dirname(__file__), "..", "results", "tables")
os.makedirs(OUT, exist_ok=True)

Vdc, L, C, R, D = P.VDC, P.L, P.C, P.R, P.D
Dp = 1 - D

lines = []
def say(s=""):
    print(s)
    lines.append(s)

def fmt_roots(r):
    return ", ".join(f"{x.real:.4g}{x.imag:+.4g}j" if abs(x.imag) > 1e-9 else f"{x.real:.6g}" for x in r)

def describe(name, num, den):
    i = tf_info(num, den)
    say(f"  {name}")
    say(f"     num = {np.array2string(np.asarray(num, float), precision=6)}")
    say(f"     den = {np.array2string(np.asarray(den, float), precision=6)}")
    say(f"     DC gain = {i['dc_gain']:.6g}   zeros: {fmt_roots(i['zeros'])}   poles: {fmt_roots(i['poles'])}")
    if "wn" in i:
        say(f"     wn = {i['wn']:.6g} rad/s   zeta = {i['zeta']:.4g}")
    return i

say("=" * 78)
say("1) Operating point (Eq. 1) and averaged state-space model (Eqs. 3-18)")
say("=" * 78)
A = np.array([[0, -Dp / L], [Dp / C, -1 / (R * C)]])
B = np.array([[1 / L], [0]])
X = -np.linalg.solve(A, B * Vdc)
say(f"  D = {D:.3f}")
say(f"  A = {A.tolist()}")
say(f"  B = {B.ravel().tolist()}   C = [0 1]")
say(f"  steady state  I_L = {X[0,0]:.4f} A,  V_C = {X[1,0]:.4f} V   (paper Eq. 18: Vdc/((D-1)^2 R) = 5 A, Vdc/(1-D) = 40 V)")

say()
say("=" * 78)
say("2) Control-to-output TF  v/d   (Eq. 31 symbolic -> numeric)")
say("=" * 78)
num31 = np.array([-L * Vdc, R * Vdc * Dp ** 2])
den31 = np.array([L * R * C * Dp ** 2, L * Dp ** 2, R * Dp ** 4])
i31 = describe("Eq. 31 evaluated with Table 3 values (correct)", num31, den31)
scale = num31[1]
describe("same TF normalised so that numerator constant = 1", num31 / scale, den31 / scale)
i32 = describe("Eq. 32 AS PRINTED", P.EQ32_NUM, P.EQ32_DEN)
i2 = describe("Eq. 2 AS PRINTED (Simulink Control Design estimate)", P.EQ2_NUM, P.EQ2_DEN)
say("  -> textbook check: RHP zero  R(1-D)^2/L = %.0f rad/s ; resonance (1-D)/sqrt(LC) = %.1f rad/s ;"
    " zeta = sqrt(L/C)/(2R(1-D)) = %.4f" % (R * Dp ** 2 / L, Dp / np.sqrt(L * C), np.sqrt(L / C) / (2 * R * Dp)))
say("  -> Eq. 32 = Eq. 31 / 80 only for the s^2 term and the constants; the s-terms (-0.002 s, 2.5e-5 s)")
say("     were NOT divided by 80. This moves the RHP zero from 40 000 to 500 rad/s and turns the")
say("     lightly damped resonance (zeta ~0.03) into two real poles (~ -524 and -10 840 rad/s).")

say()
say("=" * 78)
say("3) Duty -> inductor current TF  i_L/d   (Eq. 39 -> numeric)")
say("=" * 78)
num39 = np.array([R * C * Vdc, 2 * Vdc])
den39 = np.array([L * R * C * Dp, L * Dp, R * Dp ** 3])
describe("Eq. 39 evaluated (correct)", num39, den39)
describe("same TF divided by 80 (the paper's apparent normalisation)", num39 / 80, den39 / 80)
describe("Eq. 40 AS PRINTED", P.EQ40_NUM, P.EQ40_DEN)
say("  -> Eq. 40 again divides only some coefficients by 80: DC gain becomes 1600 A/duty instead of 20.")

say()
say("=" * 78)
say("4) Inductor current -> output voltage  v/i_L  (Eq. 41)")
say("=" * 78)
# correct: Gvd/Gid  = (R(1-D)^2 - sL) / ((1-D)(2 + sRC))
numvi = np.array([-L, R * Dp ** 2])
denvi = np.array([Dp * R * C, Dp * 2])
describe("Gvd/Gid from Eqs. 31 and 39 (correct, after cancellation)", numvi, denvi)
describe("Printed numeric expression after Eq. 41", P.EQ41_NUM, P.EQ41_DEN)
chk_n = np.polymul(P.EQ32_NUM, P.EQ40_DEN)
chk_d = np.polymul(P.EQ40_NUM, P.EQ32_DEN)
say(f"  -> printed expression = Eq.32 / Eq.40 multiplied out without cancelling:")
say(f"     Eq32num*Eq40den = {np.array2string(chk_n, precision=4)}")
say(f"     Eq40num*Eq32den = {np.array2string(chk_d, precision=4)}")

say()
say("=" * 78)
say("5) Reference model (Eqs. 45-50, Table 8, Eq. 51)")
say("=" * 78)
Rmin, Dr = P.REF_RMIN, P.REF_D
ILmax = P.VOUT ** 2 / (Rmin * Vdc)
dIL = 0.2 * ILmax
Lr = Vdc * Dr / (P.FSW * dIL)
dV = 0.04 * P.VOUT
Cr = Vdc * Dr / (Rmin * P.FSW * dV * (1 - Dr))
say(f"  I_L,avg,max = {ILmax:.3f} A (Table 8: 8)   dI_L = {dIL:.3f} A (1.6)   L = {Lr*1e3:.4f} mH (0.3125)")
say(f"  dV_out = {dV:.3f} V (1.6)   C = {Cr*1e6:.2f} uF (62.5)")
Drp = 1 - Dr
num51 = np.array([-Lr * Vdc, Rmin * Vdc * Drp ** 2])
den51 = np.array([Lr * Rmin * Cr * Drp ** 2, Lr * Drp ** 2, Rmin * Drp ** 4])
describe("Eq. 31 with Table 8 values (correct reference plant)", num51, den51)
describe("Eq. 51 AS PRINTED", P.EQ51_NUM, P.EQ51_DEN)
say("  -> denominator and DC gain match; printed numerator s-coefficient is 10x too large")
say("     (-0.0625 instead of -0.00625): RHP zero at 800 rad/s instead of 8 000 rad/s.")

say()
say("=" * 78)
say("6) Controllers")
say("=" * 78)
for name, g in [("single PI Eq.33", P.PI_SINGLE), ("outer PI Eq.42", P.PI_OUTER),
                ("inner PI Eq.43", P.PI_INNER), ("reference PI Eq.52", P.EQ52)]:
    say(f"  {name:20s} Kp = {g['Kp']:<10g} Ki = {g['Ki']:<8g}  PI zero at {g['Ki']/g['Kp']:.4g} rad/s")
say("  Paper text: inner-loop bandwidth chosen 10x the outer loop. Check (high-frequency asymptote")
say("  i_L/d ~ Vout/(sL) = %.3g/s):  inner crossover ~ Kp_i*Vout/L = %.3g rad/s (= %.1f kHz)"
    % (P.VOUT / L, P.PI_INNER['Kp'] * P.VOUT / L, P.PI_INNER["Kp"] * P.VOUT / L / 2 / np.pi / 1e3))
say("  -> that is above the 20 kHz switching frequency, i.e. not realisable with 20 kHz PWM.")

with open(os.path.join(OUT, "equation_check.txt"), "w") as f:
    f.write("\n".join(lines))
print("\nsaved results/tables/equation_check.txt")
