function [num, den] = pi_unity_feedback(Kp, Ki, gnum, gden)
%PI_UNITY_FEEDBACK  Closed loop C G / (1 + C G) with C(s) = (Kp s + Ki)/s.
%   Used for the reference model of the paper: Eq. 52 PI around Eq. 51.
nol = conv([Kp Ki], gnum(:).');
dol = conv([1 0], gden(:).');
nol = [zeros(1, numel(dol) - numel(nol)) nol];
den = dol + nol;
num = nol;
while numel(num) > 1 && num(1) == 0
    num(1) = [];
end
end
