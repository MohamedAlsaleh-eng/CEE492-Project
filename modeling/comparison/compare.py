"""Validation and test RMSE of all four models in one figure.

MLR and polynomial ridge values are read from their output files. The regression
tree and random forest were run in Julia and their output files are not in the
repository, so their values are taken from the report (Sections III-D and III-E).

Run from the repository root:  python modeling/comparison/compare.py
"""
import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd

HERE = Path(__file__).resolve().parent
MODELING = HERE.parent
sys.path.insert(0, str(MODELING))  # shared code in modeling/common.py
from common import journal_style  # noqa: E402

FIG = HERE / "figures"
INK, BLUE, GREY = "#222222", "#2166ac", "#8c8c8c"


def load_results():
    mlr = pd.read_csv(MODELING / "mlr" / "outputs" / "mlr_summary.csv", index_col="variant")
    mlr_facts = json.loads((MODELING / "mlr" / "outputs" / "mlr_facts.json").read_text())
    ridge = json.loads((MODELING / "ridge" / "outputs" / "ridge_facts.json").read_text())
    rows = [
        # label, validation mean, validation SD, test RMSE
        ("Mean-only predictor", np.nan, np.nan, mlr_facts["naive_test"]["rmse"]),
        ("MLR, 8 source predictors", mlr.loc["baseline", "cv_rmse"], mlr.loc["baseline", "cv_rmse_sd"],
         mlr.loc["baseline", "test_rmse"]),
        ("MLR, ln(age) + w/b", mlr.loc["log_age_wb", "cv_rmse"], mlr.loc["log_age_wb", "cv_rmse_sd"],
         mlr.loc["log_age_wb", "test_rmse"]),
        ("Polynomial ridge", ridge["cv_rmse"], ridge["cv_rmse_sd"], ridge["test"]["rmse"]),
        ("Regression tree", 8.70, np.nan, 6.756),   # SD across folds not reported
        ("Random forest", 6.34, 0.89, 5.23),
    ]
    return pd.DataFrame(rows, columns=["model", "val", "val_sd", "test"])


def fig_comparison(plt, res, path):
    from matplotlib.lines import Line2D
    fig, ax = plt.subplots(figsize=(3.5, 2.35))
    y = np.arange(len(res))[::-1]
    best = res["val"].idxmin()
    for yi, (i, r) in zip(y, res.iterrows()):
        col = BLUE if i == best else INK
        if not np.isnan(r["val"]):
            ax.errorbar(r["val"], yi + 0.13, xerr=0 if np.isnan(r["val_sd"]) else r["val_sd"], fmt="o", ms=4.2,
                        color=col, mec="white", mew=0.6, elinewidth=1.1, capsize=0, zorder=3)
        ax.scatter(r["test"], yi - 0.13, marker="D", s=14, facecolor="white", edgecolor=col, lw=0.9, zorder=3)
    ax.set_yticks(y)
    ax.set_yticklabels(res["model"])
    ax.get_yticklabels()[best].set_fontweight("bold")
    ax.tick_params(axis="y", length=0)
    ax.spines["left"].set_visible(False)
    ax.set_xlim(4, 16.5)
    ax.set_ylim(-0.6, len(res) - 0.4)
    ax.set_xlabel("RMSE (MPa)")
    ax.xaxis.grid(True, color="#ededed", lw=0.5)
    ax.set_axisbelow(True)
    handles = [Line2D([], [], marker="o", ls="-", ms=4.2, color=INK, mec="white", mew=0.6, lw=1.1,
                      label="Validation, mean ± SD"),
               Line2D([], [], marker="D", ls="", ms=3.8, mfc="white", mec=INK, mew=0.9, label="Test set")]
    ax.legend(handles=handles, loc="lower right", frameon=False, handletextpad=0.4, borderaxespad=0.1)
    FIG.mkdir(parents=True, exist_ok=True)
    fig.savefig(path.with_suffix(".pdf"), bbox_inches="tight", pad_inches=0.03)
    fig.savefig(path.with_suffix(".png"), dpi=300, bbox_inches="tight", pad_inches=0.03)
    plt.close(fig)


if __name__ == "__main__":
    res = load_results()
    print(res.round(3).to_string(index=False))
    fig_comparison(journal_style(), res, FIG / "model_comparison")
