function [bz, az] = tustin_tf(num, den, Ts)
%TUSTIN_TF  Bilinear (Tustin) discretisation of num(s)/den(s), paper Eq. 53.
%   [bz, az] = tustin_tf(num, den, Ts) substitutes s = (2/Ts)(z-1)/(z+1).
%   Coefficients are in descending powers of z, normalised so az(1) = 1,
%   ready for a Discrete Transfer Fcn block. Same result as
%   c2d(tf(num, den), Ts, 'tustin'), without the Control System Toolbox.
n = numel(den) - 1;
num = [zeros(1, n + 1 - numel(num)) num(:).'];
den = den(:).';
c = 2 / Ts;
bz = zeros(1, n + 1);
az = zeros(1, n + 1);
for k = 0:n                       % coefficient of s^k sits at index n+1-k
    term = 1;
    for j = 1:k
        term = conv(term, [1 -1]);
    end
    for j = 1:(n - k)
        term = conv(term, [1 1]);
    end
    bz = bz + num(n + 1 - k) * c^k * term;
    az = az + den(n + 1 - k) * c^k * term;
end
bz = bz / az(1);
az = az / az(1);
end
