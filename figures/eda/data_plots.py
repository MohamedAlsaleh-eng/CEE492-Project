import sys, os
import numpy as np, pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib import gridspec, colors, cm
from matplotlib.ticker import LogLocator, NullFormatter, FixedLocator, FixedFormatter
from scipy import stats

src, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
d = pd.read_excel(src)
d.columns = ["cement", "slag", "flyash", "water", "sp", "coarse", "fine", "age", "strength"]
d["binder"] = d.cement + d.slag + d.flyash
d["wb"] = d.water / d.binder

plt.rcParams.update({
    "font.family": "sans-serif", "font.sans-serif": ["Helvetica", "Arial"],
    "font.size": 8, "axes.titlesize": 8, "axes.labelsize": 8, "xtick.labelsize": 7, "ytick.labelsize": 7,
    "legend.fontsize": 7, "axes.linewidth": 0.6, "xtick.major.width": 0.6, "ytick.major.width": 0.6,
    "xtick.minor.width": 0.4, "ytick.minor.width": 0.4, "xtick.major.size": 3, "ytick.major.size": 3,
    "xtick.minor.size": 1.8, "ytick.minor.size": 1.8, "xtick.direction": "out", "ytick.direction": "out",
    "axes.spines.top": False, "axes.spines.right": False, "savefig.dpi": 300, "pdf.fonttype": 42,
    "axes.labelcolor": "#222", "xtick.color": "#333", "ytick.color": "#333", "text.color": "#222",
})
INK, GREY, BLUE = "#222222", "#9a9a9a", "#2a6fb5"

def save(fig, name):
    fig.savefig(f"{out}/{name}.pdf", bbox_inches="tight", pad_inches=0.02)
    fig.savefig(f"{out}/{name}.png", bbox_inches="tight", pad_inches=0.02, dpi=300)
    plt.close(fig)

def panel(ax, s, x=-0.12, y=1.02):
    ax.text(x, y, s, transform=ax.transAxes, fontsize=9, fontweight="bold", va="bottom", ha="left")

# ---------------- Fig 1: raincloud of strength by test age ----------------
def fig_raincloud():
    ages = sorted(d.age.unique())
    cmap = plt.get_cmap("viridis")
    cols = [cmap(0.08 + 0.84 * i / (len(ages) - 1)) for i in range(len(ages))]
    fig, ax = plt.subplots(figsize=(7.0, 2.9))
    rng = np.random.default_rng(1)
    for i, (a, c) in enumerate(zip(ages, cols)):
        v = d.loc[d.age == a, "strength"].values
        if len(v) >= 10:
            kde = stats.gaussian_kde(v, bw_method="scott")
            yy = np.linspace(max(0, v.min() - 3), v.max() + 3, 200)
            dens = kde(yy); dens = dens / dens.max() * 0.36
            ax.fill_betweenx(yy, i - dens, i, color=c, alpha=0.55, lw=0)
            ax.plot(i - dens, yy, color=c, lw=0.6)
        q1, med, q3 = np.percentile(v, [25, 50, 75])
        if len(v) >= 5:
            ax.add_patch(plt.Rectangle((i + 0.02, q1), 0.07, q3 - q1, fc="white", ec=INK, lw=0.6, zorder=3))
            ax.plot([i + 0.02, i + 0.09], [med, med], color=INK, lw=1.1, zorder=4)
            iqr = q3 - q1
            lo, hi = v[v >= q1 - 1.5 * iqr].min(), v[v <= q3 + 1.5 * iqr].max()
            ax.plot([i + 0.055] * 2, [lo, q1], color=INK, lw=0.6, zorder=3)
            ax.plot([i + 0.055] * 2, [q3, hi], color=INK, lw=0.6, zorder=3)
        jx = i + 0.14 + rng.uniform(0, 0.22, len(v))
        ax.scatter(jx, v, s=2.2, color=c, alpha=0.75, lw=0, zorder=2)
        ax.text(i + 0.05, 93, f"{len(v)}", ha="center", va="bottom", fontsize=6, color="#555")
    ax.set_xticks(range(len(ages)), [str(int(a)) for a in ages])
    ax.set_xlim(-0.6, len(ages) - 0.35)
    ax.set_ylim(0, 90)
    ax.set_ylabel("Compressive strength (MPa)")
    ax.set_xlabel("Specimen age (days)")
    ax.tick_params(axis="x", length=0)
    ax.text(-0.58, 93, "n =", ha="left", va="bottom", fontsize=6, color="#555")
    ax.set_clip_on(False)
    ax.yaxis.grid(True, color="#e6e6e6", lw=0.5); ax.set_axisbelow(True)
    save(fig, "fig1_raincloud_age")

# ---------------- Fig 2: corner plot ----------------
def fig_corner():
    V = [("cement", "Cement\n(kg/m³)"), ("slag", "Slag\n(kg/m³)"), ("flyash", "Fly ash\n(kg/m³)"),
         ("water", "Water\n(kg/m³)"), ("sp", "Superplast.\n(kg/m³)"), ("age", "Age\n(days)"), ("strength", "Strength\n(MPa)")]
    n = len(V)
    fig, axes = plt.subplots(n, n, figsize=(7.0, 7.0))
    fig.subplots_adjust(wspace=0.08, hspace=0.08)
    norm = colors.TwoSlopeNorm(vmin=-1, vcenter=0, vmax=1)
    dcm = plt.get_cmap("RdBu_r")
    strength_norm = colors.Normalize(d.strength.min(), d.strength.max())
    lims = {}
    for k, _ in V:
        if k == "age": lims[k] = (0.8, 450)
        else:
            lo, hi = d[k].min(), d[k].max(); pad = (hi - lo) * 0.05; lims[k] = (lo - pad, hi + pad)
    for i, (ki, li) in enumerate(V):
        for j, (kj, lj) in enumerate(V):
            ax = axes[i, j]
            for s in ax.spines.values(): s.set_linewidth(0.5)
            if j > i:
                rho, p = stats.spearmanr(d[ki], d[kj])
                ax.set_facecolor(dcm(norm(rho)) [:3] + (0.85,))
                star = "***" if p < 1e-3 else "**" if p < 1e-2 else "*" if p < 0.05 else ""
                tc = "white" if abs(rho) > 0.45 else INK
                ax.text(0.5, 0.55, f"{rho:.2f}", ha="center", va="center", fontsize=7.5, color=tc, transform=ax.transAxes,
                        fontweight="bold" if abs(rho) >= 0.3 else "normal")
                ax.text(0.5, 0.25, star, ha="center", va="center", fontsize=6.5, color=tc, transform=ax.transAxes)
                ax.set_xticks([]); ax.set_yticks([])
                for s in ax.spines.values(): s.set_visible(False)
                continue
            if i == j:
                x = d[ki].values
                if ki == "age":
                    bins = np.logspace(0, np.log10(400), 22); ax.set_xscale("log")
                else:
                    bins = np.linspace(*lims[ki], 24)
                ax.hist(x, bins=bins, color="#b9cbe2", ec="white", lw=0.3)
                ax.set_yticks([])
                ax.spines["left"].set_visible(False)
            else:
                x, y = d[kj].values, d[ki].values
                ax.scatter(x, y, s=1.2, c=d.strength, cmap="viridis", norm=strength_norm, lw=0, alpha=0.8, rasterized=True)
                if kj == "age": ax.set_xscale("log")
                if ki == "age": ax.set_yscale("log")
                ax.set_ylim(lims[ki])
            ax.set_xlim(lims[kj])
            if kj == "age":
                ax.xaxis.set_major_locator(FixedLocator([1, 10, 100])); ax.xaxis.set_major_formatter(FixedFormatter(["1", "10", "100"]))
                ax.xaxis.set_minor_formatter(NullFormatter()); ax.xaxis.set_minor_locator(FixedLocator([]))
            if ki == "age" and i != j:
                ax.yaxis.set_major_locator(FixedLocator([1, 10, 100])); ax.yaxis.set_major_formatter(FixedFormatter(["1", "10", "100"]))
                ax.yaxis.set_minor_formatter(NullFormatter()); ax.yaxis.set_minor_locator(FixedLocator([]))
            ax.tick_params(labelsize=6, length=2, pad=1.5)
            if i < n - 1: ax.set_xticklabels([])
            else: ax.set_xlabel(lj, fontsize=7)
            if j > 0 or i == 0: ax.set_yticklabels([])
            if j == 0 and i > 0: ax.set_ylabel(li, fontsize=7)
            ax.locator_params(axis="x", nbins=3) if kj != "age" else None
            if kj == "water": ax.set_xticks([150, 200])
            if i != j and ki != "age": ax.locator_params(axis="y", nbins=3)
    axes[0, 0].set_ylabel(V[0][1], fontsize=7)
    # colorbars
    cax = fig.add_axes([0.93, 0.56, 0.012, 0.3])
    cb = fig.colorbar(cm.ScalarMappable(norm=norm, cmap=dcm), cax=cax); cb.set_label("Spearman ρ (upper)", fontsize=7)
    cb.ax.tick_params(labelsize=6, length=2); cb.outline.set_linewidth(0.4)
    cax2 = fig.add_axes([0.93, 0.14, 0.012, 0.3])
    cb2 = fig.colorbar(cm.ScalarMappable(norm=strength_norm, cmap="viridis"), cax=cax2); cb2.set_label("Strength, MPa (lower, colour)", fontsize=7)
    cb2.ax.tick_params(labelsize=6, length=2); cb2.outline.set_linewidth(0.4)
    fig.text(0.93, 0.08, "* p<0.05  ** p<0.01\n*** p<0.001", fontsize=6, va="top", color="#444")
    save(fig, "fig2_corner")

# ---------------- Fig 3: ternary binder composition ----------------
def tern(c, s, f):
    t = c + s + f
    a, b = s / t, f / t           # slag, fly ash fractions
    x = b + a / 2                 # vertices: cement (0,0), fly ash (1,0), slag (0.5, h)
    y = a * np.sqrt(3) / 2
    return x, y

def fig_ternary():
    d28 = d[d.age == 28].copy()
    fig, ax = plt.subplots(figsize=(3.6, 3.4))
    h = np.sqrt(3) / 2
    ax.plot([0, 1, 0.5, 0], [0, 0, h, 0], color=INK, lw=0.7, zorder=1)
    for g in np.arange(0.1, 1.0, 0.1):
        lw, col = (0.5, "#d4d4d4") if round(g * 10) % 2 == 0 else (0.35, "#ececec")
        # constant slag
        ax.plot([g / 2, 1 - g / 2], [g * h, g * h], color=col, lw=lw, zorder=0)
        # constant fly ash
        ax.plot([g, g + (1 - g) / 2], [0, (1 - g) * h], color=col, lw=lw, zorder=0)
        # constant cement (c = 1 - g)
        ax.plot([g, g / 2], [0, g * h], color=col, lw=lw, zorder=0)
    for g in [0.2, 0.4, 0.6, 0.8]:
        ax.text(1 - g / 2 + 0.02, g * h, f"{round(g * 100)}", fontsize=6, color="#666", va="center", ha="left")       # slag ticks right edge
        ax.text(g, -0.03, f"{round(g * 100)}", fontsize=6, color="#666", va="top", ha="center")                  # fly ash ticks bottom
        ax.text(g / 2 - 0.02, g * h, f"{round((1 - g) * 100)}", fontsize=6, color="#666", va="center", ha="right")  # cement ticks left
    x, y = tern(d28.cement.values, d28.slag.values, d28.flyash.values)
    order = np.argsort(d28.strength.values)
    sc = ax.scatter(x[order], y[order], c=d28.strength.values[order], cmap="viridis", s=9, lw=0.3, ec="white", zorder=3,
                    vmin=10, vmax=80)
    ax.text(-0.04, -0.04, "Cement", ha="right", va="top", fontsize=7.5, fontweight="bold")
    ax.text(1.04, -0.04, "Fly ash", ha="left", va="top", fontsize=7.5, fontweight="bold")
    ax.text(0.5, h + 0.04, "Slag", ha="center", va="bottom", fontsize=7.5, fontweight="bold")
    ax.text(0.5, -0.11, "Fly ash share of binder (%)", ha="center", va="top", fontsize=6.5, color="#444")
    ax.text(0.86, 0.47, "Slag (%)", rotation=-60, ha="center", va="center", fontsize=6.5, color="#444")
    ax.text(0.14, 0.47, "Cement (%)", rotation=60, ha="center", va="center", fontsize=6.5, color="#444")
    ax.set_aspect("equal"); ax.axis("off")
    ax.set_xlim(-0.12, 1.12); ax.set_ylim(-0.2, h + 0.1)
    cax = fig.add_axes([0.80, 0.55, 0.025, 0.32])
    cb = fig.colorbar(sc, cax=cax); cb.set_label("28-day strength (MPa)", fontsize=7)
    cb.ax.tick_params(labelsize=6, length=2); cb.outline.set_linewidth(0.4)
    save(fig, "fig3_ternary_binder")

# ---------------- Fig 4: strength vs w/b, coloured by age, with marginals ----------------
def fig_joint():
    fig = plt.figure(figsize=(3.6, 3.4))
    gs = gridspec.GridSpec(2, 2, width_ratios=[4, 1], height_ratios=[1, 4], wspace=0.04, hspace=0.04)
    ax = fig.add_subplot(gs[1, 0]); axt = fig.add_subplot(gs[0, 0], sharex=ax); axr = fig.add_subplot(gs[1, 1], sharey=ax)
    norm = colors.LogNorm(1, 365)
    order = np.argsort(d.age.values)
    sc = ax.scatter(d.wb.values[order], d.strength.values[order], c=d.age.values[order], cmap="plasma", norm=norm,
                    s=5, lw=0.2, ec="white", alpha=0.95, rasterized=True)
    ax.set_xlabel("Water-to-binder ratio, w/(c+s+f)"); ax.set_ylabel("Compressive strength (MPa)")
    ax.set_xlim(0.2, 0.95); ax.set_ylim(0, 88)
    axt.hist(d.wb, bins=np.linspace(0.2, 0.95, 31), color="#c9c9c9", ec="white", lw=0.3)
    axr.hist(d.strength, bins=np.linspace(0, 88, 31), orientation="horizontal", color="#c9c9c9", ec="white", lw=0.3)
    for a in (axt, axr):
        a.tick_params(labelbottom=False, labelleft=False, length=0)
        for s in a.spines.values(): s.set_visible(False)
        a.set_xticks([]) if a is axr else a.set_yticks([])
    axt.tick_params(labelbottom=False); axr.tick_params(labelleft=False)
    cax = ax.inset_axes([0.66, 0.9, 0.3, 0.035])
    cb = fig.colorbar(sc, cax=cax, orientation="horizontal")
    cb.set_ticks([1, 7, 28, 90, 365]); cb.set_ticklabels(["1", "7", "28", "90", "365"])
    cb.ax.xaxis.set_minor_formatter(NullFormatter()); cb.ax.tick_params(labelsize=6, length=2, which="both")
    cb.set_label("Age (days)", fontsize=6.5, labelpad=1); cb.outline.set_linewidth(0.4)
    save(fig, "fig4_wb_joint")

# ---------------- Fig 5: strength development of individual mixtures ----------------
def fig_development():
    mix = ["cement", "slag", "flyash", "water", "sp", "coarse", "fine"]
    g = d.groupby(mix)
    norm = colors.Normalize(0.25, 0.85); cmap = plt.get_cmap("viridis_r")
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(7.0, 2.7), gridspec_kw=dict(wspace=0.42))
    ratios = {}
    for k, s in g:
        s = s.groupby("age").strength.mean()
        wb = k[3] / (k[0] + k[1] + k[2])
        if len(s) >= 3:
            a1.plot(s.index, s.values, color=cmap(norm(wb)), lw=0.7, alpha=0.75, marker="o", ms=1.6, mew=0)
        if 28 in s.index:
            pool = {90: 95, 91: 95, 100: 95, 360: 362, 365: 362}
            for a, v in s.items(): ratios.setdefault(pool.get(a, a), []).append(v / s[28])
    a1.set_xscale("log"); a1.set_xlim(0.9, 420); a1.set_ylim(0, 88)
    a1.xaxis.set_major_locator(FixedLocator([1, 3, 7, 14, 28, 56, 90, 180, 365]))
    a1.xaxis.set_major_formatter(FixedFormatter(["1", "3", "7", "14", "28", "56", "90", "180", "365"]))
    a1.xaxis.set_minor_formatter(NullFormatter()); a1.xaxis.set_minor_locator(FixedLocator([]))
    a1.set_xlabel("Age (days, log scale)"); a1.set_ylabel("Compressive strength (MPa)")
    a1.yaxis.grid(True, color="#ececec", lw=0.5); a1.set_axisbelow(True)
    cb = fig.colorbar(cm.ScalarMappable(norm=norm, cmap=cmap), ax=a1, fraction=0.04, pad=0.02)
    cb.set_label("w/b of mixture", fontsize=7); cb.ax.tick_params(labelsize=6, length=2); cb.outline.set_linewidth(0.4)
    panel(a1, "a", x=-0.15)
    ag = [a for a in sorted(ratios) if len(ratios[a]) >= 5]
    q = np.array([np.percentile(ratios[a], [10, 25, 50, 75, 90]) for a in ag])
    a2.fill_between(ag, q[:, 0], q[:, 4], color=BLUE, alpha=0.12, lw=0, label="10–90th pct.")
    a2.fill_between(ag, q[:, 1], q[:, 3], color=BLUE, alpha=0.25, lw=0, label="25–75th pct.")
    a2.plot(ag, q[:, 2], color=BLUE, lw=1.4, marker="o", ms=3, mfc="white", mew=1, label="Median")
    a2.axhline(1, color=GREY, lw=0.6, ls=(0, (3, 2))); a2.axvline(28, color=GREY, lw=0.6, ls=(0, (3, 2)))
    a2.set_xscale("log"); a2.set_xlim(2.5, 420); a2.set_ylim(0, 1.75)
    a2.xaxis.set_major_locator(FixedLocator([3, 7, 14, 28, 56, 95, 180, 270, 362]))
    a2.xaxis.set_major_formatter(FixedFormatter(["3", "7", "14", "28", "56", "90*", "180", "", "365*"]))
    a2.xaxis.set_minor_formatter(NullFormatter()); a2.xaxis.set_minor_locator(FixedLocator([]))
    a2.set_xlabel("Age (days, log scale)"); a2.set_ylabel(r"$f_c(t)\,/\,f_c(28\,\mathrm{d})$, same mixture")
    a2.legend(frameon=False, loc="lower right")
    a2.yaxis.grid(True, color="#ececec", lw=0.5); a2.set_axisbelow(True)
    for a in ag:
        a2.text(a, 1.66, len(ratios[a]), ha="center", fontsize=5.5, color="#666")
    a2.text(-0.015, 1.66, "n", fontsize=5.5, color="#666", ha="right", transform=a2.get_yaxis_transform())
    a2.text(0.03, 0.86, "* pooled: 90–100 d and 360–365 d", transform=a2.transAxes, ha="left", fontsize=5.5, color="#666")
    panel(a2, "b", x=-0.15)
    save(fig, "fig5_strength_development")

for f in [fig_raincloud, fig_corner, fig_ternary, fig_joint, fig_development]:
    f(); print("ok", f.__name__)
