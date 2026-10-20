"""
Recreation of Sections II-III (plant modelling):

  Fig. 1   frequency response duty -> v_out of the switching converter, measured
           with a 0.03 sinusoidal duty perturbation at D = 0.5 from 10 rad/s up to
           1/10 of the switching frequency (as Simulink Control Design does)
  Eq. 2    1-zero / 2-pole transfer function fitted to those points
  Eq. 31   state-space averaging TF (correct numbers vs. printed Eq. 32)
  Table 6  open-loop step characteristics
  Fig. 5   step and Bode responses of the transfer functions
  Fig. 7   block-diagram (circuit), differential-equation and transfer-function models

Run:  python sec2_3_modeling.py
"""
import csv
import os
import numpy as np
import matplotlib.pyplot as plt

import paper_values as P
from boost_sim import (simulate, default_params, SIMSCAPE_DEFAULT_PARASITICS,
                       averaged_linear_tf)
from tftools import (tf_step, tf_freq, mag_db, phase_deg, stepinfo, fit_tf_1z2p, tf_info)
from plotstyle import save, inset, C1, C2, C3, INK2, MUTED, TAB_DIR

W_MAX = 2 * np.pi * P.FSW / 10          # 1/10 of the switching frequency [rad/s]
N_FREQ = 20
AMP_SMALL = 0.0005                      # small-signal check amplitude


# --------------------------------------------------------------------------- #
#  Frequency-response estimation (Simulink Control Design "frestimate" style)
# --------------------------------------------------------------------------- #
def steady_state(params, D0=P.D, T=0.4):
    """Run to periodic steady state; T is an integer number of switching periods,
    so the returned end state is at the start of a PWM period."""
    r = simulate(T, plant="switching", ctrl="open", params=params, duty=D0)
    iL_end, v_end = r["x_end"]
    return iL_end, v_end, r["v_avg"][-4000:].mean()


def fr_point(params, w, amp, D0=P.D):
    """Inject d = D0 + amp*sin(wt) and extract the fundamental of v and d
    (one settling segment, then an integer number of measurement periods)."""
    Tp = 2 * np.pi / w
    n_set = max(1, int(np.ceil(0.15 / Tp)))      # >= 0.15 s: lets the LC resonance (tau = 2RC) die out
    n_meas = max(3 if w < 100 else 4, int(np.ceil(0.02 / Tp)))
    r = simulate((n_set + n_meas) * Tp, plant="switching", ctrl="open",
                 params=params, duty=lambda t: D0 + amp * np.sin(w * t))
    # Average v and d over each switching period first (what an averaging
    # measurement sees; removes the ripple, whose shape depends on d), then
    # correlate with the excitation over an integer number of its periods.
    nper = int(round(1 / (P.FSW * P.TS)))
    def per_period(x):
        n = len(x) // nper * nper
        xs = np.repeat(x[:n].reshape(-1, nper).mean(axis=1), nper)
        return np.concatenate([xs, np.full(len(x) - n, xs[-1])])
    t = r["t"] + 0.5 * P.TS
    v, d = per_period(r["v_avg"]), per_period(r["d"])
    m = t >= n_set * Tp
    ex = np.exp(-1j * w * t[m])
    vm, dm = v[m] - v[m].mean(), d[m] - d[m].mean()    # remove the operating point (no DC leakage)
    return np.sum(vm * ex) / np.sum(dm * ex), r["iL"][m].min()


def estimate_frequency_response(params, amp, w):
    iL0, v0, _ = steady_state(params)
    p = dict(params, iL0=iL0, v0=v0)
    H, imin = [], []
    for wi in w:
        h, im = fr_point(p, wi, amp)
        H.append(h)
        imin.append(im)
    return np.array(H), np.array(imin)


def main():
    print("Section II-III recreation")
    # Circuit used throughout = Table 3 values with ideal MOSFET and ideal diode.
    # (For the Simulink-default-device variant use
    #  default_params(**SIMSCAPE_DEFAULT_PARASITICS) instead.)
    plant_p = default_params()
    ideal_p = default_params()
    w0 = (1 - P.D) / np.sqrt(P.L * P.C)
    w = np.sort(np.concatenate([np.logspace(1, np.log10(W_MAX), N_FREQ),
                                w0 * np.array([0.92, 0.97, 1.0, 1.03, 1.08])]))
    wd = np.logspace(1, 6, 600)

    # ---------------- Fig. 1 / Eq. 2 ------------------------------------- #
    print(" estimating frequency response (this takes ~1 min) ...")
    H03, imin03 = estimate_frequency_response(plant_p, P.PERTURB_AMP, w)
    H003, imin003 = estimate_frequency_response(plant_p, AMP_SMALL, w)
    n03, d03, fit03 = fit_tf_1z2p(w, H03)
    n003, d003, fit003 = fit_tf_1z2p(w, H003)
    nv_lin, _, den_lin, IL0, V0 = averaged_linear_tf(plant_p)
    nv_ide, ni_ide, den_ide, _, _ = averaged_linear_tf(ideal_p)

    with open(os.path.join(TAB_DIR, "fig01_frequency_response_points.csv"), "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["w_rad_s", "mag_dB_amp0.03", "phase_deg_amp0.03", "min_iL_amp0.03",
                     f"mag_dB_amp{AMP_SMALL:g}", f"phase_deg_amp{AMP_SMALL:g}", f"min_iL_amp{AMP_SMALL:g}"])
        ph03 = phase_deg(H03)
        ph003 = phase_deg(H003)
        for i in range(len(w)):
            wr.writerow([f"{w[i]:.2f}", f"{mag_db(H03[i]):.3f}", f"{ph03[i]:.2f}", f"{imin03[i]:.3f}",
                         f"{mag_db(H003[i]):.3f}", f"{ph003[i]:.2f}", f"{imin003[i]:.3f}"])

    fig, axs = plt.subplots(2, 2, figsize=(11, 6.2), sharex=True)
    for col, (H, nf, dfit, amp, fitpct) in enumerate([(H03, n03, d03, P.PERTURB_AMP, fit03),
                                                     (H003, n003, d003, AMP_SMALL, fit003)]):
        am, ap = axs[0, col], axs[1, col]
        am.semilogx(wd, mag_db(tf_freq(P.EQ2_NUM, P.EQ2_DEN, wd)), "--", color=INK2, lw=1.1,
                    label="Paper Eq. 2 (printed)")
        am.semilogx(wd, mag_db(tf_freq(nv_lin, den_lin, wd)), color=C3, lw=1.1,
                    label="Averaged small-signal model = Eq. 31")
        am.semilogx(wd, mag_db(tf_freq(nf, dfit, wd)), color=C2, lw=1.4,
                    label=f"Fitted 1-zero/2-pole TF (fit {fitpct:.0f}%)")
        am.semilogx(w, mag_db(H), "o", color=C1, ms=4.5, label="Measured points (switching model)")
        am.set_title(f"Perturbation amplitude {amp:g}" + ("  (paper's value)" if col == 0 else "  (small signal)"))
        am.set_ylabel("Magnitude (dB)")
        am.set_ylim(-10, 75)
        ap.semilogx(wd, phase_deg(tf_freq(P.EQ2_NUM, P.EQ2_DEN, wd)), "--", color=INK2, lw=1.1)
        ap.semilogx(wd, phase_deg(tf_freq(nv_lin, den_lin, wd)), color=C3, lw=1.1)
        ap.semilogx(wd, phase_deg(tf_freq(nf, dfit, wd)), color=C2, lw=1.4)
        ap.semilogx(w, phase_deg(H), "o", color=C1, ms=4.5)
        ap.set_ylabel("Phase (deg)")
        ap.set_xlabel("Frequency (rad/s)")
        ap.set_ylim(-280, 20)
        ap.set_yticks([-270, -180, -90, 0])
        am.axvspan(W_MAX, 1e6, color="#f0efec", zorder=0)
        ap.axvspan(W_MAX, 1e6, color="#f0efec", zorder=0)
    axs[0, 0].legend(loc="lower left")
    fig.suptitle("Fig. 1 recreated - duty-to-output frequency response at D = 0.5 "
                 "(shaded: above fsw/10, not measured)", fontsize=10.5, fontweight="bold")
    fig.tight_layout()
    save(fig, "fig01_frequency_response_estimation.png")

    # ---------------- Eq. 31 / Eq. 32 / Table 6 / Fig. 5 ------------------ #
    num31 = np.array([-P.L * P.VDC, P.R * P.VDC * (1 - P.D) ** 2])
    den31 = np.array([P.L * P.R * P.C * (1 - P.D) ** 2, P.L * (1 - P.D) ** 2, P.R * (1 - P.D) ** 4])
    models = [
        ("Paper Eq. 2 (printed)", P.EQ2_NUM, P.EQ2_DEN, 0.0305, INK2, "--"),
        ("Paper Eq. 32 (printed)", P.EQ32_NUM, P.EQ32_DEN, 0.0151, MUTED, ":"),
        ("Eq. 31 with Table 3 values (correct)", num31, den31, 0.1, C1, "-"),
        ("Fitted TF, amp 0.03", n03, d03, 0.1, C2, "-"),
        (f"Fitted TF, amp {AMP_SMALL:g}", n003, d003, 0.1, C3, "-"),
    ]
    rows = []
    for name, n, d, tend, *_ in models:
        t = np.linspace(0, tend, 200001)
        y = tf_step(n, d, t)
        info = stepinfo(t, y, yfinal=np.polyval(n, 0) / np.polyval(d, 0))
        rows.append((name, info, tf_info(n, d)))
    keys = ["RiseTime", "SettlingTime", "SettlingMin", "SettlingMax", "Overshoot", "Undershoot",
            "Peak", "PeakTime"]
    with open(os.path.join(TAB_DIR, "table06_open_loop_step.csv"), "w", newline="") as f:
        wr = csv.writer(f)
        wr.writerow(["Model"] + keys + ["zeros", "poles", "DC gain"])
        for name, P6 in P.TABLE6.items():
            wr.writerow(["PAPER Table 6: " + name] + [P6[k] for k in keys] + ["", "", ""])
        for name, info, ti in rows:
            wr.writerow([name] + [f"{info[k]:.5g}" for k in keys] +
                        [" ".join(f"{z.real:.4g}{z.imag:+.4g}j" for z in ti["zeros"]),
                         " ".join(f"{z.real:.4g}{z.imag:+.4g}j" for z in ti["poles"]),
                         f"{ti['dc_gain']:.5g}"])
    print("  Table 6 recreated:")
    for name, info, _ in rows:
        print(f"    {name:38s} " + "  ".join(f"{k}={info[k]:.4g}" for k in keys))

    fig, axs = plt.subplots(1, 3, figsize=(13, 3.9))
    t = np.linspace(0, 0.02, 20001)
    for name, n, d, _, col, ls in models[:3]:
        axs[0].plot(t * 1e3, tf_step(n, d, t), ls, color=col, label=name)
        axs[1].semilogx(wd, mag_db(tf_freq(n, d, wd)), ls, color=col)
        axs[2].semilogx(wd, phase_deg(tf_freq(n, d, wd)), ls, color=col)
    axs[0].set(title="(a) Open-loop unit-step response", xlabel="Time (ms)", ylabel="Amplitude (V per unit duty)")
    axs[1].set(title="(b) Magnitude", xlabel="Frequency (rad/s)", ylabel="dB")
    axs[2].set(title="(c) Phase", xlabel="Frequency (rad/s)", ylabel="deg", yticks=[-270, -180, -90, 0])
    axs[0].legend(loc="lower right", fontsize=7.8)
    fig.suptitle("Fig. 5 recreated - printed transfer functions vs. Eq. 31 evaluated correctly",
                 fontsize=10.5, fontweight="bold")
    fig.tight_layout()
    save(fig, "fig05_tf_step_and_bode.png")

    # ---------------- Fig. 7 three model types ---------------------------- #
    T7 = 0.05
    r_blk = simulate(T7, plant="switching", ctrl="open", duty=0.5, params=plant_p)
    r_dif = simulate(T7, plant="switching", ctrl="open", duty=0.5,
                     params=default_params(unidirectional=0))
    tt = r_blk["t"]
    y_tf = 0.5 * tf_step(num31, den31, tt)
    fig, ax = plt.subplots(figsize=(8.6, 4.4))
    ax.plot(tt, r_blk["v"], color=C1, lw=1.3, label="Block-diagram (circuit) model: switch + diode, DCM possible")
    ax.plot(tt, r_dif["v"], color=C2, lw=1.0, label="Differential-equation model: ideal switched (Fig. 6)")
    ax.plot(tt, y_tf, color=INK2, lw=1.0, label="Transfer-function model: Eq. 31, d = 0.5 step")
    ax.set(xlabel="Time (s)", ylabel="Voltage (V)", xlim=(0, T7), ylim=(-2, 82))
    ax.legend(loc="lower right")
    ax.set_title("Fig. 7 recreated - open-loop output voltage of three model types (cold start, D = 0.5)")
    save(fig, "fig07_model_comparison.png")
    print(f"  Fig. 7: circuit model peak {r_blk['v'].max():.1f} V, settles at {r_blk['v_avg'][-2000:].mean():.2f} V;"
          f" ideal switched model peak {r_dif['v'].max():.1f} V")

    # ---------------- text summary --------------------------------------- #
    with open(os.path.join(TAB_DIR, "sec2_fitted_transfer_functions.txt"), "w") as f:
        def line(lbl, n, d):
            ti = tf_info(n, d)
            f.write(f"{lbl}\n  num = {np.array2string(np.asarray(n), precision=5)}\n"
                    f"  den = {np.array2string(np.asarray(d), precision=5)}\n"
                    f"  DC gain = {ti['dc_gain']:.4g}, zeros = {ti['zeros']}, poles = {ti['poles']}\n\n")
        f.write(f"Operating point of the circuit model at D = 0.5: I_L = {IL0:.3f} A, V = {V0:.3f} V\n\n")
        line("Paper Eq. 2 (printed)", P.EQ2_NUM, P.EQ2_DEN)
        line(f"Fitted to switching-model data, amplitude 0.03 (fit {fit03:.1f}%)", n03, d03)
        line(f"Fitted to switching-model data, amplitude {AMP_SMALL:g} (fit {fit003:.1f}%)", n003, d003)
        line("Averaged small-signal model of the simulated circuit", nv_lin, den_lin)
        line("Ideal averaged model = Eq. 31 (correct numbers)", nv_ide, den_ide)
        f.write(f"min inductor current during the 0.03 sweep: {imin03.min():.3f} A "
                f"(0 means the converter entered DCM)\n")
    for lbl, n, d in [("fit amp 0.03 ", n03, d03), (f"fit amp {AMP_SMALL:g}", n003, d003)]:
        ti = tf_info(n, d)
        print(f"  {lbl}: num={np.array2string(n, precision=4)} den={np.array2string(d, precision=4)}"
              f" zeros={np.round(ti['zeros'], 1)} poles={np.round(ti['poles'], 1)}")
    print(f"  fit quality: amp 0.03 -> {fit03:.1f}%, amp {AMP_SMALL:g} -> {fit003:.1f}%")


if __name__ == "__main__":
    main()
