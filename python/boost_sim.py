"""
Simulation engine for the recreation of Yanarates & Zhou (IEEE Access 2022).

One core loop simulates
  plant      : 0 = large-signal averaged model (state-space averaging, Eqs. 3-9)
               1 = switching circuit model (PWM, MOSFET + diode, DCM capable)
  controller : 0 = open loop (duty profile)
               1 = single PI                       (Eq. 33, Fig. 8)
               2 = cascade PI                      (Eqs. 42-43, Fig. 9)
               3 = cascade PI-based MRAC           (Eqs. 44, 54-55, Fig. 10/12)
The controller is discrete with sample time Ts = 1/(10 fsw) (paper Sec. IV-C/E);
integrators use the  Ts*z/(z-1)  form written in Eqs. (44), (54), (55).

numba is used automatically when installed (≈100x faster); otherwise plain
Python is used (a 0.6 s run then takes a few seconds).
"""
import numpy as np

try:  # optional speed-up
    from numba import njit
    HAVE_NUMBA = True
except Exception:  # pragma: no cover
    HAVE_NUMBA = False

    def njit(*args, **kwargs):
        if len(args) == 1 and callable(args[0]):
            return args[0]
        return lambda f: f

import paper_values as P
from tftools import feedback_unity, series, c2d_tustin


# --------------------------------------------------------------------------- #
#  Parameter container
# --------------------------------------------------------------------------- #
def default_params(**over):
    """Circuit + control parameters. Parasitics default to zero (Table 3 lists
    none); see SIMSCAPE_DEFAULT_PARASITICS for the Simulink default devices."""
    p = dict(
        L=P.L, C=P.C, fsw=P.FSW, Ts=P.TS,
        rL=0.0, Ron=0.0, Vf=0.0, Rd=0.0,      # parasitics
        unidirectional=1,                     # 1: diode (DCM possible); 0: ideal bidirectional switch
        pwm_mode=0,                           # 0: carrier compared with u every Ts; 1: duty latched once per period
        nsub_avg=2,                           # RK4 sub-steps per Ts for the averaged plant
        hmax_sw=1e-6,                         # max RK4 step inside switching intervals
        dmin=0.0, dmax=0.9,                   # duty-cycle limiter (Fig. 19)
        anti_windup=0,                        # 0: none (Simulink PID default), 1: clamping
        fc_v=0.0, fc_i=0.0,                   # optional measurement low-pass [Hz] (0 = off)
        theta0=1.0,
        iL0=0.0, v0=0.0,                      # initial state (cold start by default)
    )
    p.update(over)
    return p


# Simscape Electrical (Specialized Power Systems) default device parameters:
# Mosfet block Ron = 0.1 ohm ; Diode block Ron = 1 mOhm, Vf = 0.8 V.
SIMSCAPE_DEFAULT_PARASITICS = dict(Ron=0.1, Rd=0.001, Vf=0.8, rL=0.0)


# --------------------------------------------------------------------------- #
#  Small-signal model of the averaged plant (with optional parasitics)
# --------------------------------------------------------------------------- #
def operating_point(p, Vin=P.VDC, R=P.R, D=P.D):
    Dp = 1 - D
    rs = p["rL"] + D * p["Ron"] + Dp * p["Rd"]
    V = (Vin - Dp * p["Vf"]) / (Dp + rs / (R * Dp))
    IL = V / (R * Dp)
    return IL, V


def averaged_linear_tf(p, Vin=P.VDC, R=P.R, D=P.D):
    """Linearise the averaged model at duty D. Returns (num_v, num_i, den, IL, V)
    with v/d = num_v/den and iL/d = num_i/den.  With zero parasitics this is
    exactly Eq. (31) and Eq. (39) of the paper."""
    from scipy.signal import ss2tf
    L_, C_ = p["L"], p["C"]
    IL, V = operating_point(p, Vin, R, D)
    Dp = 1 - D
    rs = p["rL"] + D * p["Ron"] + Dp * p["Rd"]
    A = np.array([[-rs / L_, -Dp / L_], [Dp / C_, -1 / (R * C_)]])
    B = np.array([[(-(p["Ron"] - p["Rd"]) * IL + V + p["Vf"]) / L_], [-IL / C_]])
    nv, den = ss2tf(A, B, np.array([[0.0, 1.0]]), np.zeros((1, 1)))
    ni, _ = ss2tf(A, B, np.array([[1.0, 0.0]]), np.zeros((1, 1)))
    return np.trim_zeros(nv[0], "f"), np.trim_zeros(ni[0], "f"), den, IL, V


def duty_for_vout(p, Vout, Vin=P.VDC, R=P.R):
    """Duty that gives Vout in steady state (averaged model with parasitics)."""
    from scipy.optimize import brentq
    return brentq(lambda D: operating_point(p, Vin, R, D)[1] - Vout, 1e-6, 0.95)


# --------------------------------------------------------------------------- #
#  Reference model (Table 8, Eq. 51 plant + Eq. 52 PI, unity feedback)
# --------------------------------------------------------------------------- #
def reference_model_tf(variant="derived"):
    """Closed-loop reference model T_m(s).
    variant='derived' : Eq. 51 recomputed from Eq. 31 + Table 8 (num -0.00625 s + 50)
    variant='printed' : Eq. 51 exactly as printed (num -0.0625 s + 50) -> unstable loop
    """
    num51 = [-0.00625, 50.0] if variant == "derived" else list(P.EQ51_NUM)
    den51 = list(P.EQ51_DEN)
    numc = [P.EQ52["Kp"], P.EQ52["Ki"]]
    denc = [1.0, 0.0]
    nol, dol = series(numc, denc, num51, den51)
    return feedback_unity(nol, dol)


def reference_model_discrete(Ts, variant="derived"):
    n, d = reference_model_tf(variant)
    bz, az = c2d_tustin(n, d, Ts)
    # pad to equal length
    m = max(len(bz), len(az))
    bz = np.pad(bz, (m - len(bz), 0))
    az = np.pad(az, (m - len(az), 0))
    return bz.astype(np.float64), az.astype(np.float64)


# --------------------------------------------------------------------------- #
#  Core loop
# --------------------------------------------------------------------------- #
@njit(cache=False)
def _core(plant, ctrl, N, Ts, fsw, L, C, rL, Ron, Vf, Rd, uni, pwm_mode,
          nsub_avg, hmax, dmin, dmax, aw, av_v, av_i,
          Kp1, Ki1, Kp2, Ki2, gamma, theta0,
          vref, vin, rload, dol, bz, az,
          iL0, v0,
          o_v, o_i, o_d, o_th, o_ym, o_iref, o_vmeas, o_imeas, o_va, o_ia):
    iL = iL0
    v = v0
    I1 = 0.0          # integrator (single PI / outer PI)
    I2 = 0.0          # integrator inner PI
    th = theta0
    vm = v0           # filtered measurements
    im = iL0
    nz = bz.shape[0]
    zs = np.zeros(nz)  # reference-model filter state (DF-II transposed)
    ym = 0.0
    d_latched = 0.0
    nper = int(round(1.0 / (fsw * Ts)))   # control samples per switching period (10)

    for k in range(N):
        Vin = vin[k]
        Rl = rload[k]

        # -------- measurement (sampled at t_k) ---------------------------- #
        vm = vm + av_v * (v - vm)
        im = im + av_i * (iL - im)

        # -------- reference model ---------------------------------------- #
        r = vref[k]
        ym = bz[0] * r + zs[0]
        for j in range(nz - 2):
            zs[j] = bz[j + 1] * r - az[j + 1] * ym + zs[j + 1]
        zs[nz - 2] = bz[nz - 1] * r - az[nz - 1] * ym

        # -------- controller ---------------------------------------------- #
        iref = 0.0
        if ctrl == 0:
            u = dol[k]
        elif ctrl == 1:
            e = r - vm
            I1_new = I1 + Ki1 * Ts * e
            u = Kp1 * e + I1_new
            if aw == 1 and ((u > dmax and e > 0.0) or (u < dmin and e < 0.0)):
                u = Kp1 * e + I1
            else:
                I1 = I1_new
        else:
            # outer-loop set-point: V_ref (as in Eq. 54 / Fig. 12) or, for the
            # model-following variant (ctrl 4), the reference-model output
            e = (ym - vm) if ctrl == 4 else (r - vm)
            I1 = I1 + Ki1 * Ts * e
            iref = Kp1 * e + I1
            ei = iref - im
            I2_new = I2 + Ki2 * Ts * ei
            upi = Kp2 * ei + I2_new
            if ctrl >= 3:
                et = vm - ym                          # tracking error, Eq. (56)
                th = th - gamma * Ts * et * ym        # MIT rule, Eqs. (44)/(55)
                u = th * upi                          # adjusted control signal
            else:
                u = upi
            sat = (u > dmax and ei * (1.0 if ctrl == 2 else th) > 0.0) or \
                  (u < dmin and ei * (1.0 if ctrl == 2 else th) < 0.0)
            if aw == 1 and sat:
                upi = Kp2 * ei + I2
                u = upi if ctrl == 2 else th * upi
            else:
                I2 = I2_new
        d = u
        if d > dmax:
            d = dmax
        if d < dmin:
            d = dmin

        o_v[k] = v
        o_i[k] = iL
        o_d[k] = d
        o_th[k] = th
        o_ym[k] = ym
        o_iref[k] = iref
        o_vmeas[k] = vm
        o_imeas[k] = im

        # -------- plant over [t_k, t_k + Ts] ------------------------------- #
        if plant == 0:
            h = Ts / nsub_avg
            dp = 1.0 - d
            rs = rL + d * Ron + dp * Rd
            sv = 0.0
            si = 0.0
            for s in range(nsub_avg):
                iold = iL
                vold = v
                # RK4 on the averaged model
                k1i = (Vin - rs * iL - dp * (v + Vf)) / L
                k1v = (dp * iL - v / Rl) / C
                if uni == 1 and iL <= 0.0 and k1i < 0.0:
                    k1i = 0.0
                i2_ = iL + 0.5 * h * k1i
                v2_ = v + 0.5 * h * k1v
                k2i = (Vin - rs * i2_ - dp * (v2_ + Vf)) / L
                k2v = (dp * i2_ - v2_ / Rl) / C
                if uni == 1 and i2_ <= 0.0 and k2i < 0.0:
                    k2i = 0.0
                i3_ = iL + 0.5 * h * k2i
                v3_ = v + 0.5 * h * k2v
                k3i = (Vin - rs * i3_ - dp * (v3_ + Vf)) / L
                k3v = (dp * i3_ - v3_ / Rl) / C
                if uni == 1 and i3_ <= 0.0 and k3i < 0.0:
                    k3i = 0.0
                i4_ = iL + h * k3i
                v4_ = v + h * k3v
                k4i = (Vin - rs * i4_ - dp * (v4_ + Vf)) / L
                k4v = (dp * i4_ - v4_ / Rl) / C
                if uni == 1 and i4_ <= 0.0 and k4i < 0.0:
                    k4i = 0.0
                iL = iL + h / 6.0 * (k1i + 2 * k2i + 2 * k3i + k4i)
                v = v + h / 6.0 * (k1v + 2 * k2v + 2 * k3v + k4v)
                if uni == 1 and iL < 0.0:
                    iL = 0.0
                sv += 0.5 * h * (vold + v)
                si += 0.5 * h * (iold + iL)
            o_va[k] = sv / Ts
            o_ia[k] = si / Ts
        else:
            # PWM: trailing-edge sawtooth carrier 0->1 over each period
            kk = k % nper
            if kk == 0:
                d_latched = d
            upwm = d if pwm_mode == 0 else d_latched
            c0 = kk / nper
            frac = (upwm - c0) * nper
            if frac < 0.0:
                frac = 0.0
            if frac > 1.0:
                frac = 1.0
            ton = frac * Ts
            sv = 0.0
            si = 0.0
            for piece in range(2):
                T = ton if piece == 0 else Ts - ton
                if T <= 0.0:
                    continue
                on = piece == 0
                ns = int(np.ceil(T / hmax))
                h = T / ns
                for s in range(ns):
                    iold = iL
                    vold = v
                    if on:
                        # switch closed: L and C decoupled
                        k1i = (Vin - (rL + Ron) * iL) / L
                        k1v = -v / (Rl * C)
                        k2i = (Vin - (rL + Ron) * (iL + 0.5 * h * k1i)) / L
                        k2v = -(v + 0.5 * h * k1v) / (Rl * C)
                        k3i = (Vin - (rL + Ron) * (iL + 0.5 * h * k2i)) / L
                        k3v = -(v + 0.5 * h * k2v) / (Rl * C)
                        k4i = (Vin - (rL + Ron) * (iL + h * k3i)) / L
                        k4v = -(v + h * k3v) / (Rl * C)
                        iL = iL + h / 6.0 * (k1i + 2 * k2i + 2 * k3i + k4i)
                        v = v + h / 6.0 * (k1v + 2 * k2v + 2 * k3v + k4v)
                    else:
                        # switch open: diode conducts unless blocked (DCM)
                        if uni == 1 and iL <= 0.0 and (Vin - Vf - v) <= 0.0:
                            iL = 0.0
                            v = v * np.exp(-h / (Rl * C))
                            sv += 0.5 * h * (vold + v)
                            continue
                        vf_ = Vf if uni == 1 else 0.0
                        rd_ = Rd if uni == 1 else 0.0
                        k1i = (Vin - (rL + rd_) * iL - vf_ - v) / L
                        k1v = (iL - v / Rl) / C
                        i2_ = iL + 0.5 * h * k1i
                        v2_ = v + 0.5 * h * k1v
                        k2i = (Vin - (rL + rd_) * i2_ - vf_ - v2_) / L
                        k2v = (i2_ - v2_ / Rl) / C
                        i3_ = iL + 0.5 * h * k2i
                        v3_ = v + 0.5 * h * k2v
                        k3i = (Vin - (rL + rd_) * i3_ - vf_ - v3_) / L
                        k3v = (i3_ - v3_ / Rl) / C
                        i4_ = iL + h * k3i
                        v4_ = v + h * k3v
                        k4i = (Vin - (rL + rd_) * i4_ - vf_ - v4_) / L
                        k4v = (i4_ - v4_ / Rl) / C
                        iL = iL + h / 6.0 * (k1i + 2 * k2i + 2 * k3i + k4i)
                        v = v + h / 6.0 * (k1v + 2 * k2v + 2 * k3v + k4v)
                        if uni == 1 and iL < 0.0:
                            iL = 0.0
                    sv += 0.5 * h * (vold + v)
                    si += 0.5 * h * (iold + iL)
            o_va[k] = sv / Ts
            o_ia[k] = si / Ts
    # final state (end of the last interval) is stored in element N
    o_v[N] = v
    o_i[N] = iL
    return 0


# --------------------------------------------------------------------------- #
#  Python front end
# --------------------------------------------------------------------------- #
PLANTS = {"average": 0, "switching": 1}
CTRLS = {"open": 0, "pi": 1, "cascade": 2, "mrac": 3, "mrac_ms": 4}


def piecewise(t, times, values):
    """Piecewise-constant profile: values[j] for t >= times[j]."""
    out = np.full_like(t, values[0], dtype=float)
    for tj, vj in zip(times, values):
        out[t >= tj] = vj
    return out


def simulate(T_end, plant="average", ctrl="mrac", params=None,
             vref=40.0, vin=P.VDC, rload=P.R, duty=0.5,
             gamma=P.GAMMA_DESIGN, gains=None, ref_variant="derived"):
    """
    Run one simulation.  vref / vin / rload / duty may be scalars, callables f(t)
    or arrays already sampled at Ts.  Returns a dict of numpy arrays.
    """
    p = default_params() if params is None else params
    Ts = p["Ts"]
    N = int(round(T_end / Ts))
    t = np.arange(N) * Ts

    def prof(x):
        if callable(x):
            return np.asarray(x(t), float)
        x = np.asarray(x, float)
        return np.full(N, float(x)) if x.ndim == 0 else x[:N].astype(float)

    if gains is None:
        if ctrl == "pi":
            gains = (P.PI_SINGLE["Kp"], P.PI_SINGLE["Ki"], 0.0, 0.0)
        else:
            gains = (P.PI_OUTER["Kp"], P.PI_OUTER["Ki"], P.PI_INNER["Kp"], P.PI_INNER["Ki"])
    bz, az = reference_model_discrete(Ts, ref_variant)

    av_v = 1.0 - np.exp(-2 * np.pi * p["fc_v"] * Ts) if p["fc_v"] > 0 else 1.0
    av_i = 1.0 - np.exp(-2 * np.pi * p["fc_i"] * Ts) if p["fc_i"] > 0 else 1.0

    outs = [np.zeros(N + 1) for _ in range(10)]
    _core(PLANTS[plant], CTRLS[ctrl], N, Ts, p["fsw"], p["L"], p["C"],
          p["rL"], p["Ron"], p["Vf"], p["Rd"], int(p["unidirectional"]), int(p["pwm_mode"]),
          int(p["nsub_avg"]), p["hmax_sw"], p["dmin"], p["dmax"], int(p["anti_windup"]),
          av_v, av_i, float(gains[0]), float(gains[1]), float(gains[2]), float(gains[3]),
          float(gamma), p["theta0"], prof(vref), prof(vin), prof(rload), prof(duty),
          bz, az, p["iL0"], p["v0"], *outs)
    names = ["v", "iL", "d", "theta", "ym", "iref", "v_meas", "i_meas", "v_avg", "iL_avg"]
    res = {nm: o[:N] for nm, o in zip(names, outs)}
    res["x_end"] = (outs[1][N], outs[0][N])   # (iL, v) at t = T_end
    res["t"] = t
    res["vref"] = prof(vref)
    res["vin"] = prof(vin)
    res["rload"] = prof(rload)
    return res
