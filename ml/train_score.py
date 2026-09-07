"""
Predictive scoring layer for the Scotland ITS analytics platform.
================================================================

Two models, both framed as *operational forecasts* - they use only
information that is knowable in advance (calendar, site characteristics,
forecast weather, planned roadworks and planned events). Realised flow,
speed and journey time are deliberately excluded, because a model that
needs to observe congestion in order to predict congestion has no
operational value to a control room.

  Model A  Congestion forecast      multi-class, target = Congestion_Level
  Model B  Collision risk           binary,  target = Accident_Flag

Validation is a strict temporal hold-out: train on 2023-2024, test on 2025.
In-sample rows are scored with 3-fold cross-validated predictions so that
the scores published to the warehouse are never fitted on themselves.

Outputs (parquet, consumed by the dbt ml marts):
  ml_risk_scores.parquet    one row per observation
  ml_model_metrics.parquet  one row per model / metric / split
"""

import json
import os

# Determinism: HistGradientBoosting reduces over OpenMP threads, and the
# reduction order varies between runs. Without pinning, published metrics move
# by roughly +/-0.5pp run to run. Set before importing numpy / sklearn.
for _v in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS", "MKL_NUM_THREADS"):
    os.environ.setdefault(_v, "1")

import numpy as np
import pandas as pd
import duckdb
from datetime import datetime, timezone

from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.model_selection import cross_val_predict, StratifiedKFold
from sklearn.preprocessing import OrdinalEncoder
from sklearn.metrics import (f1_score, recall_score, precision_score,
                             average_precision_score, roc_auc_score,
                             confusion_matrix, balanced_accuracy_score)

DB   = os.environ.get("ITS_DUCKDB_PATH", "../data/its_warehouse.duckdb")
OUT  = os.environ.get("ITS_ML_OUT", "../data/ml")
MODEL_VERSION = "v1.2.0"
SEED = 42
os.makedirs(OUT, exist_ok=True)

# ---------------------------------------------------------------- load
QUERY = """
select
    f.observation_id, f.date_key, f.time_key, f.observation_date,
    d.calendar_year, d.month_number, d.day_of_week_number, d.is_weekend,
    d.is_school_holiday, d.meteorological_season,
    t.time_band, t.is_peak,
    s.site_key, s.city_name, s.road_id, s.road_type, s.corridor,
    s.urbanisation_band, s.settlement_tier, s.speed_limit_kmh,
    s.segment_length_km, s.design_capacity_band, s.km_from_city_centroid,
    f.temperature_c, f.rainfall_mm, f.wind_speed_kmh, f.visibility_km,
    f.roadworks_flag, f.lane_closure_flag, f.public_event_flag,
    e.event_type,
    c.congestion_level, c.congestion_key,
    f.accident_flag,
    f.vehicle_count, f.average_speed_kmh, f.journey_time_index,
    f.delay_vehicle_hours, f.delay_cost_gbp, f.annualisation_factor
from marts.fct_traffic_observation f
join marts.dim_date       d on f.date_key       = d.date_key
join marts.dim_time       t on f.time_key       = t.time_key
join marts.dim_site       s on f.site_key       = s.site_key
join marts.dim_event      e on f.event_key      = e.event_key
join marts.dim_congestion c on f.congestion_key = c.congestion_key
"""

con = duckdb.connect(DB, read_only=True)
df = con.execute(QUERY).df()
con.close()
print(f"loaded {len(df):,} clean observations")

# ------------------------------------------------------- feature space
CAT = ["meteorological_season", "time_band", "city_name", "road_id",
       "road_type", "corridor", "urbanisation_band", "settlement_tier",
       "design_capacity_band", "event_type"]
NUM = ["month_number", "day_of_week_number", "time_key", "is_weekend",
       "is_school_holiday", "is_peak", "speed_limit_kmh",
       "segment_length_km", "km_from_city_centroid",
       "temperature_c", "rainfall_mm", "wind_speed_kmh", "visibility_km",
       "roadworks_flag", "lane_closure_flag", "public_event_flag"]

# cyclical encodings for hour and month
df["hour_sin"]  = np.sin(2 * np.pi * df.time_key / 24)
df["hour_cos"]  = np.cos(2 * np.pi * df.time_key / 24)
df["month_sin"] = np.sin(2 * np.pi * df.month_number / 12)
df["month_cos"] = np.cos(2 * np.pi * df.month_number / 12)
NUM += ["hour_sin", "hour_cos", "month_sin", "month_cos"]

enc = OrdinalEncoder(handle_unknown="use_encoded_value", unknown_value=-1)
X_cat = pd.DataFrame(enc.fit_transform(df[CAT].astype(str)),
                     columns=CAT, index=df.index)
X = pd.concat([X_cat, df[NUM].astype(float)], axis=1)
cat_mask = [c in CAT for c in X.columns]

is_train = df.calendar_year < 2025
print(f"train {is_train.sum():,}  |  test {(~is_train).sum():,}")

metrics = []
def log(model, split, metric, value, note=""):
    metrics.append(dict(model_name=model, data_split=split, metric_name=metric,
                        metric_value=float(value), note=note,
                        model_version=MODEL_VERSION))

# =====================================================================
# Model A - congestion forecast
# =====================================================================
y_a = df.congestion_level.values
clf_a = HistGradientBoostingClassifier(
    max_iter=400, learning_rate=0.08, max_leaf_nodes=48,
    l2_regularization=1.0, categorical_features=cat_mask,
    class_weight="balanced", random_state=SEED)

clf_a.fit(X[is_train], y_a[is_train])
proba_test_a = clf_a.predict_proba(X[~is_train])
pred_test_a  = clf_a.classes_[proba_test_a.argmax(1)]

log("Congestion Forecast", "Test 2025", "Macro F1",
    f1_score(y_a[~is_train], pred_test_a, average="macro"))
log("Congestion Forecast", "Test 2025", "Balanced Accuracy",
    balanced_accuracy_score(y_a[~is_train], pred_test_a))
log("Congestion Forecast", "Test 2025", "Accuracy",
    (pred_test_a == y_a[~is_train]).mean())
for lvl in ["Low", "Medium", "High", "Severe"]:
    log("Congestion Forecast", "Test 2025", f"Recall - {lvl}",
        recall_score(y_a[~is_train], pred_test_a, labels=[lvl], average="macro",
                     zero_division=0))
    log("Congestion Forecast", "Test 2025", f"Precision - {lvl}",
        precision_score(y_a[~is_train], pred_test_a, labels=[lvl], average="macro",
                        zero_division=0))
maj = pd.Series(y_a[is_train]).mode()[0]
log("Congestion Forecast", "Baseline", "Macro F1",
    f1_score(y_a[~is_train], np.full(len(pred_test_a), maj),
             average="macro", zero_division=0), "majority class")

# cross-validated in-sample scores
cv = StratifiedKFold(3, shuffle=True, random_state=SEED)
proba_train_a = cross_val_predict(clf_a, X[is_train], y_a[is_train],
                                  cv=cv, method="predict_proba", n_jobs=1)
classes_a = clf_a.classes_
proba_a = np.zeros((len(df), len(classes_a)))
proba_a[is_train.values] = proba_train_a
proba_a[~is_train.values] = proba_test_a
prob_map = {c: proba_a[:, i] for i, c in enumerate(classes_a)}
pred_a = classes_a[proba_a.argmax(1)]
prob_congested = prob_map["High"] + prob_map["Severe"]

# =====================================================================
# Model B - collision risk
# =====================================================================
y_b = df.accident_flag.values.astype(int)
clf_b = HistGradientBoostingClassifier(
    max_iter=300, learning_rate=0.06, max_leaf_nodes=24,
    l2_regularization=2.0, min_samples_leaf=60,
    categorical_features=cat_mask, class_weight="balanced",
    random_state=SEED)

clf_b.fit(X[is_train], y_b[is_train])
risk_test = clf_b.predict_proba(X[~is_train])[:, 1]
base_rate = y_b[~is_train].mean()

log("Collision Risk", "Test 2025", "PR AUC",
    average_precision_score(y_b[~is_train], risk_test))
log("Collision Risk", "Test 2025", "ROC AUC",
    roc_auc_score(y_b[~is_train], risk_test))
log("Collision Risk", "Baseline", "PR AUC", base_rate, "positive class rate")
for k in (0.05, 0.10, 0.20):
    thr = np.quantile(risk_test, 1 - k)
    top = risk_test >= thr
    cap = y_b[~is_train][top].sum() / max(y_b[~is_train].sum(), 1)
    log("Collision Risk", "Test 2025", f"Capture at top {int(k*100)}%", cap)
    log("Collision Risk", "Test 2025", f"Lift at top {int(k*100)}%",
        (y_b[~is_train][top].mean() / base_rate) if base_rate else 0)

risk_train = cross_val_predict(clf_b, X[is_train], y_b[is_train],
                               cv=cv, method="predict_proba", n_jobs=1)[:, 1]
risk = np.zeros(len(df))
risk[is_train.values] = risk_train
risk[~is_train.values] = risk_test

# =====================================================================
# Publish
# =====================================================================
scores = pd.DataFrame({
    "observation_id":            df.observation_id,
    "model_version":             MODEL_VERSION,
    "data_split":                np.where(is_train, "Train 2023-2024", "Test 2025"),
    "predicted_congestion_level": pred_a,
    "prob_low":       prob_map["Low"],
    "prob_medium":    prob_map["Medium"],
    "prob_high":      prob_map["High"],
    "prob_severe":    prob_map["Severe"],
    "prob_congested": prob_congested,
    "collision_risk_score": risk,
})
scores["collision_risk_percentile"] = scores.collision_risk_score.rank(pct=True).round(4)
scores["collision_risk_decile"] = pd.qcut(scores.collision_risk_score.rank(method="first"),
                                          10, labels=range(1, 11)).astype(int)
scores["collision_risk_band"] = pd.cut(
    scores.collision_risk_percentile,
    bins=[-0.001, 0.50, 0.80, 0.95, 1.0],
    labels=["Low", "Moderate", "Elevated", "Priority"]).astype(str)
scores["is_congestion_prediction_correct"] = (
    scores.predicted_congestion_level.values == df.congestion_level.values).astype(int)
scores["scored_at"] = datetime.now(timezone.utc)

# DuckDB is used as the parquet writer so the pipeline has no pyarrow dependency
_w = duckdb.connect()
_w.register("scores_df", scores)
_w.execute(f"COPY scores_df TO '{OUT}/ml_risk_scores.parquet' (FORMAT PARQUET)")

met = pd.DataFrame(metrics)
met["trained_at"] = datetime.now(timezone.utc)
met["training_rows"] = int(is_train.sum())
met["test_rows"] = int((~is_train).sum())
_w.register("metrics_df", met)
_w.execute(f"COPY metrics_df TO '{OUT}/ml_model_metrics.parquet' (FORMAT PARQUET)")
_w.close()

print("\n--- Congestion forecast (test 2025) ---")
print(pd.DataFrame(confusion_matrix(y_a[~is_train], pred_test_a, labels=classes_a),
                   index=[f"actual {c}" for c in classes_a],
                   columns=[f"pred {c}" for c in classes_a]))
print("\n--- Metrics ---")
print(met[["model_name","data_split","metric_name","metric_value"]]
        .to_string(index=False, float_format=lambda v: f"{v:.4f}"))
print(f"\nwrote {len(scores):,} scores to {OUT}")
