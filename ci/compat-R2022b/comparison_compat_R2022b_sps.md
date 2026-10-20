## MATLAB reference (matlab/boost_sim.m) vs compat_R2022b_sps: PASS

38 of 38 gating metrics within tolerance; 5 informational metrics listed for reference.

| Scenario | Metric | Reference | compat_R2022b_sps | Difference | Tolerance | Gating | Result |
|---|---|---|---|---|---|---|---|
| exp_cascade | Overshoot | 43.723 | 43.28 | -0.443 | max(1.5, 0%) | yes | ok |
| exp_cascade | Peak | 46.558 | 46.492 | -0.0664 | max(0.5, 1.5%) | yes | ok |
| exp_cascade | PeakTime | 0.0027 | 0.00285 | 0.00015 | max(0.0001, 10%) | yes | ok |
| exp_cascade | RiseTime | 0.0010425 | 0.00105 | 7.45e-06 | max(0.0001, 10%) | yes | ok |
| exp_cascade | SettlingTime | 0.015151 | 0.01485 | -0.000301 | max(0.001, 25%) | no | ok |
| f16_cascade | ls_max | 41.045 | 40.968 | -0.0766 | max(0.5, 1.5%) | yes | ok |
| f16_cascade | ls_min | 37.645 | 37.591 | -0.0541 | max(0.5, 1.5%) | yes | ok |
| f16_cascade | osc_amp | 0.041828 | 0.0586 | 0.0168 | max(0.05, 25%) | no | ok |
| f16_cascade | su_min | 36.969 | 36.946 | -0.0237 | max(0.5, 1.5%) | yes | ok |
| f16_cascade | su_peak | 45.619 | 45.628 | 0.00924 | max(0.5, 1.5%) | yes | ok |
| f16_cascade | su_tpeak | 0.0021 | 0.00205 | -5e-05 | max(0.0001, 10%) | yes | ok |
| f18_cascade | Overshoot | 11.541 | 11.6 | 0.059 | max(1.5, 0%) | yes | ok |
| f18_cascade | Peak | 44.616 | 44.64 | 0.0236 | max(0.5, 1.5%) | yes | ok |
| f18_cascade | PeakTime | 0.00285 | 0.00285 | 0 | max(0.0001, 10%) | yes | ok |
| f18_cascade | RiseTime | 0.00097782 | 0.00097776 | -5.57e-08 | max(0.0001, 10%) | yes | ok |
| f18_cascade | SettlingMax | 44.616 | 44.64 | 0.0236 | max(0.5, 1.5%) | yes | ok |
| f18_cascade | SettlingMin | 36.044 | 36.046 | 0.00147 | max(0.5, 1.5%) | yes | ok |
| f18_cascade | SettlingTime | 0.018265 | 0.015841 | -0.00242 | max(0.001, 25%) | no | ok |
| f18_cascade | step3_peak | 54.568 | 54.544 | -0.0232 | max(0.5, 1.5%) | yes | ok |
| f18_mrac_mf | Overshoot | 4.3649 | 4.5504 | 0.186 | max(1.5, 0%) | yes | ok |
| f18_mrac_mf | Peak | 41.746 | 41.82 | 0.0742 | max(0.5, 1.5%) | yes | ok |
| f18_mrac_mf | PeakTime | 0.0042 | 0.00425 | 5e-05 | max(0.0001, 10%) | yes | ok |
| f18_mrac_mf | RiseTime | 0.0021736 | 0.0021803 | 6.72e-06 | max(0.0001, 10%) | yes | ok |
| f18_mrac_mf | SettlingMax | 41.746 | 41.82 | 0.0742 | max(0.5, 1.5%) | yes | ok |
| f18_mrac_mf | SettlingMin | 36.009 | 36.036 | 0.0275 | max(0.5, 1.5%) | yes | ok |
| f18_mrac_mf | SettlingTime | 0.013015 | 0.013565 | 0.00055 | max(0.001, 25%) | no | ok |
| f18_mrac_mf | step3_peak | 51.931 | 52.062 | 0.131 | max(0.5, 1.5%) | yes | ok |
| f18_mrac | Overshoot | 11.427 | 11.43 | 0.00287 | max(1.5, 0%) | yes | ok |
| f18_mrac | Peak | 44.571 | 44.572 | 0.00115 | max(0.5, 1.5%) | yes | ok |
| f18_mrac | PeakTime | 0.0028 | 0.00275 | -5e-05 | max(0.0001, 10%) | yes | ok |
| f18_mrac | RiseTime | 0.00097742 | 0.00096963 | -7.79e-06 | max(0.0001, 10%) | yes | ok |
| f18_mrac | SettlingMax | 44.571 | 44.572 | 0.00115 | max(0.5, 1.5%) | yes | ok |
| f18_mrac | SettlingMin | 36.051 | 35.982 | -0.0695 | max(0.5, 1.5%) | yes | ok |
| f18_mrac | SettlingTime | 0.021816 | 0.015301 | -0.00652 | max(0.001, 25%) | no | differs |
| f18_mrac | step3_peak | 54.586 | 54.615 | 0.0295 | max(0.5, 1.5%) | yes | ok |
| lr_g0.5 | emax_step | 6.8865 | 6.9608 | 0.0743 | max(0.3, 0%) | yes | ok |
| lr_g0.5 | emin_step | -2.4142 | -2.453 | -0.0388 | max(0.3, 0%) | yes | ok |
| lr_g0.5 | theta_t0199 | 0.71035 | 0.71108 | 0.000727 | max(0.01, 0%) | yes | ok |
| lr_g0.5 | theta_t0260 | 0.45697 | 0.45586 | -0.00111 | max(0.01, 0%) | yes | ok |
| lr_g0.5 | theta_t0399 | 0.44241 | 0.44245 | 4.37e-05 | max(0.01, 0%) | yes | ok |
| lr_g0.5 | theta_t0599 | 0.15119 | 0.14664 | -0.00455 | max(0.01, 0%) | yes | ok |
| lr_g0.5 | vmax_tail | 50.11 | 50.112 | 0.00149 | max(0.5, 1.5%) | yes | ok |
| lr_g0.5 | vmin_tail | 49.892 | 49.893 | 0.0011 | max(0.5, 1.5%) | yes | ok |
