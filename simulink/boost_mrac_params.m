function bm = boost_mrac_params(varargin)
%BOOST_MRAC_PARAMS  Parameters of the Simulink recreation of Yanarates & Zhou,
%   "Design and Cascade PI Controller-Based Robust Model Reference Adaptive
%   Control of DC-DC Boost Converter", IEEE Access 10 (2022) 44909-44922.
%
%   bm = boost_mrac_params()                    paper values (Table 3, Eqs. 33,
%                                               42, 43, 51-53)
%   bm = boost_mrac_params('gamma', 0.1, ...)   override fields (name/value)
%   bm = boost_mrac_params(bm0, 'gamma', 0.1)   start from an existing struct
%
%   The struct is also stored in the base workspace as BM. Every block of the
%   models made by BUILD_BOOST_MODELS reads its parameters from it, for
%   example the inductor uses BM.L and the outer PI uses BM.Kp_o and BM.Ki_o.
%
%   Profiles (reference, input voltage, load) are value triples with two
%   switching times:  x(t) = x(1) for t < t(1), x(2) for t(1) <= t < t(2),
%   x(3) for t >= t(2).  A time of 1e3 s means "never" in these studies.

if nargin >= 1 && isstruct(varargin{1})
    bm = varargin{1};
    varargin(1) = [];
else
    bm = defaults();
end
assert(mod(numel(varargin), 2) == 0, 'boost_mrac_params:args', ...
    'Overrides must be name/value pairs.');
for k = 1:2:numel(varargin)
    name = varargin{k};
    assert(isfield(bm, name), 'boost_mrac_params:unknownField', ...
        'Unknown parameter "%s".', name);
    bm.(name) = varargin{k + 1};
end
bm = derived(bm);
assignin('base', 'BM', bm);
end

% -------------------------------------------------------------------------
function bm = defaults()
% Table 3: design parameters of the converter
bm.Vin_nom = 20;          % input voltage [V]
bm.Vout_nom = 40;         % output voltage [V]
bm.fsw = 20e3;            % switching frequency [Hz]
bm.L = 100e-6;            % inductance [H]
bm.C = 440e-6;            % output capacitance [F]
bm.R_nom = 16;            % load [Ohm]

% Semiconductor devices of the Specialized Power Systems plant.
% Defaults are practically ideal; the Simscape Electrical defaults are
% Ron_sw = 0.1, Ron_d = 1e-3, Vf_d = 0.8 (see the loss-sensitivity study).
bm.Ron_sw = 1e-4;         % MOSFET on-resistance [Ohm]
bm.Ron_d = 1e-4;          % diode on-resistance [Ohm]
bm.Vf_d = 0;              % diode forward voltage [V]

% Controllers
bm.Kp_s = 0.0114;  bm.Ki_s = 2.82;   % single PI, Eq. 33
bm.Kp_o = 0.15;    bm.Ki_o = 1000;   % outer (voltage) PI, Eq. 42
bm.Kp_i = 0.5;     bm.Ki_i = 5;      % inner (current) PI, Eq. 43
bm.gamma = 0.04;                     % MIT-rule learning rate, Sec. IV-C
bm.theta0 = 1;                       % initial adaptation parameter
bm.dmin = 0;       bm.dmax = 0.9;    % duty-cycle limiter (Fig. 19)

% Reference model: reference converter of Table 8 (Eq. 51, numerator
% recomputed from Eq. 31 because the printed -0.0625 s gives an unstable
% reference loop) in unity feedback with the PI of Eq. 52.
bm.ref_plant_num = [-0.00625 50];
bm.ref_plant_den = [4.88e-08 7.813e-05 0.625];
bm.Kp_ref = 0.000005;
bm.Ki_ref = 7.5;

% Test profiles
bm.vref = [40 40 40];    bm.t_vref = [1e3 2e3];
bm.vin = [20 20 20];     bm.t_vin = [1e3 2e3];
bm.rload = [16 16 16];   bm.t_rload = [1e3 2e3];
bm.duty_ol = 0.5;        % open-loop duty (Fig. 7, frequency response)

% Initial state of the converter (cold start)
bm.iL0 = 0;
bm.v0 = 0;

% Differential-equation plant: lower limit of the inductor current.
% 0 = the diode blocks reverse current (DCM possible); -Inf = Fig. 6 as drawn.
bm.iL_min = 0;

% Solver
bm.reltol = 1e-5;
end

% -------------------------------------------------------------------------
function bm = derived(bm)
bm.D = 1 - bm.Vin_nom / bm.Vout_nom;          % Eq. 1
bm.Tsw = 1 / bm.fsw;
bm.Ts = 1 / (10 * bm.fsw);                     % Sec. IV-E: Ts = 1/(10 fsw)
[bm.ref_cl_num, bm.ref_cl_den] = pi_unity_feedback(bm.Kp_ref, bm.Ki_ref, ...
    bm.ref_plant_num, bm.ref_plant_den);
[bm.ref_bz, bm.ref_az] = tustin_tf(bm.ref_cl_num, bm.ref_cl_den, bm.Ts);  % Eq. 53
[bm.R_base, bm.R_a, bm.R_b, bm.g_a, bm.g_b] = load_network(bm.rload);
end
