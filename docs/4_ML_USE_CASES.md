# Machine Learning Use Cases — Scotland ITS Dataset

Twelve project briefs, ordered from beginner to advanced. Each states the target, the honest feature set (leakage removed), a validation scheme that respects time, a baseline to beat, and the realistic performance ceiling given how the data was generated.

**Universal rules for this dataset:**

1. **Split by time, never at random.** Train on 2023–2024, test on 2025. Random splits leak seasonal and site-level structure and will flatter every model.
2. **Drop deterministic children of the target.** `Congestion_Level` is a hard threshold on `Journey_Time_Index`; `Journey_Time_Minutes` is segment length ÷ `Average_Speed_kmh`; `Vehicle_Count` is the sum of the class counts; `CO2_Emission_kg` is a formula over counts and speed.
3. **Site identity carries most of the level.** Encode the (`Latitude`,`Longitude`,`Road_ID`) site as a categorical, or use target encoding — but fit the encoder on training folds only.
4. **Cyclical time encoding.** Use `sin/cos(2π·hour/24)` and `sin/cos(2π·month/12)` rather than raw integers.

---

## Tier 1 — Foundational (regression & classification)

### 1. Congestion level classification (multi-class)
**Target:** `Congestion_Level` (Low / Medium / High / Severe).
**Features:** hour (cyclical), day of week, month, `School_Holiday_Flag`, site identity, `Road_Type`, `Speed_Limit_kmh`, `Rainfall_mm`, `Temperature_C`, `Visibility_km`, `Wind_Speed_kmh`, `Roadworks_Flag`, `Lane_Closure_Flag`, `Public_Event_Flag`, `Event_Type`, `Accident_Flag`, `Incident_Type`.
**Must exclude:** `Journey_Time_Index`, `Journey_Time_Minutes`, `Average_Speed_kmh`, `Vehicle_Count`, `CO2_Emission_kg` (all encode the answer).
**Why it's non-trivial:** severe class imbalance (Low 71.0% / Medium 20.9% / High 5.9% / Severe 2.3%). Accuracy is a useless metric here — the majority-class baseline already scores 0.71. Use macro-F1, per-class recall and a confusion matrix; try class weights, focal loss or SMOTE and compare honestly.
**Baseline → target:** majority class macro-F1 ≈ 0.21; a tuned gradient-boosted tree should reach macro-F1 0.55–0.70 with Severe recall being the hard part.
**Skills:** imbalanced classification, ordinal targets, cost-sensitive learning, threshold tuning.

### 2. Average speed regression
**Target:** `Average_Speed_kmh`.
**Features:** as above plus `Vehicle_Count` and the class counts (flow is a legitimate causal input to speed).
**Must exclude:** `Journey_Time_Minutes`, `Journey_Time_Index`, `Congestion_Level`.
**Twist:** the underlying relationship is a BPR curve — speed = free-flow ÷ (1 + 0.52·(v/c)^2.9). Linear regression will underfit badly; the interesting exercise is showing that a tree ensemble or a spline/GAM recovers the non-linear shape, then plotting partial dependence of speed on flow and comparing it against the true curve.
**Baseline → target:** mean predictor RMSE ≈ 22 km/h; linear model ≈ 15–17; gradient boosting ≈ 8–11 km/h, limited by the ~4.5% corrupted rows unless you filter them.
**Skills:** non-linear regression, partial dependence plots, residual diagnostics, robust loss functions (Huber) against the speed outliers.

### 3. Traffic volume forecasting
**Target:** `Vehicle_Count` (or its log, which is better behaved — the raw distribution is right-skewed with a heavy tail).
**Features:** calendar, site, weather, holiday and event flags.
**Note the sampling caveat:** rows are independently sampled site-hours, so there is *no* lag structure at a single detector. Either (a) frame this as cross-sectional demand estimation, or (b) aggregate to city-day / city-hour panels first and then do proper time-series forecasting with lags, rolling means and Fourier seasonality.
**Baseline → target:** a site×hour×daytype lookup table is a strong baseline (MAPE ≈ 25–30%); a good model should reach 15–20% MAPE on the aggregated panel.
**Skills:** target transformation, hierarchical aggregation, seasonal decomposition, MAPE vs sMAPE trade-offs.

---

## Tier 2 — Applied (imbalance, anomalies, causality)

### 4. Accident risk prediction (highly imbalanced binary)
**Target:** `Accident_Flag` — positive rate **0.36%** (~360 positives).
**Features:** weather (rain, visibility, temperature, wind), congestion proxies, hour, month, road type, speed limit, roadworks.
**This is the flagship exercise.** With a 1:277 imbalance, accuracy and even ROC-AUC are misleading; **precision-recall AUC** and lift-at-top-k% are what matter. Realistic result: PR-AUC of 0.02–0.06 against a 0.0036 random baseline — a 5–15× lift, which is genuinely useful for patrol deployment even though it sounds terrible in absolute terms.
**Learning objective:** teaching that "my model has 99.6% accuracy" is a failure, not a success.
**Extensions:** calibrated probabilities (Platt / isotonic), cost-sensitive thresholding where a missed accident costs 50× a false alarm, and Brier score decomposition.
**Skills:** rare-event modelling, PR curves, calibration, resampling strategies, business-cost optimisation.

### 5. Unsupervised anomaly / sensor-fault detection
**Task:** find the ~4.5% of rows with injected defects **without** using the defect definitions.
**Approach:** Isolation Forest, One-Class SVM, Local Outlier Factor, or an autoencoder over the numeric block; compare against a rules-based detector.
**Evaluation:** build approximate ground truth using the rules in the Data Quality Report (negative values, impossible speeds, dead zeros, sum-mismatch, site-hour spikes, duplicate keys), then measure precision/recall of the unsupervised model against it.
**Expected finding, and the lesson:** hard defects (negatives, 300 km/h speeds) are trivially caught by both approaches; the 456 injected traffic spikes are only ~59% detectable even with the site-hour median rule, because a 3× spike at 03:00 is still within the plausible range for 08:00. Unsupervised methods over-flag genuine severe-congestion events. Recall of 0.55–0.75 at precision 0.6–0.8 is a good result.
**Skills:** unsupervised learning, evaluation without labels, rules vs models, false-positive cost analysis.

### 6. Journey time prediction for traveller information
**Target:** `Journey_Time_Minutes`.
**Features:** flow, weather, incidents, roadworks, calendar, site.
**Must exclude:** `Average_Speed_kmh` and `Journey_Time_Index`.
**Business framing:** an ITS variable-message-sign system needs a point estimate *and* an uncertainty band. Fit quantile regression (P10 / P50 / P90) or use conformal prediction, then evaluate interval coverage — a "45 minutes, usually 40–55" message is far more useful than a bare point estimate.
**Extra credit:** incidents inflate journey time 2.2× on average, but only 0.36% of rows have one. Show how much of the P90 tail your model captures.
**Skills:** quantile regression, conformal prediction, prediction-interval coverage, tail modelling.

### 7. Incident type classification
**Target:** `Incident_Type` restricted to non-`None` rows (2,720 rows: Breakdown 1,678, Debris 526, Collision 303, Severe Weather 112, Vehicle Fire 101).
**Why interesting:** a small, imbalanced, 5-class problem with genuinely weak signal. Severe Weather is separable from the weather columns; Breakdown vs Debris is close to irreducible noise. This is a good exercise in **recognising a Bayes-error ceiling** and not chasing it — expect macro-F1 around 0.35–0.50 and be able to explain why higher would be suspicious.
**Skills:** small-sample classification, learning curves, knowing when to stop.

### 8. Causal impact of roadworks (quasi-experimental)
**Question:** what is the causal effect of `Roadworks_Flag` on `Journey_Time_Index`?
**Naive answer:** 1.143 → 1.408, a 23% increase. But roadworks are non-randomly scheduled — concentrated in summer and overnight (21:00–05:00) when traffic is light, which *understates* the true effect.
**Method:** propensity-score matching or inverse-probability weighting on hour, month, site, road type and weather; or a doubly-robust estimator; or a DiD design using sites with and without works. Compare the adjusted ATE with the naive difference and quantify the confounding bias.
**Skills:** causal inference, confounding, propensity scores, sensitivity analysis. The generator's ground-truth mechanism (capacity multiplied by 0.80–0.93, or by (1 − 1/lanes) under lane closure, plus a 1.05–1.22× delay multiplier) means you can **check your estimate against the truth** — rare and valuable in a teaching dataset.

---

## Tier 3 — Advanced

### 9. Emissions modelling and policy simulation
**Target:** `CO2_Emission_kg`, then counterfactual scenarios.
**Exercise:** fit a model, then simulate: what happens to total CO₂ if (a) HGV traffic shifts entirely to 22:00–05:00, (b) a 20% mode shift from cars to buses occurs in Glasgow and Edinburgh peaks, (c) average speeds rise 10 km/h through better traffic management? Note the non-obvious trade-off — the congestion penalty means higher speeds cut emissions, but higher speeds also induce more demand, which the data cannot tell you about.
**Deliverable:** a scenario table with tonnes CO₂ saved per year and an explicit statement of which assumptions the data cannot validate.
**Skills:** simulation, scenario analysis, sensitivity testing, communicating model limits.

### 10. Spatio-temporal clustering of network behaviour
**Task:** cluster the 74 sensor sites by their normalised 24-hour × 7-day flow and speed signatures.
**Expected structure:** urban commuter links (sharp twin peaks), inter-urban freight links (flat profile, high overnight HGV share, e.g. M74/A9), and rural/leisure links (weekend-dominant, summer-dominant, e.g. A82).
**Method:** build a site × (hour × daytype) feature matrix, reduce with PCA or UMAP, cluster with k-means or hierarchical clustering, and validate with silhouette score plus a qualitative read against road type. **Then check** whether your clusters recover `Road_Type` — partial agreement is the interesting result, because the A9 behaves like a motorway and the urban section of the M8 behaves like an arterial.
**Skills:** feature engineering from panel data, dimensionality reduction, cluster validation, interpretation.

### 11. Multi-task / multi-output learning
**Task:** jointly predict `Average_Speed_kmh`, `Journey_Time_Index` and `Air_Quality_Index` from a shared representation.
**Why:** these three share upstream causes (flow, weather, incidents). A multi-task neural network with a shared trunk and three heads should beat three independent models on the weakest target (AQI), demonstrating positive transfer. Watch for negative transfer if you weight the losses badly — that failure mode is itself the lesson.
**Skills:** multi-task learning, loss weighting, shared representations, transfer diagnostics.

### 12. End-to-end MLOps / data engineering pipeline
Not a model — a system. Build the full path: raw CSV → validation layer (Great Expectations or Pandera, encoding every rule from the Data Quality Report) → quarantine table for the 4.5% defective rows → star-schema warehouse (see the Data Dictionary) → feature store with point-in-time correctness → trained model → batch scoring → drift monitoring.
**Drift exercise:** train on 2023, score 2024 and 2025. The generator applies +2.8% and +4.9% year-on-year demand growth, so you should detect genuine covariate drift in `Vehicle_Count` and be able to distinguish it from concept drift (there is none — the speed-flow relationship is stationary). Being able to tell those two apart is the point.
**Skills:** data contracts, orchestration (Airflow/Dagster/dbt), warehouse modelling, PSI/KS drift monitoring, CI for data.

---

## Business intelligence angles (non-ML)

For BI and analytics portfolios rather than modelling:

- **Network performance dashboard** — JTI heat map by road × hour × month, with congestion hot-spot ranking and a peak-spreading view.
- **Council reporting pack** — per-council-area KPIs: mean delay, severe-congestion hours, accident counts, CO₂ tonnage, AQI exceedances. Aberdeen and Dundee make a good comparison pair.
- **Incident response analysis** — delay attributable to incidents by type and location; expected benefit of a 10-minute faster clearance time.
- **Weather resilience report** — quantify the congestion and accident penalty of rain, fog and freezing conditions; identify the sites most sensitive to weather (candidates for gritting priority and VMS warnings).
- **Air quality vs traffic** — evidence base for a Low Emission Zone: which sites, which hours, which vehicle classes contribute most; use the HGV/bus share and AQI relationship.
- **Data quality scorecard** — sensor uptime, defect rate and completeness by site and month; a maintenance prioritisation list driven by the 34% defect rate on `Faulty` sensors.

---

## Getting started

```python
import pandas as pd, numpy as np

df = pd.read_csv("scotland_its_dataset.csv",
                 keep_default_na=False, na_values=[""],
                 parse_dates=["Date"])

# site key
df["Site_ID"] = (df.Road_ID + "_" +
                 df.Latitude.round(4).astype(str) + "_" +
                 df.Longitude.round(4).astype(str))

# cyclical time
df["hour_sin"]  = np.sin(2*np.pi*df.Hour/24);   df["hour_cos"]  = np.cos(2*np.pi*df.Hour/24)
df["month_sin"] = np.sin(2*np.pi*df.Month/12);  df["month_cos"] = np.cos(2*np.pi*df.Month/12)
df["is_weekend"] = df.Day_of_Week.isin(["Saturday","Sunday"]).astype(int)
df["is_peak"]    = df.Hour.isin([7,8,16,17,18]).astype(int)

# temporal split — never random
train = df[df.Year < 2025]
test  = df[df.Year == 2025]
```
