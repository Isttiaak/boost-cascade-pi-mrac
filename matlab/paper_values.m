function P = paper_values()
%PAPER_VALUES  Numbers exactly as printed in Yanarates & Zhou, IEEE Access 10 (2022) 44909-44922.
%   P = paper_values() returns a struct with Table 3, Eqs. 2/32/40/41/51/52,
%   controller gains and the Table 6 / Table 10 results.

% ---- Table 3 ---------------------------------------------------------------
P.Vdc  = 20;          % input voltage [V]
P.fsw  = 20e3;        % switching frequency [Hz]
P.L    = 100e-6;      % inductance [H]
P.C    = 440e-6;      % output capacitance [F]
P.Vout = 40;          % output voltage [V]
P.R    = 16;          % load [Ohm]
P.D    = 1 - P.Vdc/P.Vout;   % Eq. (1) -> 0.5
P.Ts   = 1/(10*P.fsw);       % controller / discretisation sample time
P.perturb_amp = 0.03;        % duty perturbation used for FR estimation

% ---- printed transfer functions --------------------------------------------
P.eq2_num  = [-1.018e06 4.821e08];         P.eq2_den  = [1 1.302e04 6.307e06];
P.eq32_num = [-0.002 1];                    P.eq32_den = [2.2e-09 2.5e-05 0.0125];
P.eq40_num = [0.00176 40];                  P.eq40_den = [4.4e-09 5e-05 0.025];
P.eq41_num = [-8.8e-12 -9.56e-08 0 0.025];  P.eq41_den = [3.872e-12 1.32e-07 0.001022 0.5];

% ---- controllers -------------------------------------------------------------
P.pi_single = struct('Kp', 0.0114, 'Ki', 2.82);    % Eq. (33)
P.pi_outer  = struct('Kp', 0.15,   'Ki', 1000);    % Eq. (42)
P.pi_inner  = struct('Kp', 0.5,    'Ki', 5);       % Eq. (43)
P.gamma_design = 0.04;
P.gammas_study = [0.1 0.5 1];

% ---- reference model (Table 8, Eqs. 51-52) -----------------------------------
P.ref_Rmin = 10; P.ref_D = 0.5; P.ref_L = 0.3125e-3; P.ref_C = 62.5e-6;
P.eq51_num = [-0.0625 50];  P.eq51_den = [4.88e-08 7.813e-05 0.625];
P.eq52 = struct('Kp', 0.000005, 'Ki', 7.5);

% ---- Table 6 (columns: Rise Settling SetMin SetMax OS US Peak PeakTime) ------
P.table6_names = {'Simulink Control Design (Eq. 2)', 'State-space averaging (Eq. 32)'};
P.table6 = [0.0044 0.0081 68.8104 76.4336 0 85.1766 76.4336 0.0305;
            0.0042 0.0078 72.0324 79.9377 0 81.2702 79.9377 0.0151];

% ---- Table 10 ------------------------------------------------------------------
P.table10_names = {'Single PI', 'Cascade PI', 'Cascade PI-based MRAC'};
P.table10 = [5.9e-4 0.0079  33.69  40.164 0.41    3.16 40.164 0.001;
             0.0012 0.0064  37.564 44.697 11.7425 0.1  44.697 0.0028;
             0.0014 0.00145 39.7   41.485 3.7125  0    41.485 0.0025];
P.metric_names = {'RiseTime','SettlingTime','SettlingMin','SettlingMax', ...
                  'Overshoot','Undershoot','Peak','PeakTime'};
end
