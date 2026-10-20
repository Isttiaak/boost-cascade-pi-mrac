function [num, den, fitpct] = fit_tf_1z2p(w, H)
%FIT_TF_1Z2P  Fit G(s) = (b1 s + b0)/(s^2 + a1 s + a0) to complex data H(jw).
%   Levy least squares, Sanathanan-Koerner iterations, then an fminsearch
%   polish of the relative complex error (no extra toolbox needed).
%   Comparable to tfest(data, 2, 1) of the System Identification Toolbox.
w = w(:); H = H(:); s = 1i*w;
x = solve_ls(ones(size(w)));
for it = 1:30
    x = solve_ls(1 ./ abs(s.^2 + x(3)*s + x(4)));
end
cost = @(z) sum(abs(((z(1)*s + z(2)) ./ (s.^2 + z(3)*s + z(4)) - H) ./ abs(H)).^2);
sc = abs(x) + 1e-12;
z = fminsearch(@(q) cost(q .* sc), ones(4,1), optimset('MaxFunEvals', 2e4, 'MaxIter', 2e4, 'TolX', 1e-10, 'TolFun', 1e-14));
x = z .* sc;
num = [x(1) x(2)];  den = [1 x(3) x(4)];
G = polyval(num, s) ./ polyval(den, s);
fitpct = 100 * (1 - norm(H - G) / norm(H - mean(H)));

    function xx = solve_ls(wt)
        A = [s, ones(size(s)), -H.*s, -H] .* wt;
        b = (H .* s.^2) .* wt;
        xx = [real(A); imag(A)] \ [real(b); imag(b)];
    end
end
