# Verification of the Yanarates & Zhou (2022) recreation in MATLAB/Simulink

Summary written by `simulink/ci_report.m` with MATLAB 25.1.0.2973910 (R2025a) Update 1.

| Job | Result |
|---|---|
| reference | passed |
| simulink | passed |
| frestimate | passed |
| compat-R2022b | passed |

## Paper checks: transfer functions and tables (Sections II-IV)

Table 6 is recomputed with MATLAB's `stepinfo` on the printed Eq. 2 and Eq. 32; "differs" rows confirm printed numbers that contradict the paper's own formulas.

| Check | Paper | Recreated | Expected | Result |
|---|---|---|---|---|
| Table 6, Eq. 2: RiseTime (stepinfo) | 0.0044 | 0.0043603 | match (±0.0001) | as expected |
| Table 6, Eq. 2: SettlingTime (stepinfo) | 0.0081 | 0.0080603 | match (±0.0001) | as expected |
| Table 6, Eq. 2: SettlingMin (stepinfo) | 68.81 | 68.81 | match (±0.2) | as expected |
| Table 6, Eq. 2: SettlingMax (stepinfo) | 76.434 | 76.434 | match (±0.05) | as expected |
| Table 6, Eq. 2: Overshoot (stepinfo) | 0 | 0 | match (±0.05) | as expected |
| Table 6, Eq. 2: Undershoot (stepinfo) | 85.177 | 85.177 | match (±0.05) | as expected |
| Table 6, Eq. 2: Peak (stepinfo) | 76.434 | 76.434 | match (±0.05) | as expected |
| Table 6, Eq. 2: PeakTime (stepinfo) | 0.0305 | 0.020524 | info | differs (info) |
| Table 6, Eq. 32: RiseTime (stepinfo) | 0.0042 | 0.0041917 | match (±0.0001) | as expected |
| Table 6, Eq. 32: SettlingTime (stepinfo) | 0.0078 | 0.0077909 | match (±0.0001) | as expected |
| Table 6, Eq. 32: SettlingMin (stepinfo) | 72.032 | 72.032 | match (±0.2) | as expected |
| Table 6, Eq. 32: SettlingMax (stepinfo) | 79.938 | 79.938 | match (±0.05) | as expected |
| Table 6, Eq. 32: Overshoot (stepinfo) | 0 | 0 | match (±0.05) | as expected |
| Table 6, Eq. 32: Undershoot (stepinfo) | 81.27 | 81.27 | match (±0.05) | as expected |
| Table 6, Eq. 32: Peak (stepinfo) | 79.938 | 79.938 | match (±0.05) | as expected |
| Table 6, Eq. 32: PeakTime (stepinfo) | 0.0151 | 0.015116 | info | close |
| Table 8: I_L,avg,max (A) | 8 | 8 | match (±1e-09) | as expected |
| Table 8: inductor ripple (A) | 1.6 | 1.6 | match (±1e-09) | as expected |
| Table 8: L (mH) | 0.3125 | 0.3125 | match (±1e-09) | as expected |
| Table 8: output ripple (V) | 1.6 | 1.6 | match (±1e-09) | as expected |
| Table 8: C (uF) | 62.5 | 62.5 | match (±1e-09) | as expected |
| Eq. 32 RHP zero (rad/s) vs Eq. 31 with Table 3 | 500 | 40000 | differs (>50) | as expected |
| Eq. 32 damping ratio vs Eq. 31 with Table 3 | 2.3837 | 0.029796 | differs (>0.1) | as expected |
| Eq. 40 DC gain (A per unit duty) vs Eq. 39 | 1600 | 20 | differs (>1) | as expected |
| Eq. 51 RHP zero (rad/s) vs Eq. 31 with Table 8 | 800 | 8000 | differs (>50) | as expected |
| Eq. 2 RHP zero (rad/s) vs Eq. 31 with Table 3 | 473.58 | 40000 | differs (>50) | as expected |
| Reference loop, printed Eq. 51 + Eq. 52: max Re(pole) (rad/s) | - | 182.4 | unstable (> 0) | as expected |
| Reference loop, Eq. 51 from Table 8 + Eq. 52: max Re(pole) (rad/s) | - | -457.9 | stable (< 0) | as expected |
| Single PI (Eq. 33) on printed Eq. 2: max Re(pole) (rad/s) | - | -155.62 | stable (< 0) | as expected |
| Single PI (Eq. 33) on printed Eq. 32: max Re(pole) (rad/s) | - | -156.94 | stable (< 0) | as expected |
| Single PI (Eq. 33) on Eq. 31 (Table 3): max Re(pole) (rad/s) | - | 52.852 | unstable (> 0) | as expected |

## Paper checks: simulations (Figs. 7, 13-16, Table 10)

Paper values marked (fig.) are read off the paper's figures. Table 10 is the 30 -> 40 V reference step at 0.2 s.

| Check | Paper | MATLAB script | Simulink diffeq | Simulink circuit (SPS) | Expected | Result |
|---|---|---|---|---|---|---|
| Fig. 7: circuit model, cold-start peak (V) (fig.) | 76 | 76.527 | 76.528 | 76.501 | match (±1.5) | as expected |
| Fig. 7: circuit model, mean over 40-50 ms (V) (fig.) | 40 | 39.992 | 39.992 | 39.991 | match (±0.5) | as expected |
| Fig. 13: tracking-error peak after 0.2 s, gamma = 0.1 (V) (fig.) | 7 | 7.0536 | 7.0867 | 7.0128 | match (±1) | as expected |
| Fig. 13: tracking-error peak after 0.2 s, gamma = 1 (V) (fig.) | 6 | 5.6259 | 5.6654 | 5.6147 | match (±1) | as expected |
| Fig. 14: theta before 0.2 s, gamma = 0.1 (fig.) | 0.95 | 0.94196 | 0.94189 | 0.94179 | match (±0.1) | as expected |
| Fig. 14: theta before 0.2 s, gamma = 0.5 (fig.) | 0.755 | 0.71035 | 0.71048 | 0.71108 | match (±0.1) | as expected |
| Fig. 14: theta before 0.2 s, gamma = 1 (fig.) | 0.505 | 0.42612 | 0.42586 | 0.42572 | match (±0.1) | as expected |
| Fig. 14: theta at 0.26 s, gamma = 0.1 (fig.) | 0.9 | 0.88942 | 0.88823 | 0.88895 | match (±0.1) | as expected |
| Fig. 14: theta at 0.26 s, gamma = 0.5 (fig.) | 0.5 | 0.45697 | 0.45657 | 0.45586 | match (±0.1) | as expected |
| Fig. 14: theta at 0.26 s, gamma = 1 (fig.) | 0.12 | 0.10323 | 0.10333 | 0.09595 | match (±0.1) | as expected |
| Fig. 15: gamma = 1 diverges after 0.4 s, minimum over 0.5-0.6 s (V) (fig.) | 33 | 31.723 | 30.684 | 30.601 | match (±3) | as expected |
| Fig. 15: gamma = 1, maximum over 0.5-0.6 s (V) (fig., axis ends at 70 V) | 68 | 73.262 | 73.458 | 73.742 | at least the paper value | as expected |
| Fig. 15: gamma = 0.5 stays regulated near 50 V, maximum over 0.5-0.6 s (V) (fig.) | 50 | 50.11 | 50.425 | 50.112 | match (±1) | as expected |
| Fig. 16: single PI, start-up peak (V) (fig.) | 52.5 | 51.426 | 51.426 | 51.414 | match (±2.5) | as expected |
| Fig. 16: single PI, start-up dip (V) (fig.) | 28 | 26.072 | 26.073 | 26.075 | match (±2.5) | as expected |
| Fig. 16: cascade PI, start-up peak (V) (fig.) | 46.5 | 45.619 | 45.66 | 45.628 | match (±2) | as expected |
| Fig. 16: cascade PI, start-up dip (V) (fig.) | 38.5 | 36.969 | 36.914 | 36.946 | match (±2) | as expected |
| Fig. 16: cascade PI, dip after 16 -> 10 Ohm (V) (fig.) | 37.8 | 37.645 | 37.763 | 37.591 | match (±0.5) | as expected |
| Fig. 16: cascade PI, peak after 16 -> 10 Ohm (V) (fig.) | 40.9 | 41.045 | 40.972 | 40.968 | match (±0.5) | as expected |
| Fig. 16: MRAC as written, dip after 16 -> 10 Ohm (V) (fig.) | 38.6 | 37.843 | 37.735 | 37.61 | info | differs (info) |
| Table 10: cascade PI, peak (V) | 44.697 | 44.616 | 44.672 | 44.64 | match (±0.5) | as expected |
| Table 10: cascade PI, overshoot (% of 40 V) | 11.742 | 11.541 | 11.681 | 11.6 | match (±1.5) | as expected |
| Table 10: cascade PI, peak time (s) | 0.0028 | 0.00285 | 0.00275 | 0.00285 | match (±0.0005) | as expected |
| Table 10: cascade PI, rise time (s) | 0.0012 | 0.00097782 | 0.00098164 | 0.00097776 | info | close |
| Table 10: cascade PI, settling time (s) | 0.0064 | 0.018265 | 0.01554 | 0.015841 | info | differs (info) |
| Table 10: MRAC peak (V) vs MRAC as written (Eqs. 54-56) | 41.485 | 44.571 | 44.649 | 44.572 | differs (>0.5) | as expected |
| Table 10: MRAC peak (V) vs model-following set-point | 41.485 | 41.746 | 41.684 | 41.82 | match (±0.5) | as expected |
| Table 10: MRAC overshoot (% of 40 V) vs model-following set-point | 3.7125 | 4.3649 | 4.2088 | 4.5504 | match (±1.5) | as expected |
| Table 10: single PI, peak (V) | 40.164 | 41.013 | 41.013 | 41.089 | info | differs (info) |

## Paper checks: frequency response with Simulink Control Design (Section II-A)

| Check | Paper | frestimate | Expected | Result |
|---|---|---|---|---|
| Eq. 2 RHP zero (rad/s) vs frestimate, amplitude 0.03 | 473.58 | 17719 | differs (>236.788) | as expected |
| Eq. 2 damping ratio vs frestimate, amplitude 0.03 | 2.5922 | 0.404 | differs (>0.5) | as expected |
| Eq. 2 DC gain vs frestimate, amplitude 0.03 | 76.439 | 80.292 | info | differs (info) |
| Eq. 31 resonance (rad/s) vs frestimate, amplitude 0.0005 | 2383.7 | 2383.1 | match (±50) | as expected |
| Eq. 31 damping ratio vs frestimate, amplitude 0.0005 | 0.029796 | 0.03056 | match (±0.01) | as expected |
| Eq. 31 DC gain vs frestimate, amplitude 0.0005 | 80 | 81.359 | match (±3) | as expected |

| Source | DC gain | Zero (rad/s) | Poles (rad/s) | zeta | Fit (%) |
|---|---|---|---|---|---|
| Paper Eq. 2 | 76.44 | 473.58 | -12516.1+0j, -503.911+0j | 2.59 | - |
| Eq. 31 (Table 3 values) | 80 | 40000 | -71.0227+2382.6j, -71.0227-2382.6j | 0.0298 | - |
| frestimate amplitude 0.03 | 80.29 | 17719 | -813.542+1841.94j, -813.542-1841.94j | 0.404 | 74.37 |
| frestimate amplitude 0.0005 | 81.36 | 44271 | -72.8158+2381.94j, -72.8158-2381.94j | 0.0306 | 97.58 |

## Agreement with the MATLAB reference (matlab/boost_sim.m)

| Implementation | Gating metrics within tolerance | Informational metrics that differ |
|---|---|---|
| compat_R2022b_diffeq | 38 / 38 | 1 |
| compat_R2022b_sps | 38 / 38 | 1 |
| simulink_diffeq | 98 / 98 | 4 |
| simulink_sps | 98 / 98 | 5 |

17 model files, 60 model diagrams and 34 figures are on the `ci-results` branch and in the run's artifacts.

