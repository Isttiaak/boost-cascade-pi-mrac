"""
Scenarios and metrics shared by every implementation of the recreation:
Python (this folder), the MATLAB scripts (matlab/) and the Simulink models
(simulink/).  The MATLAB twin is simulink/scenario_list.m and
simulink/scenario_metrics.m - keep the three definitions identical.

Signals are compared at the controller sample instants t_k = k*Ts,
k = 0 .. N-1, N = round(T/Ts).  A window [t0, t1) is the index range
round(t0/Ts) .. round(t1/Ts)-1.
"""
import numpy as np

from tftools import stepinfo

TS = 5e-6                  # controller sample time 1/(10 fsw)
NEVER = (1e3, 2e3)         # switching times that never occur
CTRLS = ["pi", "cascade", "mrac", "mrac_mf"]

TABLE10_KEYS = ["RiseTime", "SettlingTime", "SettlingMin", "SettlingMax",
                "Overshoot", "Peak", "PeakTime"]
EXP_KEYS = ["RiseTime", "SettlingTime", "Overshoot", "Peak", "PeakTime"]


def scenario_list():
    S = []
    base = dict(gamma=0.04, vref=([40, 40, 40], NEVER), vin=([20, 20, 20], NEVER),
                rload=([16, 16, 16], NEVER), duty=0.5, iL_min=0.0)

    def add(**kw):
        s = dict(base)
        s.update(kw)
        S.append(s)

    # Fig. 7: open loop, D = 0.5, cold start
    add(name="ol_diode", ctrl="open", T=0.05)                      # circuit with diode
    add(name="ol_bidir", ctrl="open", T=0.05, iL_min=-np.inf)      # Fig. 6 as drawn
    # Figs. 13-15: learning rates
    for g in (0.1, 0.5, 1.0):
        add(name=f"lr_g{g:g}", ctrl="mrac", T=0.6, gamma=g, vref=([30, 40, 50], (0.2, 0.4)))
    for c in CTRLS:
        # Fig. 16: load 16 -> 10 -> 20 Ohm
        add(name=f"f16_{c}", ctrl=c, T=0.5, rload=([16, 10, 20], (0.2, 0.4)))
        # Fig. 17: same loads and Vin 15 -> 25 V
        add(name=f"f17_{c}", ctrl=c, T=0.5, rload=([16, 10, 20], (0.2, 0.4)),
            vin=([15, 25, 25], (0.2, 1e3)))
        # Fig. 18 and Table 10: reference 30 -> 40 -> 50 V
        add(name=f"f18_{c}", ctrl=c, T=0.5, vref=([30, 40, 50], (0.2, 0.4)))
        # Figs. 22-24 in simulation: reference 25 -> 40 V
        add(name=f"exp_{c}", ctrl=c, T=0.2, vref=([25, 40, 40], (0.1, 1e3)))
    return S


def profile_array(spec, N, Ts=TS):
    """x(k) = v1 for k < k1, v2 for k1 <= k < k2, v3 for k >= k2."""
    vals, times = spec
    k = np.arange(N)
    k1, k2 = (int(round(t / Ts)) for t in times)
    v = np.asarray(vals, float)
    return v[0] + (v[1] - v[0]) * (k >= k1) + (v[2] - v[1]) * (k >= k2)


def _win(t0, t1, Ts=TS):
    return slice(int(round(t0 / Ts)), int(round(t1 / Ts)))


def scenario_metrics(name, t, v, iL=None, theta=None, ym=None, Ts=TS):
    """Metrics of one run. Returns an ordered dict {metric: value}."""
    kind = name.split("_")[0]
    out = {}
    v = np.asarray(v, float)
    t = np.asarray(t, float)
    if kind == "ol":
        w = _win(0, 0.05, Ts)
        k = int(np.argmax(v[w]))
        out["peak"] = v[w][k]
        out["tpeak"] = t[w][k]
        e = _win(0.04, 0.05, Ts)
        out["vmean_end"] = v[e].mean()
        out["ripple_end"] = 0.5 * (v[e].max() - v[e].min())
    elif kind == "lr":
        for tq in (0.199, 0.399, 0.599):
            out[f"theta_t{int(round(tq * 1000)):04d}"] = theta[int(round(tq / Ts))]
        tail = _win(0.5, 0.6, Ts)
        out["vmin_tail"] = v[tail].min()
        out["vmax_tail"] = v[tail].max()
        s = _win(0.2, 0.215, Ts)
        e = v[s] - ym[s]
        out["emax_step"] = e.max()
        out["emin_step"] = e.min()
    elif kind in ("f16", "f17"):
        w = _win(0, 0.03, Ts)
        k = int(np.argmax(v[w]))
        out["su_peak"] = v[w][k]
        out["su_tpeak"] = t[w][k]
        out["su_min"] = v[k:_win(0, 0.05, Ts).stop].min()
        if kind == "f16":
            s = _win(0.2, 0.215, Ts)
            out["ls_min"] = v[s].min()
            out["ls_max"] = v[s].max()
            o = _win(0.15, 0.2, Ts)
        else:
            s = _win(0.2, 0.25, Ts)
            out["vs_min"] = v[s].min()
            out["vs_max"] = v[s].max()
            o = _win(0.45, 0.5, Ts)
        out["osc_amp"] = 0.5 * (v[o].max() - v[o].min())
    elif kind == "f18":
        s = _win(0.2, 0.4, Ts)
        info = stepinfo(t[s] - 0.2, v[s], yfinal=40.0, yinit=0.0)      # Table 10 definitions
        for key in TABLE10_KEYS:
            out[key] = info[key]
        out["step3_peak"] = v[_win(0.4, 0.45, Ts)].max()
    elif kind == "exp":
        s = _win(0.1, 0.2, Ts)
        info = stepinfo(t[s] - 0.1, v[s], yfinal=40.0, yinit=25.0, settle_ref="final")
        for key in EXP_KEYS:
            out[key] = info[key]
    else:
        raise ValueError(name)
    return out
