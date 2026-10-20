## Paper checks (matlab_script): all as expected

| Check | Paper | Recreated | Tolerance | Expected | Result | Note |
|---|---|---|---|---|---|---|
| Fig. 7: circuit model, cold-start peak (V) (fig.) | 76 | 76.527 | 1.5 | match | as expected |  |
| Fig. 7: circuit model, mean over 40-50 ms (V) (fig.) | 40 | 39.992 | 0.5 | match | as expected |  |
| Fig. 13: tracking-error peak after 0.2 s, gamma = 0.1 (V) (fig.) | 7 | 7.0536 | 1 | match | as expected |  |
| Fig. 13: tracking-error peak after 0.2 s, gamma = 1 (V) (fig.) | 6 | 5.6259 | 1 | match | as expected |  |
| Fig. 14: theta before 0.2 s, gamma = 0.1 (fig.) | 0.95 | 0.94196 | 0.1 | match | as expected |  |
| Fig. 14: theta before 0.2 s, gamma = 0.5 (fig.) | 0.755 | 0.71035 | 0.1 | match | as expected |  |
| Fig. 14: theta before 0.2 s, gamma = 1 (fig.) | 0.505 | 0.42612 | 0.1 | match | as expected |  |
| Fig. 14: theta at 0.26 s, gamma = 0.1 (fig.) | 0.9 | 0.88942 | 0.1 | match | as expected |  |
| Fig. 14: theta at 0.26 s, gamma = 0.5 (fig.) | 0.5 | 0.45697 | 0.1 | match | as expected |  |
| Fig. 14: theta at 0.26 s, gamma = 1 (fig.) | 0.12 | 0.10323 | 0.1 | match | as expected |  |
| Fig. 15: gamma = 1 diverges after 0.4 s, minimum over 0.5-0.6 s (V) (fig.) | 33 | 31.723 | 3 | match | as expected |  |
| Fig. 15: gamma = 1, maximum over 0.5-0.6 s (V) (fig., axis ends at 70 V) | 68 | 73.262 | 0 | at_least | as expected |  |
| Fig. 15: gamma = 0.5 stays regulated near 50 V, maximum over 0.5-0.6 s (V) (fig.) | 50 | 50.11 | 1 | match | as expected |  |
| Fig. 16: single PI, start-up peak (V) (fig.) | 52.5 | 51.426 | 2.5 | match | as expected |  |
| Fig. 16: single PI, start-up dip (V) (fig.) | 28 | 26.072 | 2.5 | match | as expected |  |
| Fig. 16: cascade PI, start-up peak (V) (fig.) | 46.5 | 45.619 | 2 | match | as expected |  |
| Fig. 16: cascade PI, start-up dip (V) (fig.) | 38.5 | 36.969 | 2 | match | as expected |  |
| Fig. 16: cascade PI, dip after 16 -> 10 Ohm (V) (fig.) | 37.8 | 37.645 | 0.5 | match | as expected |  |
| Fig. 16: cascade PI, peak after 16 -> 10 Ohm (V) (fig.) | 40.9 | 41.045 | 0.5 | match | as expected |  |
| Fig. 16: MRAC as written, dip after 16 -> 10 Ohm (V) (fig.) | 38.6 | 37.843 | 0.5 | info | differs | paper MRAC dips less than its cascade PI |
| Table 10: cascade PI, peak (V) | 44.697 | 44.616 | 0.5 | match | as expected | 30 -> 40 V step at 0.2 s |
| Table 10: cascade PI, overshoot (% of 40 V) | 11.742 | 11.541 | 1.5 | match | as expected |  |
| Table 10: cascade PI, peak time (s) | 0.0028 | 0.00285 | 0.0005 | match | as expected |  |
| Table 10: cascade PI, rise time (s) | 0.0012 | 0.00097782 | 0.0003 | info | close |  |
| Table 10: cascade PI, settling time (s) | 0.0064 | 0.018265 | 0.002 | info | differs | definition not stated |
| Table 10: MRAC peak (V) vs MRAC as written (Eqs. 54-56) | 41.485 | 44.571 | 0.5 | differs | as expected | as written it behaves like the cascade PI |
| Table 10: MRAC peak (V) vs model-following set-point | 41.485 | 41.746 | 0.5 | match | as expected |  |
| Table 10: MRAC overshoot (% of 40 V) vs model-following set-point | 3.7125 | 4.3649 | 1.5 | match | as expected |  |
| Table 10: single PI, peak (V) | 40.164 | 41.013 | 0.5 | info | differs | limit cycle with lossless devices |
