"""Multiple linear regression (MLR) for concrete compressive strength.

1. Compares five feature sets with the shared grouped five-fold validation.
2. Selects the feature set with the lowest mean validation RMSE.
3. Refits on the full training set and evaluates once on the test set.
4. Reports coefficients, VIFs, error analysis, and test RMSE over 200
   alternative grouped splits.
5. Writes result tables to modeling/mlr/outputs/ and figures to modeling/mlr/figures/.

Run from the repository root:  python modeling/mlr/mlr.py
"""
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd
import statsmodels.api as sm
from scipy import stats
from sklearn.model_selection import KFold
from statsmodels.nonparametric.smoothers_lowess import lowess
from statsmodels.stats.outliers_influence import variance_inflation_factor

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))  # shared code in modeling/common.py
from common import (INGREDIENTS, PREDICTORS, TARGET, clean_data, journal_style, load_split,  # noqa: E402
                    metrics, test_mixtures)

OUT = HERE / "outputs"
FIG = HERE / "figures"

BASE = PREDICTORS
LOG_AGE = INGREDIENTS + ["log_age"]
VARIANTS = [
    # key, label, predictors, log-transformed target
    ("baseline", "Baseline (8 source predictors)", BASE, False),
    ("log_age", "ln(age) replaces age", LOG_AGE, False),
    ("log_age_wb", "ln(age) + w/b", LOG_AGE + ["wb"], False),
    ("no_aggregates", "ln(age) + w/b, no aggregates",
     [c for c in LOG_AGE + ["wb"] if c not in ("coarse", "fine")], False),
    ("log_target", "ln(age) + w/b, ln(strength) target", LOG_AGE + ["wb"], True),
]
LABEL = {v[0]: v[1] for v in VARIANTS}
GREY, BLUE, INK = "#8c8c8c", "#2166ac", "#222222"
N_RESPLITS = 200


def add_features(d):
    d = d.copy()
    d["log_age"] = np.log(d["age"])
    d["wb"] = d["water"] / (d["cement"] + d["slag"] + d["flyash"])
    return d


def fit_predict(train, test, cols, log_target):
    """Standardize with training statistics, fit OLS, predict strength in MPa."""
    mu, sd = train[cols].mean(), train[cols].std()
    X = sm.add_constant((train[cols] - mu) / sd)
    y = np.log(train[TARGET]) if log_target else train[TARGET]
    # HC3 standard errors: residuals are heteroscedastic (Breusch-Pagan test in main)
    model = sm.OLS(y, X).fit(cov_type="HC3")
    pred = model.predict(sm.add_constant((test[cols] - mu) / sd, has_constant="add"))
    return model, np.exp(pred) if log_target else pred


def cross_validate(train, cols, log_target):
    rows = []
    for f in sorted(train["fold"].unique()):
        a, b = train[train["fold"] != f], train[train["fold"] == f]
        _, p = fit_predict(a, b, cols, log_target)
        rows.append({"fold": f, **metrics(b[TARGET], p)})
    return pd.DataFrame(rows)


def coefficient_table(model, cols):
    ci = model.conf_int()
    return pd.DataFrame({
        "predictor": cols,
        "coef": model.params[cols].values,
        "ci_low": ci.loc[cols, 0].values,
        "ci_high": ci.loc[cols, 1].values,
        "p_value": model.pvalues[cols].values,
    })


def vif_table(train, cols):
    X = sm.add_constant((train[cols] - train[cols].mean()) / train[cols].std())
    return pd.DataFrame({"predictor": cols,
                         "vif": [variance_inflation_factor(X.values, i + 1) for i in range(len(cols))]})


def resplit_rmse(cols_by_key):
    """Test RMSE over alternative grouped 80/20 splits (no folds needed)."""
    clean, _ = clean_data()
    clean = add_features(clean)
    rows = []
    for seed in range(1, N_RESPLITS + 1):
        ids, _ = test_mixtures(clean, seed)
        te = clean[clean["mix_id"].isin(ids)]
        tr = clean[~clean["mix_id"].isin(ids)]
        row = {"seed": seed}
        for key, (cols, log_target) in cols_by_key.items():
            _, p = fit_predict(tr, te, cols, log_target)
            row[key] = metrics(te[TARGET], p)["rmse"]
        rows.append(row)
    return pd.DataFrame(rows)


# ----------------------------------------------------------------------------- figures

def label_panels(fig, axes, letters, dx=0.0, y=None):
    """Bold panel letters at a common height, left-aligned with each axes' outer edge."""
    fig.canvas.draw()
    r = fig.canvas.get_renderer()
    for ax, s in zip(axes, letters):
        box = ax.get_tightbbox(r).transformed(fig.transFigure.inverted())
        top = y if y is not None else ax.get_position().y1 + 0.035
        fig.text(box.x0 + dx, top, s, fontsize=9, fontweight="bold", va="bottom", ha="left")


def save(fig, path):
    fig.savefig(path.with_suffix(".pdf"), bbox_inches="tight", pad_inches=0.03)
    fig.savefig(path.with_suffix(".png"), dpi=300, bbox_inches="tight", pad_inches=0.03)


def fig_feature_sets(plt, cv, summary, coefs, selected, naive_rmse, path):
    from matplotlib.lines import Line2D
    fig = plt.figure(figsize=(7.0, 2.85))
    gs = fig.add_gridspec(1, 2, wspace=0.62, left=0.235, right=0.99, top=0.86, bottom=0.165)
    ax, bx = fig.add_subplot(gs[0]), fig.add_subplot(gs[1])

    # (a) validation RMSE by feature set
    keys = [v[0] for v in VARIANTS]
    ypos = {k: len(keys) - 1 - i for i, k in enumerate(keys)}
    for k in keys:
        r = cv.loc[cv["variant"] == k, "rmse"].to_numpy()
        ax.scatter(r, np.full(len(r), ypos[k]), marker="|", s=30, color="#b0b0b0", lw=0.9, zorder=2)
        s = summary.loc[k]
        col = BLUE if k == selected else GREY if k == "baseline" else INK
        ax.errorbar(s["cv_rmse"], ypos[k], xerr=s["cv_rmse_sd"], fmt="o", ms=4.5, color=col,
                    mfc=col, mec="white", mew=0.6, elinewidth=1.1, capsize=0, zorder=4)
        ax.scatter(s["test_rmse"], ypos[k] - 0.3, marker="D", s=14, facecolor="white", edgecolor=col, lw=0.9, zorder=4)
    ax.axvline(naive_rmse, color=GREY, lw=0.7, ls=(0, (3, 2)), zorder=0)
    ax.text(naive_rmse - 0.2, len(keys) - 0.45, "Mean-only\npredictor (test)", ha="right", va="top", fontsize=7, color="#555555")
    ax.set_yticks([ypos[k] for k in keys])
    ax.set_yticklabels([LABEL[k] for k in keys])
    for t, k in zip(ax.get_yticklabels(), keys):
        if k == selected:
            t.set_fontweight("bold")
    ax.tick_params(axis="y", length=0)
    ax.spines["left"].set_visible(False)
    ax.set_xlim(5.5, 16.5)
    ax.set_ylim(-0.7, len(keys) - 0.3)
    ax.set_xlabel("RMSE (MPa)")
    ax.xaxis.grid(True, color="#ededed", lw=0.5)
    ax.set_axisbelow(True)
    handles = [Line2D([], [], marker="|", ls="", ms=6, mew=0.9, color="#b0b0b0", label="Validation fold"),
               Line2D([], [], marker="o", ls="-", ms=4.5, color=INK, mec="white", mew=0.6, lw=1.1, label="Validation mean ± SD"),
               Line2D([], [], marker="D", ls="", ms=3.8, mfc="white", mec=INK, mew=0.9, label="Test set")]
    ax.legend(handles=handles, loc="center right", bbox_to_anchor=(0.88, 0.5), frameon=False,
              handletextpad=0.4, borderaxespad=0.1, labelspacing=0.5)

    # (b) standardized coefficients with 95% CI; age and ln(age) on separate rows
    order = ["cement", "slag", "flyash", "water", "sp", "coarse", "fine", "age", "log_age", "wb"]
    names = ["Cement", "Slag", "Fly ash", "Water", "Superplasticizer", "Coarse aggregate",
             "Fine aggregate", "Age (baseline only)", "ln(age) (selected only)", "w/b (selected only)"]
    yb = {p: len(order) - 1 - i for i, p in enumerate(order)}
    both = set(coefs.loc[coefs["variant"] == "baseline", "predictor"]) & set(coefs.loc[coefs["variant"] == selected, "predictor"])
    for key, col, dy, filled in [("baseline", GREY, 0.17, False), (selected, BLUE, -0.17, True)]:
        for _, r in coefs[coefs["variant"] == key].iterrows():
            y = yb[r["predictor"]] + (dy if r["predictor"] in both else 0)
            bx.plot([r["ci_low"], r["ci_high"]], [y, y], color=col, lw=1.1, solid_capstyle="butt", zorder=2)
            bx.plot(r["coef"], y, marker="o", ms=3.6, color=col, mfc=col if filled else "white",
                    mec=col if not filled else "white", mew=0.8 if not filled else 0.5, zorder=3)
    bx.axvline(0, color="#9a9a9a", lw=0.6)
    bx.set_yticks([yb[p] for p in order])
    bx.set_yticklabels(names)
    bx.tick_params(axis="y", length=0)
    bx.spines["left"].set_visible(False)
    bx.set_ylim(-0.7, len(order) - 0.3)
    bx.set_xlabel("Standardized coefficient (MPa per SD)")
    bx.xaxis.grid(True, color="#ededed", lw=0.5)
    bx.set_axisbelow(True)
    handles = [Line2D([], [], marker="o", color=GREY, mfc="white", mec=GREY, mew=0.8, lw=1.1, ms=3.6, label="Baseline"),
               Line2D([], [], marker="o", color=BLUE, mec="white", mew=0.5, lw=1.1, ms=3.6, label="Selected: ln(age) + w/b")]
    bx.legend(handles=handles, loc="lower left", bbox_to_anchor=(-0.02, 1.0), ncol=2, frameon=False,
              handletextpad=0.3, columnspacing=1.2, borderaxespad=0.1)
    label_panels(fig, [ax, bx], ["a", "b"], y=0.955)
    save(fig, path)
    plt.close(fig)


def fig_diagnostics(plt, test, path, rmse_base, rmse_sel):
    from matplotlib.lines import Line2D
    from matplotlib.ticker import FixedLocator, FixedFormatter, NullLocator
    fig, axes = plt.subplots(1, 3, figsize=(7.0, 2.6), gridspec_kw=dict(wspace=0.5, left=0.065, right=0.99, top=0.88, bottom=0.17))
    a, b, c = axes
    for ax in axes:
        ax.set_box_aspect(1)
    y = test[TARGET].to_numpy()
    pb, ps = test["pred_baseline"].to_numpy(), test["pred_selected"].to_numpy()
    lim = (0, 85)

    # (a) predicted vs observed
    a.fill_between(lim, [lim[0] - 10, lim[1] - 10], [lim[0] + 10, lim[1] + 10], color="#efefef", lw=0, zorder=0)
    a.plot(lim, lim, color="#9a9a9a", lw=0.7, zorder=1)
    a.scatter(y, pb, s=7, facecolor="none", edgecolor=GREY, lw=0.5, zorder=2)
    a.scatter(y, ps, s=6, color=BLUE, alpha=0.7, lw=0, zorder=3)
    a.set_xlim(lim); a.set_ylim(lim)
    a.set_xlabel("Observed strength (MPa)")
    a.set_ylabel("Predicted strength (MPa)")
    a.text(0.03, 0.97, "Test set, n = 201\nShaded band: ±10 MPa", transform=a.transAxes, fontsize=7, va="top", linespacing=1.3)
    handles = [Line2D([], [], marker="o", ls="", mfc="none", mec=GREY, mew=0.6, ms=3, label=f"Baseline  {rmse_base:.1f}"),
               Line2D([], [], marker="o", ls="", color=BLUE, ms=3, label=f"Selected  {rmse_sel:.1f}")]
    a.legend(handles=handles, loc="lower right", bbox_to_anchor=(1.04, 0.0), title="Test RMSE (MPa)", title_fontsize=7, frameon=False,
             handletextpad=0.2, borderaxespad=0.1, labelspacing=0.3, alignment="left")

    # (b) residual vs age; the two models are offset sideways so their points do not overlap
    rb, rs = y - pb, y - ps
    jit = np.exp(np.random.default_rng(1).uniform(-0.035, 0.035, len(test)))
    b.axhline(0, color="#9a9a9a", lw=0.7)
    b.scatter(test["age"] * 0.92 * jit, rb, s=7, facecolor="none", edgecolor=GREY, lw=0.5)
    b.scatter(test["age"] * 1.08 * jit, rs, s=6, color=BLUE, alpha=0.7, lw=0)
    bins = [(1, 3), (4, 7), (8, 14), (15, 28), (29, 56), (57, 100), (101, 200), (201, 400)]
    for r, col, mfc in [(rb, GREY, "white"), (rs, BLUE, BLUE)]:
        xs, ms = [], []
        for lo, hi in bins:
            m = ((test["age"] >= lo) & (test["age"] <= hi)).to_numpy()
            if m.sum() >= 5:
                xs.append(np.median(test["age"].to_numpy()[m])); ms.append(np.median(r[m]))
        b.plot(xs, ms, color=col, lw=1.5, marker="s", ms=3.4, mfc=mfc, mec=col if mfc == "white" else "white", mew=0.7, zorder=5)
    b.set_xscale("log")
    b.xaxis.set_major_locator(FixedLocator([3, 7, 14, 28, 56, 100, 365]))
    b.xaxis.set_major_formatter(FixedFormatter(["3", "7", "14", "28", "56", "100", "365"]))
    b.xaxis.set_minor_locator(NullLocator())
    b.set_xlim(2.3, 480)
    b.set_ylim(-32, 32)
    b.set_xlabel("Specimen age (days, log scale)")
    b.set_ylabel("Residual, obs. − pred. (MPa)")
    b.text(0.03, 0.97, "Lines: median by age group", transform=b.transAxes, fontsize=7, va="top")

    # (c) residual vs predicted for the selected model
    c.axhline(0, color="#9a9a9a", lw=0.7)
    c.scatter(ps, rs, s=6, color=BLUE, alpha=0.7, lw=0)
    trend = lowess(rs, ps, frac=0.5, return_sorted=True)
    c.plot(trend[:, 0], trend[:, 1], color=INK, lw=1.2)
    sd = rs.std(ddof=1)
    for s in (1.96 * sd, -1.96 * sd):
        c.axhline(s, color="#9a9a9a", lw=0.6, ls=(0, (3, 2)))
    c.set_xlim(lim); c.set_ylim(-32, 32)
    c.set_xlabel("Predicted strength (MPa)")
    c.set_ylabel("Residual, obs. − pred. (MPa)")
    c.text(0.03, 0.97, "Selected model", transform=c.transAxes, fontsize=7, va="top")
    handles = [Line2D([], [], color=INK, lw=1.2, label="LOWESS trend"),
               Line2D([], [], color="#9a9a9a", lw=0.6, ls=(0, (3, 2)), label="±1.96 SD (pooled)")]
    c.legend(handles=handles, loc="lower left", frameon=False, handletextpad=0.4, borderaxespad=0.1)
    label_panels(fig, axes, ["a", "b", "c"])
    save(fig, path)
    plt.close(fig)


# ----------------------------------------------------------------------------- main

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    FIG.mkdir(parents=True, exist_ok=True)
    d = add_features(load_split())
    train, test = d[d["set"] == "train"], d[d["set"] == "test"]

    # 1. grouped five-fold validation for every feature set
    cv_rows, summary = [], []
    for key, label, cols, log_target in VARIANTS:
        cv = cross_validate(train, cols, log_target).assign(variant=key)
        cv_rows.append(cv)
        summary.append({"variant": key, "label": label, "n_predictors": len(cols),
                        "cv_rmse": cv["rmse"].mean(), "cv_rmse_sd": cv["rmse"].std(ddof=1),
                        "cv_mae": cv["mae"].mean(), "cv_r2": cv["r2"].mean()})
    cv = pd.concat(cv_rows, ignore_index=True)
    summary = pd.DataFrame(summary).set_index("variant")

    # 2. selection by mean validation RMSE
    selected = summary["cv_rmse"].idxmin()

    # 3. refit on the full training set, evaluate once on the test set
    models, preds, coefs, vifs = {}, {}, [], []
    for key, label, cols, log_target in VARIANTS:
        model, p = fit_predict(train, test, cols, log_target)
        models[key], preds[key] = model, p
        m = metrics(test[TARGET], p)
        for k, v in m.items():
            summary.loc[key, f"test_{k}"] = v
        if key in ("baseline", selected):
            coefs.append(coefficient_table(model, cols).assign(variant=key, r2_train=model.rsquared))
            vifs.append(vif_table(train, cols).assign(variant=key))
    coefs, vifs = pd.concat(coefs), pd.concat(vifs)

    # raw-unit coefficients of the baseline (MPa per kg/m3 or per day)
    raw_coef = (models["baseline"].params[BASE] / train[BASE].std()).rename("mpa_per_unit")

    # 4. checks and error analysis
    naive = metrics(test[TARGET], np.full(len(test), train[TARGET].mean()))
    rnd = []
    for a_i, b_i in KFold(5, shuffle=True, random_state=492).split(train):
        _, p = fit_predict(train.iloc[a_i], train.iloc[b_i], BASE, False)
        rnd.append(metrics(train.iloc[b_i][TARGET], p)["rmse"])
    sel_model = models[selected]
    sel_cols, sel_log = [(v[2], v[3]) for v in VARIANTS if v[0] == selected][0]
    resplits = resplit_rmse({"baseline": (BASE, False), "selected": (sel_cols, sel_log)})

    test_out = test[["source_row", "mix_id", "age", TARGET]].copy()
    test_out["pred_baseline"], test_out["pred_selected"] = preds["baseline"], preds[selected]
    err = test_out[TARGET] - test_out["pred_selected"]
    age_bins = pd.cut(test_out["age"], [0, 7, 28, 100, 400], labels=["3–7 d", "14–28 d", "56–100 d", "180–365 d"])
    str_bins = pd.cut(test_out[TARGET], [0, 20, 40, 60, 100], labels=["<20", "20–40", "40–60", "≥60"])
    by_age = err.groupby(age_bins, observed=False).agg(n="size", bias="mean", rmse=lambda e: np.sqrt(np.mean(e ** 2)))
    by_strength = err.groupby(str_bins, observed=False).agg(n="size", bias="mean", rmse=lambda e: np.sqrt(np.mean(e ** 2)))
    resid_base = test_out[TARGET] - test_out["pred_baseline"]
    by_age_base = resid_base.groupby(age_bins, observed=False).agg(bias="mean")
    shapiro = stats.shapiro(sel_model.resid)
    bp = sm.stats.het_breuschpagan(sel_model.resid, sel_model.model.exog)

    facts = {
        "selected": selected,
        "naive_test": naive,
        "random_cv_baseline_rmse": [float(np.mean(rnd)), float(np.std(rnd, ddof=1))],
        "resplit_baseline_rmse_pct": resplits["baseline"].quantile([0.05, 0.5, 0.95]).round(2).tolist(),
        "resplit_selected_rmse_pct": resplits["selected"].quantile([0.05, 0.5, 0.95]).round(2).tolist(),
        "resplit_improvement_all": bool((resplits["selected"] < resplits["baseline"]).all()),
        "within_5": float((err.abs() <= 5).mean()), "within_10": float((err.abs() <= 10).mean()),
        "within_10_baseline": float((resid_base.abs() <= 10).mean()),
        "test_mean_strength": float(test[TARGET].mean()),
        "error_by_age": by_age.round(2).reset_index().to_dict("records"),
        "baseline_bias_by_age": by_age_base.round(2).reset_index().to_dict("records"),
        "error_by_strength": by_strength.round(2).reset_index().to_dict("records"),
        "shapiro_p": float(shapiro.pvalue), "breusch_pagan_p": float(bp[1]),
        "train_r2_selected": float(sel_model.rsquared), "train_r2_baseline": float(models["baseline"].rsquared),
        "baseline_raw_coef": raw_coef.round(4).to_dict(),
    }

    # outputs
    summary.round(4).to_csv(OUT / "mlr_summary.csv")
    cv.round(4).to_csv(OUT / "mlr_cv_folds.csv", index=False)
    coefs.round(4).to_csv(OUT / "mlr_coefficients.csv", index=False)
    vifs.round(2).to_csv(OUT / "mlr_vif.csv", index=False)
    resplits.round(4).to_csv(OUT / "mlr_resplits.csv", index=False)
    pd.concat([
        test_out.assign(model=f"MLR: {LABEL['baseline']}", y_pred=test_out["pred_baseline"]),
        test_out.assign(model=f"MLR: {LABEL[selected]} (selected)", y_pred=test_out["pred_selected"]),
    ]).rename(columns={TARGET: "y_true"})[["source_row", "mix_id", "age", "y_true", "y_pred", "model"]] \
        .round(4).to_csv(OUT / "test_predictions_mlr.csv", index=False)
    (OUT / "mlr_facts.json").write_text(json.dumps(facts, indent=2, default=str))

    plt = journal_style()
    fig_feature_sets(plt, cv, summary, coefs, selected, naive["rmse"], FIG / "mlr_feature_sets")
    fig_diagnostics(plt, test_out, FIG / "mlr_diagnostics",
                    summary.loc["baseline", "test_rmse"], summary.loc[selected, "test_rmse"])

    print(summary[["cv_rmse", "cv_rmse_sd", "test_rmse", "test_mae", "test_r2"]].round(3))
    print(json.dumps(facts, indent=1, default=str))
    print(vifs.round(2).to_string())
    print(coefs.round(3).to_string())


if __name__ == "__main__":
    main()
