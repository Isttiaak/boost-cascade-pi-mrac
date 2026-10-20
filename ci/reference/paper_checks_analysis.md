## Paper checks (analysis): all as expected

| Check | Paper | Recreated | Tolerance | Expected | Result | Note |
|---|---|---|---|---|---|---|
| Table 6, Eq. 2: RiseTime (stepinfo) | 0.0044 | 0.0043603 | 0.0001 | match | as expected |  |
| Table 6, Eq. 2: SettlingTime (stepinfo) | 0.0081 | 0.0080603 | 0.0001 | match | as expected | stepinfo TransientTime; SettlingTime = 0.009283 s |
| Table 6, Eq. 2: SettlingMin (stepinfo) | 68.81 | 68.81 | 0.2 | match | as expected |  |
| Table 6, Eq. 2: SettlingMax (stepinfo) | 76.434 | 76.434 | 0.05 | match | as expected |  |
| Table 6, Eq. 2: Overshoot (stepinfo) | 0 | 0 | 0.05 | match | as expected |  |
| Table 6, Eq. 2: Undershoot (stepinfo) | 85.177 | 85.177 | 0.05 | match | as expected |  |
| Table 6, Eq. 2: Peak (stepinfo) | 76.434 | 76.434 | 0.05 | match | as expected |  |
| Table 6, Eq. 2: PeakTime (stepinfo) | 0.0305 | 0.020524 | 0.0005 | info | differs | end of the step-plot horizon (monotone approach) |
| Table 6, Eq. 32: RiseTime (stepinfo) | 0.0042 | 0.0041917 | 0.0001 | match | as expected |  |
| Table 6, Eq. 32: SettlingTime (stepinfo) | 0.0078 | 0.0077909 | 0.0001 | match | as expected | stepinfo TransientTime; SettlingTime = 0.008926 s |
| Table 6, Eq. 32: SettlingMin (stepinfo) | 72.032 | 72.032 | 0.2 | match | as expected |  |
| Table 6, Eq. 32: SettlingMax (stepinfo) | 79.938 | 79.938 | 0.05 | match | as expected |  |
| Table 6, Eq. 32: Overshoot (stepinfo) | 0 | 0 | 0.05 | match | as expected |  |
| Table 6, Eq. 32: Undershoot (stepinfo) | 81.27 | 81.27 | 0.05 | match | as expected |  |
| Table 6, Eq. 32: Peak (stepinfo) | 79.938 | 79.938 | 0.05 | match | as expected |  |
| Table 6, Eq. 32: PeakTime (stepinfo) | 0.0151 | 0.015116 | 0.0005 | info | close | end of the step-plot horizon (monotone approach) |
| Table 8: I_L,avg,max (A) | 8 | 8 | 1e-09 | match | as expected | Eq. 46 |
| Table 8: inductor ripple (A) | 1.6 | 1.6 | 1e-09 | match | as expected | Eq. 47 |
| Table 8: L (mH) | 0.3125 | 0.3125 | 1e-09 | match | as expected | Eq. 48 |
| Table 8: output ripple (V) | 1.6 | 1.6 | 1e-09 | match | as expected | Eq. 49 |
| Table 8: C (uF) | 62.5 | 62.5 | 1e-09 | match | as expected | Eq. 50 |
| Eq. 32 RHP zero (rad/s) vs Eq. 31 with Table 3 | 500 | 40000 | 50 | differs | as expected | only some coefficients of Eq. 31 were divided by 80 |
| Eq. 32 damping ratio vs Eq. 31 with Table 3 | 2.3837 | 0.029796 | 0.1 | differs | as expected | Eq. 31: LC resonance at 2384 rad/s |
| Eq. 40 DC gain (A per unit duty) vs Eq. 39 | 1600 | 20 | 1 | differs | as expected |  |
| Eq. 51 RHP zero (rad/s) vs Eq. 31 with Table 8 | 800 | 8000 | 50 | differs | as expected | printed s-coefficient 10x too large |
| Eq. 2 RHP zero (rad/s) vs Eq. 31 with Table 3 | 473.58 | 40000 | 50 | differs | as expected | see the frestimate checks |
| Reference loop, printed Eq. 51 + Eq. 52: max Re(pole) (rad/s) | - | 182.4 | 0 | positive | as expected | unstable reference model |
| Reference loop, Eq. 51 from Table 8 + Eq. 52: max Re(pole) (rad/s) | - | -457.9 | 0 | negative | as expected | used in the recreation |
| Single PI (Eq. 33) on printed Eq. 2: max Re(pole) (rad/s) | - | -155.62 | 0 | negative | as expected |  |
| Single PI (Eq. 33) on printed Eq. 32: max Re(pole) (rad/s) | - | -156.94 | 0 | negative | as expected |  |
| Single PI (Eq. 33) on Eq. 31 (Table 3): max Re(pole) (rad/s) | - | 52.852 | 0 | positive | as expected | unstable on the lossless converter |
