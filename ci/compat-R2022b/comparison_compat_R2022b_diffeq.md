## MATLAB reference (matlab/boost_sim.m) vs compat_R2022b_diffeq: PASS

38 of 38 gating metrics within tolerance; 5 informational metrics listed for reference.

| Scenario | Metric | Reference | compat_R2022b_diffeq | Difference | Tolerance | Gating | Result |
|---|---|---|---|---|---|---|---|
| exp_cascade | Overshoot | 43.723 | 43.594 | -0.129 | max(1.5, 0%) | yes | ok |
| exp_cascade | Peak | 46.558 | 46.539 | -0.0194 | max(0.5, 1.5%) | yes | ok |
| exp_cascade | PeakTime | 0.0027 | 0.0028 | 0.0001 | max(0.0001, 10%) | yes | ok |
| exp_cascade | RiseTime | 0.0010425 | 0.0010351 | -7.39e-06 | max(0.0001, 10%) | yes | ok |
| exp_cascade | SettlingTime | 0.015151 | 0.01609 | 0.000939 | max(0.001, 25%) | no | ok |
| f16_cascade | ls_max | 41.045 | 40.972 | -0.0724 | max(0.5, 1.5%) | yes | ok |
| f16_cascade | ls_min | 37.645 | 37.763 | 0.118 | max(0.5, 1.5%) | yes | ok |
| f16_cascade | osc_amp | 0.041828 | 0.040469 | -0.00136 | max(0.05, 25%) | no | ok |
| f16_cascade | su_min | 36.969 | 36.914 | -0.0559 | max(0.5, 1.5%) | yes | ok |
| f16_cascade | su_peak | 45.619 | 45.66 | 0.0411 | max(0.5, 1.5%) | yes | ok |
| f16_cascade | su_tpeak | 0.0021 | 0.002 | -0.0001 | max(0.0001, 10%) | yes | ok |
| f18_cascade | Overshoot | 11.541 | 11.681 | 0.139 | max(1.5, 0%) | yes | ok |
| f18_cascade | Peak | 44.616 | 44.672 | 0.0558 | max(0.5, 1.5%) | yes | ok |
| f18_cascade | PeakTime | 0.00285 | 0.00275 | -0.0001 | max(0.0001, 10%) | yes | ok |
| f18_cascade | RiseTime | 0.00097782 | 0.00098164 | 3.82e-06 | max(0.0001, 10%) | yes | ok |
| f18_cascade | SettlingMax | 44.616 | 44.672 | 0.0558 | max(0.5, 1.5%) | yes | ok |
| f18_cascade | SettlingMin | 36.044 | 36.036 | -0.00785 | max(0.5, 1.5%) | yes | ok |
| f18_cascade | SettlingTime | 0.018265 | 0.01554 | -0.00272 | max(0.001, 25%) | no | ok |
| f18_cascade | step3_peak | 54.568 | 54.636 | 0.0683 | max(0.5, 1.5%) | yes | ok |
| f18_mrac_mf | Overshoot | 4.3649 | 4.2088 | -0.156 | max(1.5, 0%) | yes | ok |
| f18_mrac_mf | Peak | 41.746 | 41.684 | -0.0624 | max(0.5, 1.5%) | yes | ok |
| f18_mrac_mf | PeakTime | 0.0042 | 0.0042 | 0 | max(0.0001, 10%) | yes | ok |
| f18_mrac_mf | RiseTime | 0.0021736 | 0.0021734 | -1.68e-07 | max(0.0001, 10%) | yes | ok |
| f18_mrac_mf | SettlingMax | 41.746 | 41.684 | -0.0624 | max(0.5, 1.5%) | yes | ok |
| f18_mrac_mf | SettlingMin | 36.009 | 35.997 | -0.0123 | max(0.5, 1.5%) | yes | ok |
| f18_mrac_mf | SettlingTime | 0.013015 | 0.013615 | 0.0006 | max(0.001, 25%) | no | ok |
| f18_mrac_mf | step3_peak | 51.931 | 51.962 | 0.0311 | max(0.5, 1.5%) | yes | ok |
| f18_mrac | Overshoot | 11.427 | 11.623 | 0.195 | max(1.5, 0%) | yes | ok |
| f18_mrac | Peak | 44.571 | 44.649 | 0.0781 | max(0.5, 1.5%) | yes | ok |
| f18_mrac | PeakTime | 0.0028 | 0.00285 | 5e-05 | max(0.0001, 10%) | yes | ok |
| f18_mrac | RiseTime | 0.00097742 | 0.00097177 | -5.65e-06 | max(0.0001, 10%) | yes | ok |
| f18_mrac | SettlingMax | 44.571 | 44.649 | 0.0781 | max(0.5, 1.5%) | yes | ok |
| f18_mrac | SettlingMin | 36.051 | 36.035 | -0.016 | max(0.5, 1.5%) | yes | ok |
| f18_mrac | SettlingTime | 0.021816 | 0.015555 | -0.00626 | max(0.001, 25%) | no | differs |
| f18_mrac | step3_peak | 54.586 | 54.59 | 0.00419 | max(0.5, 1.5%) | yes | ok |
| lr_g0.5 | emax_step | 6.8865 | 6.9095 | 0.023 | max(0.3, 0%) | yes | ok |
| lr_g0.5 | emin_step | -2.4142 | -2.5028 | -0.0886 | max(0.3, 0%) | yes | ok |
| lr_g0.5 | theta_t0199 | 0.71035 | 0.71048 | 0.000126 | max(0.01, 0%) | yes | ok |
| lr_g0.5 | theta_t0260 | 0.45697 | 0.45657 | -0.000396 | max(0.01, 0%) | yes | ok |
| lr_g0.5 | theta_t0399 | 0.44241 | 0.44335 | 0.000939 | max(0.01, 0%) | yes | ok |
| lr_g0.5 | theta_t0599 | 0.15119 | 0.14922 | -0.00197 | max(0.01, 0%) | yes | ok |
| lr_g0.5 | vmax_tail | 50.11 | 50.425 | 0.314 | max(0.5, 1.5%) | yes | ok |
| lr_g0.5 | vmin_tail | 49.892 | 49.658 | -0.234 | max(0.5, 1.5%) | yes | ok |
