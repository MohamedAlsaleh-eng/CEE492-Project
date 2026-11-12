"""Shared data preparation for all predictive models.

Loads the UCI concrete dataset, removes exact duplicate records, assigns a
mixture ID to every unique recipe, and creates one grouped train/test split
plus five grouped validation folds inside the training set. The result is
written to data/concrete_split.csv so that every model (Python or Julia)
uses exactly the same partitions.

Run from the repository root:  python modeling/common.py
"""
import warnings
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "Concrete_Data.xls"
SPLIT = ROOT / "data" / "concrete_split.csv"

SEED = 492
TEST_FRACTION = 0.20
N_FOLDS = 5

INGREDIENTS = ["cement", "slag", "flyash", "water", "sp", "coarse", "fine"]
PREDICTORS = INGREDIENTS + ["age"]
TARGET = "strength"


def load_raw():
    """Original 1,030 records with short column names and 1-based source row numbers."""
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        d = pd.read_excel(RAW, engine="xlrd")
    d.columns = PREDICTORS + [TARGET]
    d.insert(0, "source_row", np.arange(1, len(d) + 1))
    return d


def clean_data():
    """Remove exact duplicate records and assign one mixture ID per unique recipe."""
    d = load_raw()
    dup = d.duplicated(subset=PREDICTORS + [TARGET], keep="first")
    clean = d[~dup].copy()
    clean["mix_id"] = clean.groupby(INGREDIENTS, sort=True).ngroup() + 1
    return clean, int(dup.sum())


def test_mixtures(clean, seed):
    """Add whole mixtures in random order until 20% of the records are in the test set."""
    rng = np.random.default_rng(seed)
    sizes = clean.groupby("mix_id").size()
    n_target = TEST_FRACTION * len(clean)
    ids, n = [], 0
    for m in rng.permutation(sizes.index.to_numpy()):
        if n >= n_target:
            break
        ids.append(m)
        n += sizes[m]
    return ids, rng


def make_split(seed=SEED):
    """Grouped train/test split and five grouped validation folds."""
    clean, n_dup = clean_data()
    ids, rng = test_mixtures(clean, seed)
    clean["set"] = np.where(clean["mix_id"].isin(ids), "test", "train")

    # folds: largest mixtures first (random tie-break), each to the fold with fewest records
    sizes = clean[clean["set"] == "train"].groupby("mix_id").size()
    ranked = sizes.to_frame("n").assign(tie=rng.permutation(len(sizes)))
    ranked = ranked.sort_values(["n", "tie"], ascending=[False, True])
    fold_n = np.zeros(N_FOLDS, dtype=int)
    fold_of = {}
    for m, n in ranked["n"].items():
        f = int(np.argmin(fold_n))
        fold_of[m] = f + 1
        fold_n[f] += n
    clean["fold"] = clean["mix_id"].map(fold_of).fillna(0).astype(int)
    clean[TARGET] = clean[TARGET].round(6)

    cols = ["source_row", "mix_id", "set", "fold"] + PREDICTORS + [TARGET]
    return clean[cols].sort_values("source_row").reset_index(drop=True), n_dup


def write_split():
    clean, n_dup = make_split()
    SPLIT.parent.mkdir(parents=True, exist_ok=True)
    clean.to_csv(SPLIT, index=False)
    return clean, n_dup


def load_split():
    """Read the shared split file (create it first if it does not exist)."""
    if not SPLIT.exists():
        write_split()
    return pd.read_csv(SPLIT)


def metrics(y, yhat):
    """RMSE and MAE in MPa, and R^2."""
    y, yhat = np.asarray(y, float), np.asarray(yhat, float)
    err = yhat - y
    return {
        "rmse": float(np.sqrt(np.mean(err ** 2))),
        "mae": float(np.mean(np.abs(err))),
        "r2": float(1 - np.sum(err ** 2) / np.sum((y - y.mean()) ** 2)),
    }


def journal_style():
    """Matplotlib settings shared by all project figures."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    plt.rcParams.update({
        "font.family": "sans-serif", "font.sans-serif": ["Helvetica", "Arial", "DejaVu Sans"],
        "font.size": 8, "axes.titlesize": 8, "axes.labelsize": 8, "xtick.labelsize": 7,
        "ytick.labelsize": 7, "legend.fontsize": 7, "axes.linewidth": 0.6,
        "xtick.major.width": 0.6, "ytick.major.width": 0.6, "xtick.minor.width": 0.4,
        "ytick.minor.width": 0.4, "xtick.major.size": 3, "ytick.major.size": 3,
        "xtick.minor.size": 1.8, "ytick.minor.size": 1.8, "xtick.direction": "out",
        "ytick.direction": "out", "axes.spines.top": False, "axes.spines.right": False,
        "savefig.dpi": 300, "pdf.fonttype": 42, "axes.labelcolor": "#222222",
        "xtick.color": "#333333", "ytick.color": "#333333", "text.color": "#222222",
        "mathtext.fontset": "custom", "mathtext.rm": "Helvetica", "mathtext.it": "Helvetica:italic",
    })
    return plt


if __name__ == "__main__":
    clean, n_dup = write_split()
    tr, te = clean[clean.set == "train"], clean[clean.set == "test"]
    print(f"exact duplicates removed: {n_dup}")
    print(f"records after cleaning: {len(clean)}, mixtures: {clean.mix_id.nunique()}")
    print(f"train: {len(tr)} records / {tr.mix_id.nunique()} mixtures ({len(tr) / len(clean):.1%})")
    print(f"test:  {len(te)} records / {te.mix_id.nunique()} mixtures ({len(te) / len(clean):.1%})")
    print(tr.groupby("fold").agg(records=("mix_id", "size"), mixtures=("mix_id", "nunique")))
    print(f"wrote {SPLIT.relative_to(ROOT)}")
