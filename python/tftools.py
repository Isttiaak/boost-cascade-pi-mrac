"""
Small transfer-function toolbox (numpy/scipy only) used by the recreation scripts.

Functions mirror the MATLAB Control System Toolbox calls the paper relies on:
  tf_step   ~ step()          stepinfo ~ stepinfo()
  tf_freq   ~ bode()          c2d_tustin ~ c2d(sys, Ts, 'tustin')
  fit_tf_1z2p ~ tfest(data, 2, 1)  (2 poles, 1 zero)
"""
import numpy as np
from scipy import signal


# --------------------------------------------------------------------------- #
#  Basic helpers
# --------------------------------------------------------------------------- #
def tf_info(num, den):
    """Return dict with zeros, poles, DC gain, wn/zeta of a 2nd-order den."""
    num = np.atleast_1d(np.asarray(num, float))
    den = np.atleast_1d(np.asarray(den, float))
    z = np.roots(num) if len(num) > 1 else np.array([])
    p = np.roots(den)
    dc = np.polyval(num, 0.0) / np.polyval(den, 0.0) if np.polyval(den, 0.0) != 0 else np.inf
    out = dict(zeros=z, poles=p, dc_gain=dc)
    if len(den) == 3:
        a2, a1, a0 = den
        wn = np.sqrt(a0 / a2)
        out["wn"] = wn
        out["zeta"] = (a1 / a2) / (2 * wn)
    return out


def tf_step(num, den, t):
    """Unit-step response of num/den on time vector t (zero initial state)."""
    sys = signal.lti(num, den)
    _, y = signal.step(sys, T=t)
    return y


def tf_freq(num, den, w):
    """Complex frequency response H(jw)."""
    _, h = signal.freqs(num, den, worN=w)
    return h


def mag_db(h):
    return 20 * np.log10(np.abs(h))


def phase_deg(h, start_near=0.0):
    """Unwrapped phase in degrees, shifted by multiples of 360 so the first
    point lies near `start_near` (MATLAB bode does the same kind of wrapping)."""
    ph = np.degrees(np.unwrap(np.angle(h)))
    k = np.round((ph[0] - start_near) / 360.0)
    return ph - 360.0 * k


def series(n1, d1, n2, d2):
    return np.polymul(n1, n2), np.polymul(d1, d2)


def feedback_unity(n, d):
    """Closed loop  G/(1+G)  for G = n/d."""
    n = np.asarray(n, float)
    d = np.asarray(d, float)
    L = max(len(n), len(d))
    n_ = np.pad(n, (L - len(n), 0))
    d_ = np.pad(d, (L - len(d), 0))
    num = np.trim_zeros(n_, "f")
    return (num if len(num) else np.array([0.0])), d_ + n_


def c2d_tustin(num, den, Ts):
    """Bilinear (Tustin) discretisation, as in paper Eq. (53)."""
    nd, dd, _ = signal.cont2discrete((num, den), Ts, method="bilinear")
    nd = np.atleast_1d(np.squeeze(nd))
    return nd / dd[0], dd / dd[0]


# --------------------------------------------------------------------------- #
#  MATLAB-style stepinfo
# --------------------------------------------------------------------------- #
def stepinfo(t, y, yfinal=None, yinit=0.0, st=0.02, rt=(0.1, 0.9),
             settle_ref="peak_error"):
    """
    Replicates MATLAB stepinfo() definitions:
      RiseTime      time from rt[0] to rt[1] of the transition yinit -> yfinal
      SettlingTime  time after which |y - yfinal| stays below st * reference,
                    reference = max|y - yfinal| (settle_ref='peak_error', the
                    definition that reproduces the paper's Table 6 exactly) or
                    |yfinal - yinit| (settle_ref='final')
      SettlingMin/Max  min/max of y once the response has risen (after the
                       first time it reaches rt[1] of the transition)
      Overshoot     % above yfinal (relative to |yfinal - yinit|)
      Undershoot    % in the wrong direction below yinit (relative to |yfinal-yinit|)
      Peak          max |y|           PeakTime  time of Peak
    """
    t = np.asarray(t, float)
    y = np.asarray(y, float)
    if yfinal is None:
        yfinal = y[-1]
    dy = yfinal - yinit
    s = np.sign(dy) if dy != 0 else 1.0
    yn = (y - yinit) * s            # normalised so the response goes upward
    D = abs(dy)

    # rise time (first crossings, linear interpolation)
    def first_cross(level):
        idx = np.where(yn >= level)[0]
        if len(idx) == 0:
            return np.nan
        i = idx[0]
        if i == 0:
            return t[0]
        return t[i - 1] + (level - yn[i - 1]) * (t[i] - t[i - 1]) / (yn[i] - yn[i - 1])

    t_lo = first_cross(rt[0] * D)
    t_hi = first_cross(rt[1] * D)
    rise = t_hi - t_lo

    # settling time
    err = np.abs(y - yfinal)
    thr = st * (err.max() if settle_ref == "peak_error" else D)
    outside = np.where(err > thr)[0]
    if len(outside) == 0:
        settle = t[0]
    elif outside[-1] == len(t) - 1:
        settle = np.nan
    else:
        i = outside[-1]
        # interpolate the last exit of the band
        e1, e2 = err[i], err[i + 1]
        frac = (e1 - thr) / (e1 - e2) if e1 != e2 else 0.0
        settle = t[i] + frac * (t[i + 1] - t[i])

    # settling min / max after rise
    if np.isnan(t_hi):
        smin = smax = np.nan
    else:
        mask = t >= t_hi
        smin = y[mask].min()
        smax = y[mask].max()

    overshoot = max(0.0, (yn.max() - D) / D * 100.0) if D > 0 else 0.0
    undershoot = max(0.0, -yn.min() / D * 100.0) if D > 0 else 0.0
    ipk = np.argmax(np.abs(y))
    return dict(RiseTime=rise, SettlingTime=settle, SettlingMin=smin,
                SettlingMax=smax, Overshoot=overshoot, Undershoot=undershoot,
                Peak=np.abs(y[ipk]), PeakTime=t[ipk])


# --------------------------------------------------------------------------- #
#  Transfer-function fitting from frequency-response data (like tfest 2p/1z)
# --------------------------------------------------------------------------- #
def fit_tf_1z2p(w, H, iters=30, weight=None):
    """
    Fit  G(s) = (b1 s + b0) / (s^2 + a1 s + a0)  to complex data H(jw).
    Levy linear least squares followed by Sanathanan-Koerner iterations,
    then a nonlinear polish on the relative complex error (like tfest).
    """
    from scipy.optimize import least_squares
    w = np.asarray(w, float)
    H = np.asarray(H, complex)
    s = 1j * w
    if weight is None:
        weight = np.ones_like(w)

    def solve(wt):
        # unknowns x = [b1, b0, a1, a0]
        # (b1 s + b0) - H (a1 s + a0) = H s^2
        A = np.column_stack([s, np.ones_like(s), -H * s, -H])
        rhs = H * s ** 2
        A = A * wt[:, None]
        rhs = rhs * wt
        Ar = np.vstack([A.real, A.imag])
        br = np.concatenate([rhs.real, rhs.imag])
        x, *_ = np.linalg.lstsq(Ar, br, rcond=None)
        return x

    x = solve(weight)
    for _ in range(iters):  # SK iterations
        den = s ** 2 + x[2] * s + x[3]
        x = solve(weight / np.abs(den))

    def resid(xx):
        G = (xx[0] * s + xx[1]) / (s ** 2 + xx[2] * s + xx[3])
        r = (G - H) / np.abs(H) * weight
        return np.concatenate([r.real, r.imag])

    sol = least_squares(resid, x, x_scale=np.abs(x) + 1e-12, max_nfev=20000)
    xb = sol.x
    num = np.array([xb[0], xb[1]])
    den = np.array([1.0, xb[2], xb[3]])
    G = tf_freq(num, den, w)
    fit_pct = 100 * (1 - np.linalg.norm(H - G) / np.linalg.norm(H - H.mean()))
    return num, den, fit_pct
