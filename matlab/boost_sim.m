function res = boost_sim(T_end, plant, ctrl, prm, opts)
%BOOST_SIM  Boost converter + controller simulation (plain MATLAB, no Simulink).
%
%   res = boost_sim(T_end, plant, ctrl, prm, opts)
%
%   plant : 'average'   large-signal state-space-averaged model (Eqs. 3-9)
%           'switching' circuit model, PWM, switch + diode (DCM capable)
%   ctrl  : 'open'      open loop, duty from opts.duty
%           'pi'        single PI                    (Eq. 33)
%           'cascade'   cascade PI                   (Eqs. 42-43)
%           'mrac'      cascade PI-based MRAC as written (Eqs. 44, 54-56)
%           'mrac_ms'   same, cascade tracks the reference-model output
%   prm   : struct from boost_params()
%   opts  : struct, optional fields
%           vref, vin, rload, duty  - scalar, function handle f(t) or vector (length N)
%           gamma                   - learning rate (default 0.04)
%           gains                   - [Kp1 Ki1 Kp2 Ki2] (default: paper gains)
%           ref_variant             - 'derived' (default) or 'printed' Eq. 51
%
%   res fields: t, v, iL, d, theta, ym, iref, v_meas, i_meas, v_avg, iL_avg,
%               vref, vin, rload, x_end = [iL v] at T_end.
%
%   The controller runs every Ts = 1/(10 fsw); integrators use Ts*z/(z-1).

P = paper_values();
if nargin < 5, opts = struct(); end
if ~isfield(opts, 'vref'),  opts.vref = 40; end
if ~isfield(opts, 'vin'),   opts.vin = P.Vdc; end
if ~isfield(opts, 'rload'), opts.rload = P.R; end
if ~isfield(opts, 'duty'),  opts.duty = 0.5; end
if ~isfield(opts, 'gamma'), opts.gamma = P.gamma_design; end
if ~isfield(opts, 'ref_variant'), opts.ref_variant = 'derived'; end
if ~isfield(opts, 'gains')
    if strcmp(ctrl, 'pi')
        opts.gains = [P.pi_single.Kp P.pi_single.Ki 0 0];
    else
        opts.gains = [P.pi_outer.Kp P.pi_outer.Ki P.pi_inner.Kp P.pi_inner.Ki];
    end
end

Ts = prm.Ts;
N = round(T_end / Ts);
t = (0:N-1)' * Ts;
vref  = profile(opts.vref, t);
vin   = profile(opts.vin, t);
rload = profile(opts.rload, t);
dol   = profile(opts.duty, t);

plant_id = find(strcmp(plant, {'average', 'switching'})) - 1;
ctrl_id  = find(strcmp(ctrl, {'open', 'pi', 'cascade', 'mrac', 'mrac_ms'})) - 1;
assert(~isempty(plant_id) && ~isempty(ctrl_id), 'unknown plant or controller');

% reference model T_m(z) (Tustin), direct form II transposed
[nT, dT] = ref_model_tf(opts.ref_variant);
[bz, az] = tfdata(c2d(tf(nT, dT), Ts, 'tustin'), 'v');
bz = bz / az(1);  az = az / az(1);
nz = numel(bz);  zs = zeros(1, nz);

Kp1 = opts.gains(1); Ki1 = opts.gains(2); Kp2 = opts.gains(3); Ki2 = opts.gains(4);
gam = opts.gamma;
L = prm.L; C = prm.C; rL = prm.rL; Ron = prm.Ron; Vf = prm.Vf; Rd = prm.Rd;
uni = prm.unidirectional; dmin = prm.dmin; dmax = prm.dmax; aw = prm.anti_windup;
if prm.fc_v > 0, av_v = 1 - exp(-2*pi*prm.fc_v*Ts); else, av_v = 1; end
if prm.fc_i > 0, av_i = 1 - exp(-2*pi*prm.fc_i*Ts); else, av_i = 1; end
nper = round(1 / (prm.fsw * Ts));

o = zeros(N, 10);   % v iL d theta ym iref vmeas imeas vavg iavg
iL = prm.iL0; v = prm.v0; I1 = 0; I2 = 0; th = prm.theta0;
vm = v; im = iL; d_latched = 0;

for k = 1:N
    Vin = vin(k); Rl = rload(k);
    % ---- measurement -------------------------------------------------------
    vm = vm + av_v * (v - vm);
    im = im + av_i * (iL - im);
    % ---- reference model ------------------------------------------------------
    r = vref(k);
    ym = bz(1) * r + zs(1);
    for j = 1:nz-2
        zs(j) = bz(j+1) * r - az(j+1) * ym + zs(j+1);
    end
    zs(nz-1) = bz(nz) * r - az(nz) * ym;
    % ---- controller ------------------------------------------------------------
    iref = 0;
    if ctrl_id == 0
        u = dol(k);
    elseif ctrl_id == 1
        e = r - vm;
        I1n = I1 + Ki1 * Ts * e;
        u = Kp1 * e + I1n;
        if aw == 1 && ((u > dmax && e > 0) || (u < dmin && e < 0))
            u = Kp1 * e + I1;
        else
            I1 = I1n;
        end
    else
        if ctrl_id == 4
            e = ym - vm;          % model-following set-point
        else
            e = r - vm;           % Eq. (54) / Fig. 12
        end
        I1 = I1 + Ki1 * Ts * e;
        iref = Kp1 * e + I1;
        ei = iref - im;
        I2n = I2 + Ki2 * Ts * ei;
        upi = Kp2 * ei + I2n;
        if ctrl_id >= 3
            et = vm - ym;                     % Eq. (56)
            th = th - gam * Ts * et * ym;     % MIT rule, Eqs. (44)/(55)
            u = th * upi;
            sgn = th;
        else
            u = upi;
            sgn = 1;
        end
        if aw == 1 && ((u > dmax && ei*sgn > 0) || (u < dmin && ei*sgn < 0))
            upi = Kp2 * ei + I2;
            if ctrl_id >= 3, u = th * upi; else, u = upi; end
        else
            I2 = I2n;
        end
    end
    d = min(max(u, dmin), dmax);
    o(k, 1:8) = [v iL d th ym iref vm im];

    % ---- plant over [t_k, t_k + Ts] ------------------------------------------------
    sv = 0; si = 0;
    if plant_id == 0
        h = Ts / prm.nsub_avg; dp = 1 - d; rs = rL + d*Ron + dp*Rd;
        for s = 1:prm.nsub_avg
            io = iL; vo = v;
            [k1i, k1v] = favg(iL, v);
            [k2i, k2v] = favg(iL + 0.5*h*k1i, v + 0.5*h*k1v);
            [k3i, k3v] = favg(iL + 0.5*h*k2i, v + 0.5*h*k2v);
            [k4i, k4v] = favg(iL + h*k3i, v + h*k3v);
            iL = iL + h/6 * (k1i + 2*k2i + 2*k3i + k4i);
            v  = v  + h/6 * (k1v + 2*k2v + 2*k3v + k4v);
            if uni == 1 && iL < 0, iL = 0; end
            sv = sv + 0.5*h*(vo + v);  si = si + 0.5*h*(io + iL);
        end
    else
        kk = mod(k-1, nper);
        if kk == 0, d_latched = d; end
        if prm.pwm_mode == 0, upwm = d; else, upwm = d_latched; end
        frac = min(max((upwm - kk/nper) * nper, 0), 1);
        ton = frac * Ts;
        for piece = 1:2
            if piece == 1, Tp = ton; on = true; else, Tp = Ts - ton; on = false; end
            if Tp <= 0, continue; end
            ns = ceil(Tp / prm.hmax_sw);  h = Tp / ns;
            for s = 1:ns
                io = iL; vo = v;
                if on
                    [k1i, k1v] = fon(iL, v);
                    [k2i, k2v] = fon(iL + 0.5*h*k1i, v + 0.5*h*k1v);
                    [k3i, k3v] = fon(iL + 0.5*h*k2i, v + 0.5*h*k2v);
                    [k4i, k4v] = fon(iL + h*k3i, v + h*k3v);
                else
                    if uni == 1 && iL <= 0 && (Vin - Vf - v) <= 0     % DCM: diode blocks
                        iL = 0;  v = v * exp(-h / (Rl*C));
                        sv = sv + 0.5*h*(vo + v);
                        continue
                    end
                    [k1i, k1v] = foff(iL, v);
                    [k2i, k2v] = foff(iL + 0.5*h*k1i, v + 0.5*h*k1v);
                    [k3i, k3v] = foff(iL + 0.5*h*k2i, v + 0.5*h*k2v);
                    [k4i, k4v] = foff(iL + h*k3i, v + h*k3v);
                end
                iL = iL + h/6 * (k1i + 2*k2i + 2*k3i + k4i);
                v  = v  + h/6 * (k1v + 2*k2v + 2*k3v + k4v);
                if ~on && uni == 1 && iL < 0, iL = 0; end
                sv = sv + 0.5*h*(vo + v);  si = si + 0.5*h*(io + iL);
            end
        end
    end
    o(k, 9:10) = [sv si] / Ts;
end

res.t = t;
names = {'v','iL','d','theta','ym','iref','v_meas','i_meas','v_avg','iL_avg'};
for j = 1:numel(names), res.(names{j}) = o(:, j); end
res.vref = vref; res.vin = vin; res.rload = rload;
res.x_end = [iL v];

    % ---------- nested derivative functions (see the paper's Table 4/5) ---------
    function [di, dv] = favg(i_, v_)
        di = (Vin - rs*i_ - dp*(v_ + Vf)) / L;
        dv = (dp*i_ - v_/Rl) / C;
        if uni == 1 && i_ <= 0 && di < 0, di = 0; end
    end
    function [di, dv] = fon(i_, v_)
        di = (Vin - (rL + Ron)*i_) / L;
        dv = -v_ / (Rl*C);
    end
    function [di, dv] = foff(i_, v_)
        if uni == 1, vf_ = Vf; rd_ = Rd; else, vf_ = 0; rd_ = 0; end
        di = (Vin - (rL + rd_)*i_ - vf_ - v_) / L;
        dv = (i_ - v_/Rl) / C;
    end
end

function x = profile(spec, t)
if isa(spec, 'function_handle')
    x = spec(t);
elseif isscalar(spec)
    x = spec * ones(size(t));
else
    x = spec(:);
    x = x(1:numel(t));
end
x = x(:);
end
