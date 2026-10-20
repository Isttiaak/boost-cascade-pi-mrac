function axi = add_inset(ax, pos, xl, yl, X, Y, colors, styles)
%ADD_INSET  Zoom inset inside axes AX (pos = [x y w h] in normalised AX units).
%   X, Y are cell arrays of vectors; only the part inside xl is plotted.
p = ax.Position;
axi = axes('Position', [p(1) + pos(1)*p(3), p(2) + pos(2)*p(4), pos(3)*p(3), pos(4)*p(4)]);
hold(axi, 'on'); box(axi, 'on'); grid(axi, 'on');
for k = 1:numel(X)
    m = X{k} >= xl(1) & X{k} <= xl(2);
    plot(axi, X{k}(m), Y{k}(m), styles{k}, 'Color', colors{k}, 'LineWidth', 0.9);
end
xlim(axi, xl); ylim(axi, yl);
axi.FontSize = 7;
% outline the zoomed region on the main axes
rectangle(ax, 'Position', [xl(1) yl(1) diff(xl) diff(yl)], 'EdgeColor', [0.5 0.5 0.5]);
end
