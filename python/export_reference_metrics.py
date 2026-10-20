"""
Run every shared scenario (scenarios.py) on the Python switching model and
write the reference that the MATLAB scripts and the Simulink models are
checked against in CI:

  results/reference/metrics_python.csv     scenario, metric, value
  results/reference/traces_python/<scenario>.csv
                                           t, v, iL, theta, ym every 50 us

Run:  python export_reference_metrics.py
"""
import csv
import os
import time
import warnings

import numpy as np

warnings.filterwarnings("ignore", message="Badly conditioned filter coefficients")

from boost_sim import simulate, default_params          # noqa: E402
from scenarios import scenario_list, scenario_metrics, profile_array, TS   # noqa: E402

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "results", "reference")
TRACE_DIR = os.path.join(OUT, "traces_python")
DECIM = 10                 # one sample per switching period in the trace files
CTRL_MAP = {"open": "open", "pi": "pi", "cascade": "cascade", "mrac": "mrac", "mrac_mf": "mrac_ms"}


def run_scenario(s):
    N = int(round(s["T"] / TS))
    p = default_params(unidirectional=0 if np.isinf(s["iL_min"]) else 1)
    r = simulate(s["T"], plant="switching", ctrl=CTRL_MAP[s["ctrl"]], params=p,
                 vref=profile_array(s["vref"], N), vin=profile_array(s["vin"], N),
                 rload=profile_array(s["rload"], N), duty=s["duty"], gamma=s["gamma"])
    return r


def main():
    os.makedirs(TRACE_DIR, exist_ok=True)
    rows = []
    t0 = time.time()
    for s in scenario_list():
        r = run_scenario(s)
        m = scenario_metrics(s["name"], r["t"], r["v"], r["iL"], r["theta"], r["ym"])
        for k, v in m.items():
            rows.append((s["name"], k, v))
        with open(os.path.join(TRACE_DIR, s["name"] + ".csv"), "w", newline="") as f:
            w = csv.writer(f)
            w.writerow(["t", "v", "iL", "theta", "ym"])
            for i in range(0, len(r["t"]), DECIM):
                w.writerow([f"{r['t'][i]:.7g}", f"{r['v'][i]:.6g}", f"{r['iL'][i]:.6g}",
                            f"{r['theta'][i]:.7g}", f"{r['ym'][i]:.6g}"])
        print(f"  {s['name']:14s} " + "  ".join(f"{k}={v:.5g}" for k, v in m.items()))
    with open(os.path.join(OUT, "metrics_python.csv"), "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(["scenario", "metric", "value"])
        for name, k, v in rows:
            w.writerow([name, k, repr(float(v))])
    print(f"wrote {len(rows)} metrics in {time.time() - t0:.0f} s -> results/reference/")


if __name__ == "__main__":
    main()
