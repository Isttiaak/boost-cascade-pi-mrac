"""
Combine the CI artifacts into one Markdown summary (GitHub step summary and
SUMMARY.md on the ci-results branch).

    python ci_summary.py <artifact dir> "<job=result ...>"
"""
import csv
import glob
import os
import sys


def table_counts(path):
    rows = list(csv.DictReader(open(path)))
    gating = [r for r in rows if r["gating"].strip() in ("1", "true", "True")]
    passed = [r for r in gating if r["pass"].strip() in ("1", "true", "True")]
    info_diff = [r for r in rows if r not in gating and r["pass"].strip() not in ("1", "true", "True")]
    fails = [r for r in gating if r not in passed]
    return len(passed), len(gating), len(info_diff), fails


def main():
    root = sys.argv[1]
    results = dict(item.split("=", 1) for item in (sys.argv[2].split() if len(sys.argv) > 2 else []))
    out = ["# Verification of the Yanarates & Zhou (2022) recreation", ""]
    out += ["| Job | Result |", "|---|---|"]
    for job, res in results.items():
        mark = {"success": "passed", "failure": "FAILED", "cancelled": "cancelled",
                "skipped": "skipped"}.get(res, res)
        out.append(f"| {job} | {mark} |")
    out.append("")
    out += ["## Agreement with the Python reference", "",
            "| Implementation | Gating metrics within tolerance | Informational metrics that differ |",
            "|---|---|---|"]
    details = []
    for path in sorted(glob.glob(os.path.join(root, "*", "comparison_*.csv"))):
        label = os.path.basename(path)[len("comparison_"):-4]
        ok, n, info, fails = table_counts(path)
        out.append(f"| {label} | {ok} / {n} | {info} |")
        for r in fails:
            details.append(f"- {label}: {r['scenario']} {r['metric']} python {r['python']} vs {r[label]}")
    out.append("")
    if details:
        out += ["Gating metrics outside tolerance:", ""] + details + [""]
    fits = glob.glob(os.path.join(root, "frestimate", "frestimate_fits.csv"))
    if fits:
        out += ["## Frequency-response estimate (Simulink Control Design)", "",
                "| Source | DC gain | Zero (rad/s) | Poles (rad/s) | zeta | Fit (%) |", "|---|---|---|---|---|---|"]
        for r in csv.DictReader(open(fits[0])):
            out.append(f"| {r['source']} | {float(r['dc_gain']):.4g} | {float(r['zero_rad_s']):.5g} | "
                       f"{r['pole1']}, {r['pole2']} | {float(r['zeta']):.3g} | {r['fit_pct']} |")
        out.append("")
    figs = sorted(glob.glob(os.path.join(root, "*", "figures", "*.png")))
    models = sorted(glob.glob(os.path.join(root, "*", "models", "*.slx")))
    out += [f"{len(models)} model files and {len(figs)} figures are on the `ci-results` branch "
            "and in the run's artifacts.", ""]
    print("\n".join(out))


if __name__ == "__main__":
    main()
