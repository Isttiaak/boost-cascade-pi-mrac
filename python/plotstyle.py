"""Shared matplotlib styling for all recreated figures (validated palette)."""
import os
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

FIG_DIR = os.path.join(os.path.dirname(__file__), "..", "results", "figures")
TAB_DIR = os.path.join(os.path.dirname(__file__), "..", "results", "tables")
os.makedirs(FIG_DIR, exist_ok=True)
os.makedirs(TAB_DIR, exist_ok=True)

# categorical slots 1-3 (validated all-pairs, light mode) + ink colours
C1, C2, C3, C4 = "#2a78d6", "#eb6834", "#1baf7a", "#eda100"
INK, INK2, MUTED = "#0b0b0b", "#52514e", "#898781"
GRID, AXIS, SURFACE = "#e1e0d9", "#c3c2b7", "#fcfcfb"

CTRL_COLORS = {"pi": C1, "cascade": C2, "mrac": C3, "mrac_ms": C4}
CTRL_LABELS = {"pi": "Single PI", "cascade": "Cascade PI", "mrac": "Cascade PI-MRAC (as written)",
               "mrac_ms": "Cascade PI-MRAC, model-following set-point"}

plt.rcParams.update({
    "figure.facecolor": "white",
    "axes.facecolor": SURFACE,
    "axes.edgecolor": AXIS,
    "axes.labelcolor": INK2,
    "axes.titlecolor": INK,
    "axes.grid": True,
    "grid.color": GRID,
    "grid.linewidth": 0.6,
    "grid.linestyle": "-",
    "xtick.color": INK2,
    "ytick.color": INK2,
    "font.size": 9.5,
    "axes.titlesize": 10.5,
    "axes.titleweight": "bold",
    "legend.frameon": True,
    "legend.framealpha": 0.92,
    "legend.edgecolor": GRID,
    "legend.fontsize": 8.5,
    "lines.linewidth": 1.25,
    "savefig.dpi": 160,
    "savefig.bbox": "tight",
})


def save(fig, name):
    path = os.path.join(FIG_DIR, name)
    fig.savefig(path)
    plt.close(fig)
    print("  saved", os.path.relpath(path, os.path.join(os.path.dirname(__file__), "..")))
    return path


def inset(ax, bounds, xlim, ylim, lines):
    """Zoom inset like the paper's figures. lines = [(x, y, kwargs), ...]."""
    axi = ax.inset_axes(bounds)
    for x, y, kw in lines:
        axi.plot(x, y, **kw)
    axi.set_xlim(*xlim)
    axi.set_ylim(*ylim)
    from matplotlib.ticker import MaxNLocator
    axi.xaxis.set_major_locator(MaxNLocator(4))
    axi.yaxis.set_major_locator(MaxNLocator(4))
    axi.tick_params(labelsize=7.5)
    axi.set_facecolor("white")
    ax.indicate_inset_zoom(axi, edgecolor=MUTED, alpha=0.9)
    return axi
