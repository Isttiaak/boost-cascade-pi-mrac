"""Run the complete Python recreation. Figures -> ../results/figures, tables -> ../results/tables.

    python run_all.py            (about 2-3 minutes without numba, much faster with numba)
"""
import os
import runpy
import sys
import time
import warnings

warnings.filterwarnings("ignore", message="Badly conditioned filter coefficients")
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import sec2_3_modeling      # noqa: E402
import sec4_design          # noqa: E402
import sec5_6_simulations   # noqa: E402

if __name__ == "__main__":
    t0 = time.time()
    runpy.run_module("verify_equations", run_name="__main__")
    sec2_3_modeling.main()
    sec4_design.main()
    sec5_6_simulations.main()
    print(f"\nAll done in {time.time() - t0:.0f} s")
