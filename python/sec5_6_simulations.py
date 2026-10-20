"""
Recreation of Sections V-VI (closed-loop simulations):

  Figs. 13-15  learning-rate study of the cascade PI-based MRAC (gamma = 0.1, 0.5, 1)
  Fig. 16      controllers under load steps
  Fig. 17      controllers under load and input-voltage steps
  Fig. 18      controllers under reference steps
  Table 10     step-response characteristics
  Figs. 22-24  simulated version of the experimental 25 V -> 40 V reference step
  extra        sensitivity of the single PI to small circuit losses

Plant: switching boost converter with Table 3 values, ideal switch and diode
(DCM possible), cold start. Controllers sampled at Ts = 1/(10 fsw) = 5 us; the
PWM carrier is compared with the control signal every Ts.

Run:  python sec5_6_simulations.py
"""
import csv
import os
import numpy as np
import matplotlib.pyplot as plt

import paper_values as P
from boost_sim import simulate, default_params, piecewise, SIMSCAPE_DEFAULT_PARASITICS
from tftools import stepinfo
from plotstyle import (save, inset, C1, C2, C3, INK2, MUTED, TAB_DIR, CTRL_COLORS, CTRL_LABELS)

# "mrac"    : Eqs. 44/54/55 and Fig. 12 as written (outer-loop error = V_ref - V_out)
# "mrac_ms" : same adaptation, but the cascade tracks the reference-model output
#             V_ref(out) (model-following set-point). Not described in the paper,
#             but it is the variant that reproduces the paper's Table 10 / Figs 16-18.
CTRLS_CMP = ["pi", "cascade", "mrac", "mrac_ms"]
LS = {"pi": "-", "cascade": "-", "mrac": "-", "mrac_ms": (0, (4, 2))}

PLANT = "switching"
PARAMS = default_params()            # Table 3 values, ideal devices
CTRLS = ["pi", "cascade", "mrac"]
NPER = int(round(1 / (P.FSW * P.TS)))  # samples per switching period


def period_avg(x):
    """Moving average over one switching period (removes the PWM ripple)."""
    k = np.ones(NPER) / NPER
    return np.convolve(x, k, mode="same")


def run(ctrl, T, **kw):
    return simulate(T, plant=PLANT, ctrl=ctrl, params=PARAMS, **kw)


# --------------------------------------------------------------------------- #
#  Scenarios
# --------------------------------------------------------------------------- #
VREF_STEPS = lambda t: piecewise(t, [0, 0.2, 0.4], [30.0, 40.0, 50.0])
LOAD_STEPS = lambda t: piecewise(t, [0, 0.2, 0.4], [16.0, 10.0, 20.0])
VIN_STEPS = lambda t: piecewise(t, [0, 0.2], [15.0, 25.0])


def learning_rate_study():
    print(" learning-rate study (Figs. 13-15)")
    gammas = P.GAMMAS_STUDY
    cols = [C1, C2, C3]
    res = {g: run("mrac", 0.6, vref=VREF_STEPS, gamma=g) for g in gammas}

    # Fig. 13 tracking error
    fig, ax = plt.subplots(figsize=(8.6, 4.4))
    for g, c in zip(gammas, cols):
        r = res[g]
        ax.plot(r["t"], r["v"] - r["ym"], color=c, lw=0.8, label=f"γ = {g:g}")
    ax.set(xlabel="Time (s)", ylabel="Tracking error e = V_out − V_ref(out) (V)", xlim=(0, 0.6), ylim=(-15, 15))
    ax.legend(loc="upper left", ncol=3)
    t = res[gammas[0]]["t"]
    m = (t >= 0.2) & (t <= 0.215)
    inset(ax, [0.09, 0.06, 0.38, 0.32], (0.2, 0.215), (-6, 8),
          [(t[m], res[g]["v"][m] - res[g]["ym"][m], dict(color=c, lw=0.9)) for g, c in zip(gammas, cols)])
    ax.set_title("Fig. 13 recreated - tracking error for varying learning rates")
    save(fig, "fig13_tracking_error_learning_rates.png")

    # Fig. 14 adaptation parameter
    fig, ax = plt.subplots(figsize=(8.6, 4.0))
    for g, c in zip(gammas, cols):
        r = res[g]
        m = (r["t"] >= 0.19) & (r["t"] <= 0.26)
        ax.plot(r["t"][m], r["theta"][m], color=c, lw=1.2, label=f"γ = {g:g}")
    ax.set(xlabel="Time (s)", ylabel="Adaptation parameter θ", xlim=(0.19, 0.26))
    ax.legend(loc="upper right", ncol=3)
    ax.set_title("Fig. 14 recreated - adaptation parameter θ around the 30→40 V step at 0.2 s")
    save(fig, "fig14_theta_learning_rates.png")

    # Fig. 15 output voltage
    fig, ax = plt.subplots(figsize=(8.6, 4.4))
    for g, c in zip(gammas, cols):
        r = res[g]
        m = r["t"] >= 0.1
        ax.plot(r["t"][m], r["v"][m], color=c, lw=0.8, label=f"γ = {g:g}")
    ax.set(xlabel="Time (s)", ylabel="Plant output voltage (V)", xlim=(0.1, 0.6), ylim=(25, 80))
    ax.legend(loc="lower right", ncol=3)
    m = (t >= 0.4) & (t <= 0.42)
    inset(ax, [0.06, 0.52, 0.42, 0.44], (0.4, 0.42), (38, 70),
          [(t[m], res[g]["v"][m], dict(color=c, lw=0.9)) for g, c in zip(gammas, cols)])
    ax.set_title("Fig. 15 recreated - plant output voltage for varying learning rates")
    save(fig, "fig15_output_voltage_learning_rates.png")

    rows = []
    for g in gammas:
        r = res[g]
        th = r["theta"]
        tt = r["t"]
        def mean_in(a, b, x):
            mm = (tt >= a) & (tt < b)
            return x[mm].mean(), x[mm].min(), x[mm].max()
        rows.append([g, *[f"{mean_in(a, b, th)[0]:.3f}" for a, b in [(0.18, 0.2), (0.38, 0.4), (0.58, 0.6)]],
                     "[%.1f, %.1f]" % mean_in(0.5, 0.6, r["v"])[1:]])
    with open(os.path.join(TAB_DIR, "fig13_15_learning_rate_summary.csv"), "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["gamma", "theta before 0.2 s", "theta before 0.4 s", "theta at 0.6 s",
                     "V_out range 0.5-0.6 s (ref 50 V)"])
        wr.writerows(rows)
    for row in rows:
        print("   gamma=%-4s theta: %s / %s / %s   V(0.5-0.6 s) %s" % tuple(row))
    return res


def comparison(name, title, fname, T, insets, ylim=(0, 55), **profiles):
    print(f" {name}")
    res = {c: run(c, T, gamma=P.GAMMA_DESIGN, **profiles) for c in CTRLS_CMP}
    fig, ax = plt.subplots(figsize=(9.2, 4.8))
    for c in CTRLS_CMP:
        r = res[c]
        ax.plot(r["t"], r["v"], color=CTRL_COLORS[c], ls=LS[c], lw=0.9, label=CTRL_LABELS[c])
    ax.set(xlabel="Time (s)", ylabel="Output voltage (V)", xlim=(0, T), ylim=ylim)
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.13), ncol=2, frameon=False)
    t = res["pi"]["t"]
    for bounds, xl, yl in insets:
        m = (t >= xl[0]) & (t <= xl[1])
        inset(ax, bounds, xl, yl, [(t[m], res[c]["v"][m], dict(color=CTRL_COLORS[c], ls=LS[c], lw=0.9))
                                   for c in CTRLS_CMP])
    ax.set_title(title)
    save(fig, fname)
    return res


def metrics_table(res_ref):
    """Table 10 recreation: 30 V -> 40 V reference step at t = 0.2 s, evaluated
    like MATLAB stepinfo on the raw output signal with its defaults (yinit = 0,
    yfinal = 40 V, so overshoot is a percentage of 40 V). With this definition the
    paper's cascade-PI column is reproduced almost exactly."""
    keys = ["RiseTime", "SettlingTime", "SettlingMin", "SettlingMax", "Overshoot", "Undershoot",
            "Peak", "PeakTime"]
    out = []
    for c in CTRLS_CMP:
        r = res_ref[c]
        t, v = r["t"], r["v"]
        m = (t >= 0.2) & (t < 0.4)
        info = stepinfo(t[m] - 0.2, v[m], yfinal=40.0, yinit=0.0)
        tail = (t > 0.35) & (t < 0.4)
        amp = 0.5 * (period_avg(v)[tail].max() - period_avg(v)[tail].min())
        out.append((c, info, amp))
    with open(os.path.join(TAB_DIR, "table10_closed_loop_step.csv"), "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["Source", "Controller"] + keys + ["Residual oscillation amplitude (V)"])
        for name, P10 in P.TABLE10.items():
            wr.writerow(["PAPER Table 10", name] + [P10[k] for k in keys] + [""])
        for c, info, amp in out:
            wr.writerow(["Recreated (30->40 V step at 0.2 s)", CTRL_LABELS[c]] +
                        [f"{info[k]:.5g}" for k in keys] + [f"{amp:.3f}"])
    print(" Table 10 recreated (30 -> 40 V step, MATLAB stepinfo defaults, raw signal):")
    for c, info, amp in out:
        print(f"   {CTRL_LABELS[c]:42s} " + "  ".join(f"{k}={info[k]:.4g}" for k in keys) +
              f"  osc=±{amp:.2f} V")
    return out


def experiment_like():
    """Simulated version of the experimental test of Figs. 22-24 (25 V -> 40 V)."""
    print(" simulated experiment 25 V -> 40 V (Figs. 22-24)")
    vref = lambda t: piecewise(t, [0, 0.1], [25.0, 40.0])
    res = {c: run(c, 0.2, vref=vref, gamma=P.GAMMA_DESIGN) for c in CTRLS_CMP}
    fig, axs = plt.subplots(2, 4, figsize=(14, 5.2), sharex=True)
    rows = []
    for j, c in enumerate(CTRLS_CMP):
        r = res[c]
        t = r["t"]
        m = (t >= 0.09) & (t <= 0.14)
        axs[0, j].plot((t[m] - 0.1) * 1e3, r["v"][m], color=CTRL_COLORS[c], lw=0.9)
        axs[1, j].plot((t[m] - 0.1) * 1e3, r["iL"][m], color=CTRL_COLORS[c], lw=0.6)
        axs[0, j].set_title(CTRL_LABELS[c].replace(", ", ",\n"), fontsize=9.5)
        axs[0, j].set_ylim(20, 50)
        axs[1, j].set_ylim(-1, 45)
        axs[1, j].set_xlabel("Time after reference step (ms)")
        v = period_avg(r["v"])
        mm = (t >= 0.1) & (t < 0.2 - NPER * P.TS)
        info = stepinfo(t[mm] - 0.1, v[mm], yfinal=40.0, yinit=25.0)
        rows.append((c, info))
    axs[0, 0].set_ylabel("Output voltage (V)")
    axs[1, 0].set_ylabel("Inductor current (A)")
    fig.suptitle("Figs. 22-24 recreated in simulation - reference step 25 V → 40 V",
                 fontsize=10.5, fontweight="bold")
    fig.tight_layout()
    save(fig, "fig22_24_simulated_experiment.png")
    with open(os.path.join(TAB_DIR, "fig22_24_simulated_experiment.csv"), "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["Controller", "RiseTime (s)", "SettlingTime (s)", "Overshoot (%)", "Undershoot (%)"])
        for c, info in rows:
            wr.writerow([CTRL_LABELS[c], f"{info['RiseTime']:.5g}", f"{info['SettlingTime']:.5g}",
                         f"{info['Overshoot']:.3g}", f"{info['Undershoot']:.3g}"])
    for c, info in rows:
        print(f"   {CTRL_LABELS[c]:22s} rise {info['RiseTime']*1e3:.2f} ms, settling "
              f"{info['SettlingTime']*1e3:.2f} ms, overshoot {info['Overshoot']:.1f} %")
    return res


def single_pi_sensitivity():
    """Single PI with lossless devices vs Simulink default device parameters."""
    print(" single-PI sensitivity to device losses")
    p_loss = default_params(**SIMSCAPE_DEFAULT_PARASITICS)
    r0 = run("pi", 0.5, vref=VREF_STEPS)
    r1 = simulate(0.5, plant=PLANT, ctrl="pi", params=p_loss, vref=VREF_STEPS)
    fig, ax = plt.subplots(figsize=(9.2, 4.2))
    ax.plot(r0["t"], r0["v"], color=C1, lw=0.8, label="Lossless switch and diode (Table 3 only)")
    ax.plot(r1["t"], r1["v"], color=C2, lw=0.8,
            label="Simulink default devices (MOSFET Ron = 0.1 Ω, diode Vf = 0.8 V)")
    ax.set(xlabel="Time (s)", ylabel="Output voltage (V)", xlim=(0, 0.5), ylim=(0, 55))
    ax.legend(loc="lower right")
    t = r0["t"]
    m = (t >= 0.4) & (t <= 0.44)
    inset(ax, [0.36, 0.08, 0.36, 0.36], (0.4, 0.44), (44, 56),
          [(t[m], r0["v"][m], dict(color=C1, lw=0.9)), (t[m], r1["v"][m], dict(color=C2, lw=0.9))])
    ax.set_title("Single PI (Eq. 33) under reference steps: effect of small device losses")
    save(fig, "extra_single_pi_loss_sensitivity.png")
    for lbl, r in [("lossless", r0), ("default devices", r1)]:
        tt = r["t"]
        mm = (tt > 0.45) & (tt < 0.5)
        print(f"   {lbl:16s}: V in 0.45-0.5 s spans [{r['v'][mm].min():.2f}, {r['v'][mm].max():.2f}] V")


def main():
    print("Section V-VI recreation (plant: %s, Table 3, ideal devices)" % PLANT)
    learning_rate_study()
    res_load = comparison(
        "load steps (Fig. 16)",
        "Fig. 16 recreated - load steps 16 Ω → 10 Ω (0.2 s) → 20 Ω (0.4 s), V_ref = 40 V",
        "fig16_load_variation.png", 0.5,
        insets=[([0.13, 0.08, 0.3, 0.42], (0, 0.03), (24, 54)),
                ([0.55, 0.08, 0.3, 0.42], (0.2, 0.215), (36, 44))],
        vref=40.0, rload=LOAD_STEPS)
    comparison(
        "load + input-voltage steps (Fig. 17)",
        "Fig. 17 recreated - V_in 15 V → 25 V (0.2 s), load 16 → 10 Ω (0.2 s) → 20 Ω (0.4 s)",
        "fig17_load_and_input_variation.png", 0.5,
        insets=[([0.13, 0.08, 0.3, 0.42], (0, 0.05), (18, 54)),
                ([0.55, 0.08, 0.3, 0.42], (0.4, 0.43), (38, 44))],
        ylim=(0, 60), vref=40.0, rload=LOAD_STEPS, vin=VIN_STEPS)
    res_ref = comparison(
        "reference steps (Fig. 18)",
        "Fig. 18 recreated - reference steps 30 V → 40 V (0.2 s) → 50 V (0.4 s)",
        "fig18_reference_variation.png", 0.5,
        insets=[([0.10, 0.08, 0.25, 0.4], (0, 0.06), (18, 54)),
                ([0.40, 0.08, 0.25, 0.4], (0.2, 0.24), (28, 46)),
                ([0.71, 0.08, 0.25, 0.4], (0.4, 0.44), (38, 58))],
        ylim=(0, 60), vref=VREF_STEPS)
    metrics_table(res_ref)
    experiment_like()
    single_pi_sensitivity()


if __name__ == "__main__":
    main()
