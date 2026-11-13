"""Polynomial regression with ridge regularization for concrete strength.

1. Uses the shared train/test split and five mixture-grouped validation folds.
2. Expands the eight source predictors into quadratic terms and interactions.
3. Selects the ridge penalty using the lowest mean validation RMSE.
4. Refits on all training records and evaluates the test set once.
5. Saves results and figures to modeling/ridge/outputs/ and figures/.

Run from the repository root: python modeling/ridge/ridge.py
"""
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.linear_model import Ridge
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import PolynomialFeatures, StandardScaler

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(HERE.parent))  # shared functions in modeling/common.py
from common import PREDICTORS, TARGET, journal_style, load_split, metrics  # noqa: E402

OUT = HERE / "outputs"
FIG = HERE / "figures"
PENALTIES = np.logspace(-4, 4, 20)
GREY, BLUE, INK = "#8c8c8c", "#2166ac", "#222222"


def make_model(penalty):
    """Fit the polynomial expansion and scaling inside each training fold."""
    return Pipeline([
        ("polynomial", PolynomialFeatures(degree=2, include_bias=False)),
        ("scale", StandardScaler()),
        ("ridge", Ridge(alpha=float(penalty), fit_intercept=True, solver="svd")),
    ])


def cross_validate(train):
    """Evaluate all 20 penalties on the five existing mixture-grouped folds."""
    rows = []
    for penalty in PENALTIES:
        for fold in range(1, 6):
            a = train[train["fold"] != fold]
            b = train[train["fold"] == fold]
            model = make_model(penalty)
            model.fit(a[PREDICTORS], a[TARGET])
            pred = model.predict(b[PREDICTORS])
            rows.append({"penalty": float(penalty), "fold": fold,
                         **metrics(b[TARGET], pred)})
    return pd.DataFrame(rows)


def summarize_cv(cv):
    """Use the average fold RMSE to select the ridge penalty."""
    summary = cv.groupby("penalty", sort=True).agg(
        cv_rmse=("rmse", "mean"), cv_rmse_sd=("rmse", "std"),
        cv_mae=("mae", "mean"), cv_r2=("r2", "mean"),
    ).reset_index()
    return summary, float(summary.loc[summary["cv_rmse"].idxmin(), "penalty"])


def error_table(test, predictions):
    """Check whether errors are larger for old and high-strength specimens."""
    age = test["age"].to_numpy()
    y = test[TARGET].to_numpy()
    groups = [
        ("All test specimens", np.ones(len(test), dtype=bool)),
        ("Age below 180 days", age < 180),
        ("Age 180 days or more", age >= 180),
        ("Strength 60 MPa or less", y <= 60),
        ("Strength above 60 MPa", y > 60),
    ]
    rows = []
    for label, mask in groups:
        m = metrics(y[mask], predictions[mask]) if mask.sum() > 1 else dict(rmse=np.nan, mae=np.nan, r2=np.nan)
        rows.append({"group": label, "n": int(mask.sum()),
                     "bias_obs_minus_pred": float(np.mean(y[mask] - predictions[mask])) if mask.any() else np.nan,
                     **m})
    return pd.DataFrame(rows)


def save(fig, path):
    fig.savefig(path.with_suffix(".pdf"), bbox_inches="tight", pad_inches=0.04)
    fig.savefig(path.with_suffix(".png"), dpi=300, bbox_inches="tight", pad_inches=0.04)


def fig_tuning(plt, cv, summary, selected, test_rmse, path):
    """Two panels: penalty choice and fold-by-fold error."""
    fig, (ax, bx) = plt.subplots(1, 2, figsize=(7.0, 2.65),
                                gridspec_kw=dict(wspace=0.36, left=0.085, right=0.98, top=0.86, bottom=0.21))
    ax.fill_between(summary["penalty"].to_numpy(),
                    (summary["cv_rmse"] - summary["cv_rmse_sd"]).to_numpy(),
                    (summary["cv_rmse"] + summary["cv_rmse_sd"]).to_numpy(),
                    color="#e4ecf5", lw=0)
    ax.plot(summary["penalty"], summary["cv_rmse"], "o-", color=BLUE, ms=3, lw=1.1)
    ax.axvline(selected, color=INK, lw=0.75, ls=(0, (3, 2)))
    chosen = summary.loc[np.isclose(summary.penalty, selected)].iloc[0]
    ax.scatter([selected], [chosen.cv_rmse], s=35, marker="D", color=INK, zorder=4)
    ax.set_xscale("log")
    ax.set_xlabel("Ridge penalty, λ (log scale)")
    ax.set_ylabel("Mean validation RMSE (MPa)")
    ax.text(0.03, 0.97, f"Selected λ = {selected:.2f}\nCV RMSE = {chosen.cv_rmse:.2f} MPa",
            transform=ax.transAxes, va="top", fontsize=7)
    ax.grid(axis="y", color="#eeeeee", lw=0.5)
    ax.set_axisbelow(True)

    folds = cv.loc[np.isclose(cv.penalty, selected)].sort_values("fold")
    bx.bar(folds["fold"].astype(str), folds["rmse"], color=BLUE, width=0.57, alpha=0.85)
    bx.axhline(chosen.cv_rmse, color=INK, lw=1.0, label=f"Mean = {chosen.cv_rmse:.2f} MPa")
    bx.set_xlabel("Validation fold")
    bx.set_ylabel("Validation RMSE (MPa)")
    bx.set_ylim(0, max(11, folds.rmse.max() + 1.5))
    bx.legend(frameon=False, loc="upper right", fontsize=7)
    bx.grid(axis="y", color="#eeeeee", lw=0.5)
    bx.set_axisbelow(True)
    for p, letter in zip([ax, bx], ["a", "b"]):
        p.text(-0.12, 1.10, letter, transform=p.transAxes, fontweight="bold", fontsize=9)
    save(fig, path)
    plt.close(fig)


def fig_diagnostics(plt, test, pred, score, path):
    """Three test-set panels, following the MLR diagnostic figure format."""
    from statsmodels.nonparametric.smoothers_lowess import lowess
    y = test[TARGET].to_numpy()
    age = test["age"].to_numpy()
    residual = y - pred
    fig, axes = plt.subplots(1, 3, figsize=(7.0, 2.7),
                             gridspec_kw=dict(wspace=0.53, left=0.075, right=0.985, top=0.86, bottom=0.21))
    a, b, c = axes
    for x in axes:
        x.set_box_aspect(1)
    lim = (0, 90)
    a.fill_between(lim, [lim[0] - 10, lim[1] - 10], [lim[0] + 10, lim[1] + 10],
                   color="#efefef", zorder=0)
    a.plot(lim, lim, color=GREY, lw=0.8)
    a.scatter(y, pred, s=9, color=BLUE, alpha=0.70, edgecolors="none")
    a.set(xlim=lim, ylim=lim, xlabel="Observed strength (MPa)", ylabel="Predicted strength (MPa)")
    a.text(0.03, 0.97, f"Test n = {len(y)}\nRMSE = {score['rmse']:.2f} MPa",
           transform=a.transAxes, va="top", fontsize=7)

    b.axhline(0, color=GREY, lw=0.8)
    b.scatter(age, residual, s=9, color=BLUE, alpha=0.65, edgecolors="none")
    b.set_xscale("log")
    bins = [(1, 7), (8, 28), (29, 100), (101, 400)]
    xs, med = [], []
    for lo, hi in bins:
        mask = (age >= lo) & (age <= hi)
        if mask.sum() >= 3:
            xs.append(np.median(age[mask])); med.append(np.median(residual[mask]))
    b.plot(xs, med, "s-", color=INK, lw=1.1, ms=3, label="Median by age group")
    b.set(xlabel="Specimen age (days, log scale)", ylabel="Residual, obs. − pred. (MPa)")
    b.legend(frameon=False, fontsize=6.5, loc="lower left")

    c.axhline(0, color=GREY, lw=0.8)
    c.scatter(pred, residual, s=9, color=BLUE, alpha=0.65, edgecolors="none")
    trend = lowess(residual, pred, frac=0.5, return_sorted=True)
    c.plot(trend[:, 0], trend[:, 1], color=INK, lw=1.1, label="LOWESS trend")
    for offset in [-10, 10]:
        c.axhline(offset, color=GREY, lw=0.7, ls=(0, (3, 2)))
    c.set(xlabel="Predicted strength (MPa)", ylabel="Residual, obs. − pred. (MPa)")
    c.legend(frameon=False, fontsize=7, loc="lower left")
    for p, letter in zip(axes, ["a", "b", "c"]):
        p.text(-0.14, 1.10, letter, transform=p.transAxes, fontweight="bold", fontsize=9)
    save(fig, path)
    plt.close(fig)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    FIG.mkdir(parents=True, exist_ok=True)
    if not (ROOT / "data" / "concrete_split.csv").exists():
        raise FileNotFoundError("Use the existing data/concrete_split.csv; do not regenerate the split.")
    d = load_split()
    train, test = d.loc[d["set"] == "train"].copy(), d.loc[d["set"] == "test"].copy()
    assert len(train) == 804 and len(test) == 201
    assert set(train.fold) == set(range(1, 6)) and set(test.fold) == {0}
    assert set(train.mix_id).isdisjoint(set(test.mix_id))
    assert (train.groupby("mix_id").fold.nunique() == 1).all()

    # 1. Tune the penalty without using the held-out test set.
    cv = cross_validate(train)
    summary, selected = summarize_cv(cv)

    # 2. Fit the chosen model on the complete training set; test it once.
    final = make_model(selected)
    final.fit(train[PREDICTORS], train[TARGET])
    prediction = final.predict(test[PREDICTORS])
    score = metrics(test[TARGET], prediction)
    details = error_table(test, prediction)

    # 3. Export outputs for the four-model comparison and report.
    test_out = test[["source_row", "mix_id", "age", TARGET]].rename(columns={TARGET: "y_true"}).copy()
    test_out["y_pred"] = prediction
    test_out["model"] = "polynomial_ridge"
    test_out[["source_row", "mix_id", "age", "y_true", "y_pred", "model"]].to_csv(
        OUT / "test_predictions_ridge.csv", index=False)
    cv.round(6).to_csv(OUT / "ridge_cv_folds.csv", index=False)
    summary.round(6).to_csv(OUT / "ridge_cv_summary.csv", index=False)
    details.round(6).to_csv(OUT / "ridge_error_groups.csv", index=False)
    terms = final.named_steps["polynomial"].get_feature_names_out(PREDICTORS)
    coefficients = pd.DataFrame({"term": terms, "coefficient_standardized": final.named_steps["ridge"].coef_})
    coefficients.round(6).to_csv(OUT / "ridge_coefficients.csv", index=False)
    facts = {"penalty": selected, "cv_rmse": float(summary.loc[np.isclose(summary.penalty, selected), "cv_rmse"].iloc[0]),
             "cv_rmse_sd": float(summary.loc[np.isclose(summary.penalty, selected), "cv_rmse_sd"].iloc[0]),
             "test": score, "n_train": int(len(train)), "n_test": int(len(test)),
             "n_polynomial_terms": int(len(terms)), "within_5": float((np.abs(test_out.y_true - prediction) <= 5).mean()),
             "within_10": float((np.abs(test_out.y_true - prediction) <= 10).mean()),
             "errors_by_group": details.to_dict("records")}
    (OUT / "ridge_facts.json").write_text(json.dumps(facts, indent=2))

    # 4. Generate publication-style PNG/PDF figures and short reading guides.
    plt = journal_style()
    fig_tuning(plt, cv, summary, selected, score["rmse"], FIG / "ridge_tuning")
    fig_diagnostics(plt, test, prediction, score, FIG / "ridge_diagnostics")
    (FIG / "ridge_tuning.txt").write_text(
        "Fig. X. Ridge penalty selection. (a) Mean five-fold validation RMSE across 20 logarithmically spaced "
        "penalties; the shaded band shows one standard deviation across folds. The diamond marks the chosen penalty. "
        "(b) RMSE for each grouped validation fold at the chosen penalty. The horizontal line is the mean.\n")
    (FIG / "ridge_diagnostics.txt").write_text(
        "Fig. Y. Test-set diagnostics for polynomial ridge regression. (a) Predicted versus observed compressive "
        "strength; the shaded band is within 10 MPa of the observed value. (b) Residual (observed minus predicted) "
        "versus specimen age; the line joins age-group medians. (c) Residual versus predicted strength; "
        "the dark line is a LOWESS trend, with dashed lines at ±10 MPa.\n")
    print("Selected ridge penalty:", f"{selected:.6g}")
    print("Five-fold validation RMSE:", f"{facts['cv_rmse']:.3f} ± {facts['cv_rmse_sd']:.3f} MPa")
    print("Test results:", {k: round(v, 4) for k, v in score.items()})
    print("Error analysis:\n", details.round(3).to_string(index=False))


if __name__ == "__main__":
    main()
