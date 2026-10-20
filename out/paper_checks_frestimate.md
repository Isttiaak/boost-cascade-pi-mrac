## Paper checks (frestimate): all as expected

| Check | Paper | Recreated | Tolerance | Expected | Result | Note |
|---|---|---|---|---|---|---|
| Eq. 2 RHP zero (rad/s) vs frestimate, amplitude 0.03 | 473.58 | 17719 | 236.788 | differs | as expected | paper procedure |
| Eq. 2 damping ratio vs frestimate, amplitude 0.03 | 2.5922 | 0.404 | 0.5 | differs | as expected | converter enters DCM near resonance |
| Eq. 2 DC gain vs frestimate, amplitude 0.03 | 76.439 | 80.292 | 2 | info | differs |  |
| Eq. 31 resonance (rad/s) vs frestimate, amplitude 0.0005 | 2383.7 | 2383.1 | 50 | match | as expected | paper's own formula, not a printed number |
| Eq. 31 damping ratio vs frestimate, amplitude 0.0005 | 0.029796 | 0.03056 | 0.01 | match | as expected | paper's own formula |
| Eq. 31 DC gain vs frestimate, amplitude 0.0005 | 80 | 81.359 | 3 | match | as expected | paper's own formula |
