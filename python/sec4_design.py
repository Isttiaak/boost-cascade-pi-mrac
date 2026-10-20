"""
Recreation of Section IV (controller and reference-model design):

  * controller transfer functions of Eqs. 33, 42, 43, 52 and their Tustin
    discretisation at Ts = 1/(10 fsw) (Eq. 53)
  * reference model: Table 8 recomputed, Eq. 51 derived vs. printed, closed-loop
    reference model T_m(s) and its step response
  * loop analysis of the paper's gains on the printed and on the correct plant
    models (closed-loop poles, margins, crossover frequencies)

Run:  python sec4_design.py
"""
import csv
import os
import numpy as np
import matplotlib.pyplot as plt

import paper_values as P
from boost_sim import default_params, averaged_linear_tf, reference_model_tf
from tftools import (tf_freq, mag_db, phase_deg, c2d_tustin, tf_step, stepinfo, series,
                     feedback_unity)
from plotstyle import save, C1, C2, C3, INK2, MUTED, TAB_DIR

pm, pa = np.polymul, np.polyadd


def margins(numL, denL, w=np.logspace(0, 7, 200000)):
    """Smallest phase margin over all gain crossovers and smallest gain margin
    over all -180 deg phase crossings (handles resonant loops)."""
    Lw = tf_freq(numL, denL, w)
    mag = np.abs(Lw)
    ph = phase_deg(Lw, start_near=-90)
    pms, wcs, gms, wps = [], [], [], []
    for i in np.where(np.diff(np.sign(mag - 1.0)) != 0)[0]:
        pms.append(180 + ph[i] - 360 * np.round((180 + ph[i]) / 360))
        wcs.append(w[i])
    k = (ph + 180) / 360
    for i in np.where(np.diff(np.floor(k)) != 0)[0]:
        gms.append(-20 * np.log10(mag[i]))
        wps.append(w[i])
    pm_ = min(pms) if pms else np.inf
    gm_ = min(gms) if gms else np.inf
    return pm_, (wcs[int(np.argmin(pms))] if pms else np.nan), gm_, (wps[int(np.argmin(gms))] if gms else np.nan)


def cl_poles_single(Kp, Ki, n, d):
    return np.roots(pa(pm([1, 0], d), pm([Kp, Ki], n)))


def cl_poles_cascade(go, gi, nv, ni, den):
    Kpo, Kio, Kpi, Kii = go["Kp"], go["Ki"], gi["Kp"], gi["Ki"]
    ch = pa(pa(pm([1, 0, 0], den), pm([Kpi, Kii, 0], ni)), pm(pm([Kpi, Kii], [Kpo, Kio]), nv))
    return np.roots(ch)


def fmt_poles(r):
    r = sorted(r, key=lambda z: (z.real, abs(z.imag)))
    out = []
    for z in r:
        if abs(z.imag) < 1e-6 * max(1, abs(z.real)):
            out.append(f"{z.real:.4g}")
        elif z.imag > 0:
            out.append(f"{z.real:.4g}±{z.imag:.4g}j")
    return ", ".join(out)


def main():
    print("Section IV recreation")
    Ts = P.TS
    lines = []

    # ---------------- controllers and Tustin coefficients ----------------- #
    ctrl = [("Single PI, Eq. 33", P.PI_SINGLE), ("Outer PI, Eq. 42", P.PI_OUTER),
            ("Inner PI, Eq. 43", P.PI_INNER), ("Reference-model PI, Eq. 52", P.EQ52)]
    with open(os.path.join(TAB_DIR, "sec4_discretised_controllers.csv"), "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["Controller", "Kp", "Ki", "C(s)", "C(z) Tustin num", "C(z) Tustin den"])
        for name, g in ctrl:
            bz, az = c2d_tustin([g["Kp"], g["Ki"]], [1, 0], Ts)
            wr.writerow([name, g["Kp"], g["Ki"], f"({g['Kp']} s + {g['Ki']})/s",
                         " ".join(f"{x:.8g}" for x in bz), " ".join(f"{x:.8g}" for x in az)])
            lines.append(f"{name:28s} C(z) = ({bz[0]:.8g} + {bz[1]:.8g} z^-1)/(1 - z^-1)")

    # ---------------- reference model ------------------------------------- #
    nT, dT = reference_model_tf("derived")
    nTp, dTp = reference_model_tf("printed")
    bzr, azr = c2d_tustin(nT, dT, Ts)
    lines += ["", "Reference model T_m(s) = C_ref G_ref / (1 + C_ref G_ref)",
              f"  derived Eq.51 (num -0.00625 s + 50): poles {fmt_poles(np.roots(dT))}  -> stable",
              f"  printed Eq.51 (num -0.0625 s + 50):  poles {fmt_poles(np.roots(dTp))}  -> UNSTABLE",
              f"  Tustin T_m(z): num {np.array2string(bzr, precision=6)}",
              f"                 den {np.array2string(azr, precision=8)}"]
    t = np.linspace(0, 0.02, 20001)
    y = tf_step(nT, dT, t)
    yp = tf_step(nTp, dTp, t)
    sref = stepinfo(t, y, yfinal=1.0)
    lines.append("  derived reference-model step: " + ", ".join(f"{k}={v:.4g}" for k, v in sref.items()))

    fig, axs = plt.subplots(1, 2, figsize=(11, 3.8))
    axs[0].plot(t * 1e3, y, color=C3, lw=1.5, label="Eq. 51 derived from Table 8 (-0.00625 s + 50)")
    axs[0].plot(t * 1e3, yp, "--", color=C2, lw=1.2, label="Eq. 51 as printed (-0.0625 s + 50)")
    axs[0].set(title="(a) Closed-loop reference model, unit step", xlabel="Time (ms)",
               ylabel="V_ref(out) / V_ref", ylim=(-1.5, 2.5))
    axs[0].legend(loc="upper right", fontsize=8)
    # loop gain of the single PI on different plants
    wd = np.logspace(1, 6, 4000)
    nv_i, ni_i, den_i, _, _ = averaged_linear_tf(default_params())
    plants = [("Printed Eq. 2", P.EQ2_NUM, P.EQ2_DEN, INK2, "--"),
              ("Printed Eq. 32", P.EQ32_NUM, P.EQ32_DEN, MUTED, ":"),
              ("Correct Eq. 31 (lossless)", nv_i, den_i, C1, "-")]
    for name, n, d, col, ls in plants:
        nl, dl = series([P.PI_SINGLE["Kp"], P.PI_SINGLE["Ki"]], [1, 0], n, d)
        axs[1].semilogx(wd, mag_db(tf_freq(nl, dl, wd)), ls, color=col, label=name)
    axs[1].axhline(0, color=INK2, lw=0.8)
    axs[1].set(title="(b) Single-PI loop gain |C(jw)G(jw)| (Eq. 33)", xlabel="Frequency (rad/s)",
               ylabel="dB", ylim=(-60, 60))
    axs[1].legend(loc="lower left", fontsize=8)
    fig.tight_layout()
    save(fig, "sec4_reference_model_and_loop_gain.png")

    # ---------------- loop analysis table --------------------------------- #
    rows = []
    for name, n, d, *_ in plants:
        nl, dl = series([P.PI_SINGLE["Kp"], P.PI_SINGLE["Ki"]], [1, 0], n, d)
        pm_, wc, gm_, wp = margins(nl, dl)
        r = cl_poles_single(P.PI_SINGLE["Kp"], P.PI_SINGLE["Ki"], n, d)
        rows.append(["Single PI", name, fmt_poles(r), "stable" if np.all(r.real < 0) else "UNSTABLE",
                     f"{pm_:.1f} deg @ {wc:.0f} rad/s", f"{gm_:.1f} dB @ {wp:.0f} rad/s"])
    for rr in [0.01, 0.02, 0.05]:
        pp = default_params(rL=rr)
        nv, ni, den, _, _ = averaged_linear_tf(pp, D=0.5)
        nl, dl = series([P.PI_SINGLE["Kp"], P.PI_SINGLE["Ki"]], [1, 0], nv, den)
        pm_, wc, gm_, wp = margins(nl, dl)
        r = cl_poles_single(P.PI_SINGLE["Kp"], P.PI_SINGLE["Ki"], nv, den)
        rows.append(["Single PI", f"Eq. 31 + {rr*1e3:.0f} mOhm series loss", fmt_poles(r),
                     "stable" if np.all(r.real < 0) else "UNSTABLE",
                     f"{pm_:.1f} deg @ {wc:.0f} rad/s", f"{gm_:.1f} dB @ {wp:.0f} rad/s"])
    # cascade (continuous time)
    r = cl_poles_cascade(P.PI_OUTER, P.PI_INNER, nv_i, ni_i, den_i)
    rows.append(["Cascade PI", "Correct Eqs. 31/39 (lossless)", fmt_poles(r),
                 "stable" if np.all(r.real < 0) else "UNSTABLE", "", ""])
    r = cl_poles_cascade(P.PI_OUTER, P.PI_INNER, np.array(P.EQ32_NUM), np.array(P.EQ40_NUM) / 2,
                         np.array(P.EQ32_DEN))
    rows.append(["Cascade PI", "Printed Eqs. 32/40", fmt_poles(r),
                 "stable" if np.all(r.real < 0) else "UNSTABLE", "", ""])
    # inner loop crossover
    nli, dli = series([P.PI_INNER["Kp"], P.PI_INNER["Ki"]], [1, 0], ni_i, den_i)
    pm_i, wc_i, _, _ = margins(nli, dli)
    lines += ["", f"Inner current loop (correct Eq. 39): crossover {wc_i:.3g} rad/s = {wc_i/2/np.pi/1e3:.1f} kHz,"
              f" PM {pm_i:.1f} deg (continuous time).",
              f"  The switching frequency is {P.FSW/1e3:.0f} kHz, so this loop is faster than the PWM itself;",
              "  it only behaves in simulation because the carrier is compared with the control signal",
              "  10 times per period (multi-sampled PWM)."]

    with open(os.path.join(TAB_DIR, "sec4_loop_analysis.csv"), "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["Controller", "Plant model", "Closed-loop poles", "Stability",
                     "Min phase margin", "Min gain margin"])
        wr.writerows(rows)
    lines += ["", "Loop analysis (continuous time, D = 0.5, R = 16 ohm):"]
    for row in rows:
        lines.append(f"  {row[0]:10s} | {row[1]:34s} | {row[3]:8s} | poles {row[2]} | PM {row[4]} | GM {row[5]}")
    with open(os.path.join(TAB_DIR, "sec4_design_summary.txt"), "w") as f:
        f.write("\n".join(lines))
    print("\n".join("  " + s for s in lines))


if __name__ == "__main__":
    main()
