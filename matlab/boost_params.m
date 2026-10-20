function prm = boost_params(varargin)
%BOOST_PARAMS  Circuit and control parameters used by BOOST_SIM.
%   prm = boost_params()                     Table 3 values, ideal switch and diode
%   prm = boost_params('Ron',0.1,'Vf',0.8)   override any field (name/value pairs)
%
%   Simulink (Specialized Power Systems) default devices, for a sensitivity run:
%       boost_params('Ron', 0.1, 'Rd', 0.001, 'Vf', 0.8)

P = paper_values();
prm.L = P.L;  prm.C = P.C;  prm.fsw = P.fsw;  prm.Ts = P.Ts;
prm.rL = 0;  prm.Ron = 0;  prm.Vf = 0;  prm.Rd = 0;   % parasitics (Table 3 lists none)
prm.unidirectional = 1;   % 1: diode (DCM possible), 0: ideal bidirectional switch
prm.pwm_mode = 0;         % 0: carrier compared with u every Ts, 1: duty latched once per period
prm.nsub_avg = 2;         % RK4 sub-steps per Ts for the averaged plant
prm.hmax_sw = 1e-6;       % max RK4 step inside switching intervals [s]
prm.dmin = 0;  prm.dmax = 0.9;   % duty-cycle limiter (Fig. 19)
prm.anti_windup = 0;      % 0: none (Simulink PID default), 1: clamping
prm.fc_v = 0;  prm.fc_i = 0;     % optional measurement low-pass [Hz], 0 = off
prm.theta0 = 1;           % initial adaptation parameter
prm.iL0 = 0;  prm.v0 = 0; % initial state (cold start)

for k = 1:2:numel(varargin)
    prm.(varargin{k}) = varargin{k+1};
end
end
