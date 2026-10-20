"""
Numbers exactly as printed in:
C. Yanarates and Z. Zhou, "Design and Cascade PI Controller-Based Robust Model
Reference Adaptive Control of DC-DC Boost Converter", IEEE Access, vol. 10,
pp. 44909-44922, 2022, doi:10.1109/ACCESS.2022.3169591.
"""

# ---- Table 3: design parameters of the boost converter -------------------- #
VDC = 20.0          # input voltage [V]
FSW = 20e3          # switching frequency [Hz]
L = 100e-6          # inductance [H]
C = 440e-6          # output capacitance [F]
VOUT = 40.0         # output voltage [V]
R = 16.0            # load resistance [Ohm]
D = 1 - VDC / VOUT  # Eq. (1) -> 0.5

TS = 1 / (10 * FSW)  # controller / discretisation sample time (Sec. IV-C, IV-E)
PERTURB_AMP = 0.03   # sinusoidal duty perturbation used for FR estimation (Sec. II-A)

# ---- Eq. (2): TF "estimated" with Simulink Control Design ----------------- #
EQ2_NUM = [-1.018e06, 4.821e08]
EQ2_DEN = [1.0, 1.302e04, 6.307e06]

# ---- Eq. (32): state-space averaging TF, as printed ----------------------- #
EQ32_NUM = [-0.002, 1.0]
EQ32_DEN = [2.2e-09, 2.5e-05, 0.0125]

# ---- Eq. (40): duty -> inductor current, as printed ----------------------- #
EQ40_NUM = [0.00176, 40.0]
EQ40_DEN = [4.4e-09, 5e-05, 0.025]

# ---- un-numbered Eq. after (41): inductor current -> output voltage ------- #
EQ41_NUM = [-8.8e-12, -9.56e-08, 0.0, 0.025]
EQ41_DEN = [3.872e-12, 1.32e-07, 0.001022, 0.5]

# ---- Controllers ----------------------------------------------------------- #
PI_SINGLE = dict(Kp=0.0114, Ki=2.82)      # Eq. (33)
PI_OUTER = dict(Kp=0.15, Ki=1000.0)       # Eq. (42)
PI_INNER = dict(Kp=0.5, Ki=5.0)           # Eq. (43)
GAMMA_DESIGN = 0.04                       # learning rate used for comparisons
GAMMAS_STUDY = (0.1, 0.5, 1.0)            # Figs. 13-15

# ---- Table 8 + Eqs. (51), (52): reference model --------------------------- #
REF_RMIN = 10.0
REF_D = 0.5
REF_IL_AVG_MAX = 8.0
REF_DIL = 1.6
REF_L = 0.3125e-3
REF_DVOUT = 1.6
REF_C = 62.5e-6
EQ51_NUM = [-0.0625, 50.0]
EQ51_DEN = [4.88e-08, 7.813e-05, 0.625]
EQ52 = dict(Kp=0.000005, Ki=7.5)

# ---- Table 6: open-loop step characteristics ------------------------------ #
TABLE6 = {
    "Simulink Control Design (Eq. 2)": dict(RiseTime=0.0044, SettlingTime=0.0081,
        SettlingMin=68.8104, SettlingMax=76.4336, Overshoot=0.0, Undershoot=85.1766,
        Peak=76.4336, PeakTime=0.0305),
    "State-space averaging (Eq. 32)": dict(RiseTime=0.0042, SettlingTime=0.0078,
        SettlingMin=72.0324, SettlingMax=79.9377, Overshoot=0.0, Undershoot=81.2702,
        Peak=79.9377, PeakTime=0.0151),
}

# ---- Table 10: closed-loop step characteristics ---------------------------- #
TABLE10 = {
    "Single PI": dict(RiseTime=5.9e-4, SettlingTime=0.0079, SettlingMin=33.69,
        SettlingMax=40.164, Overshoot=0.41, Undershoot=3.16, Peak=40.164, PeakTime=0.001),
    "Cascade PI": dict(RiseTime=0.0012, SettlingTime=0.0064, SettlingMin=37.564,
        SettlingMax=44.697, Overshoot=11.7425, Undershoot=0.1, Peak=44.697, PeakTime=0.0028),
    "Cascade PI-MRAC": dict(RiseTime=0.0014, SettlingTime=0.00145, SettlingMin=39.7,
        SettlingMax=41.485, Overshoot=3.7125, Undershoot=0.0, Peak=41.485, PeakTime=0.0025),
}
