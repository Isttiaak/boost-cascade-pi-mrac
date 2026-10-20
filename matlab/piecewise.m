function y = piecewise(t, times, values)
%PIECEWISE  Piecewise-constant profile: values(j) for t >= times(j).
y = values(1) * ones(size(t));
for j = 1:numel(times)
    y(t >= times(j)) = values(j);
end
end
