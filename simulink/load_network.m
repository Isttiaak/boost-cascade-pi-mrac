function [Rbase, Ra, Rb, ga, gb] = load_network(R)
%LOAD_NETWORK  Switched-resistor network that realises a load profile.
%   [Rbase, Ra, Rb, ga, gb] = load_network([R1 R2 R3])
%
%   Specialized Power Systems has no variable resistor, so the load of the
%   circuit plant is a fixed resistor Rbase plus two resistors Ra and Rb that
%   ideal switches connect in parallel. ga and gb (1x3, 0/1) are the switch
%   states during the three intervals of the profile, so that
%       1/R(k) = 1/Rbase + ga(k)/Ra + gb(k)/Rb.
%   Unused branches get 1 MOhm and stay open.
R = R(:).';
assert(numel(R) == 3 && all(R > 0), 'load_network:input', ...
    'Expected three positive load values.');
G = 1 ./ R;
lv = uniquetol(G, 1e-12);          % distinct conductances, ascending
Rbase = 1 / lv(1);
Ra = 1e6;
Rb = 1e6;
ga = zeros(1, 3);
gb = zeros(1, 3);
if numel(lv) >= 2
    Ra = 1 / (lv(2) - lv(1));
    ga = double(G >= lv(2) - 1e-12);
end
if numel(lv) == 3
    Rb = 1 / (lv(3) - lv(2));
    gb = double(G >= lv(3) - 1e-12);
end
end
