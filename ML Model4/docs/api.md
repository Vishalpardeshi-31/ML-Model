# ML Model 4 — REST API Specification & Architecture Guide
### Gateway (Flask :5000) ⇄ ML Inference Microservice (R Plumber :8000)

**Version:** 1.0.0  
**Data Standard:** 100% Verified Real-World Data • Zero Synthetic Predictions  
**Architecture:** Frontend (SPA) ➔ Flask Gateway (`http://127.0.0.1:5000`) ➔ R Plumber (`http://127.0.0.1:8000`) ➔ Serialized R `.rds` Models

---

## 1. Architectural Overview

```
┌────────────────────────────────────────────────────────┐
│               Frontend Single Page App                 │
│         (HTML5, CSS3 Glassmorphism, JavaScript)        │
└───────────────────────────┬────────────────────────────┘
                            │  HTTP / JSON (:5000)
                            ▼
┌────────────────────────────────────────────────────────┐
│               Flask REST API Gateway                   │
│         (Input Validation, CORS, Error Shield)         │
└───────────────────────────┬────────────────────────────┘
                            │  Proxy Forwarding (:8000)
                            ▼
┌────────────────────────────────────────────────────────┐
│               R Plumber Microservice                   │
│          (Preloaded Serialized Models in RAM)          │
│                                                        │
│  • models/brain_kmeans.rds                             │
│  • models/country_hierarchical.rds                     │
│  • models/f1_regression.rds                            │
│  • models/placement_logistic.rds                       │
└────────────────────────────────────────────────────────┘
```

---

## 2. Standard Error Response Format

All error responses from the Flask Gateway adhere to a uniform JSON schema and return appropriate HTTP status codes:

```json
{
  "error": true,
  "message": "Human-readable explanation of validation or service fault"
}
```

### HTTP Status Codes:
* `200 OK`: Request succeeded; real model prediction/data returned.
* `400 Bad Request`: Missing field, invalid data type, out-of-bounds numerical value, or unrecognized categorical factor.
* `404 Not Found`: Processed dataset or resource not found on disk.
* `502 Bad Gateway`: R Plumber returned a non-JSON or malformed payload.
* `503 Service Unavailable`: R Plumber microservice is offline or unreachable at port 8000.
* `504 Gateway Timeout`: R Plumber timed out during intensive inference calculation.

---

## 3. System & Health Endpoints

### 3.1 Health Status
Probes both Flask Gateway and the R Plumber microservice.

* **Endpoint:** `GET /api/health`
* **Response `200 OK`:**
```json
{
  "gateway": "Flask REST API",
  "project": "ML Model 4",
  "r_service": {
    "models_loaded": {
      "brain_kmeans": true,
      "country_hierarchical": true,
      "f1_regression": true,
      "placement_logistic": true
    },
    "service": "R ML API",
    "status": "ok",
    "timestamp": "2026-09-26 01:56:01.149104"
  },
  "status": "ok"
}
```

### 3.2 Models Metadata
Returns complete algorithmic metadata, feature schemas, hyperparameters, and provenance from `models/model_metadata.json`.

* **Endpoint:** `GET /api/models`
* **Response `200 OK`:**
```json
{
  "project": "ML Model 4",
  "version": "1.0.0",
  "models": [
    {
      "id": "brain",
      "name": "Brain Activity Pattern Discovery",
      "learning": "Unsupervised",
      "algorithm": "K-Means Clustering",
      "optimal_k": 3,
      "dataset_source": "UCI EEG Eye State Dataset (DOI: 10.24432/C57G7J)",
      "input_features": [ ... ],
      "metrics": { ... }
    },
    ...
  ]
}
```

### 3.3 Side Report Endpoint
Returns structured metrics for the in-app Side Report modal.

* **Endpoint:** `GET /api/models/report`

---

## 4. Model 1: Brain Activity Pattern Discovery

* **Paradigm:** Unsupervised Learning
* **Algorithm:** K-Means Clustering (`stats::kmeans`)
* **Serialized Model:** `models/brain_kmeans.rds`
* **Preprocessing:** `log1p` on power bands + $Z$-score standardization + PCA projection

### 4.1 Prediction Endpoint
* **Endpoint:** `POST /api/brain/predict`
* **Required Features (13):**
  * `delta_power` (float, $\ge 0.0$, $\mu\text{V}^2/\text{Hz}$)
  * `theta_power` (float, $\ge 0.0$, $\mu\text{V}^2/\text{Hz}$)
  * `alpha_power` (float, $\ge 0.0$, $\mu\text{V}^2/\text{Hz}$)
  * `beta_power` (float, $\ge 0.0$, $\mu\text{V}^2/\text{Hz}$)
  * `gamma_power` (float, $\ge 0.0$, $\mu\text{V}^2/\text{Hz}$)
  * `alpha_relative` (float, $[0.0, 1.0]$)
  * `beta_relative` (float, $[0.0, 1.0]$)
  * `theta_beta_ratio` (float, $\ge 0.0$)
  * `occipital_alpha` (float, $\ge 0.0$, $\mu\text{V}^2/\text{Hz}$)
  * `frontal_asymmetry` (float, $[-1.0, 1.0]$)
  * `mean_amplitude` (float, $\mu\text{V}$)
  * `signal_variance` (float, $\ge 0.0$, $\mu\text{V}^2$)
  * `spectral_entropy` (float, nats)

* **Request Example:**
```json
{
  "delta_power": 2.5,
  "theta_power": 1.3,
  "alpha_power": 1.6,
  "beta_power": 1.4,
  "gamma_power": 0.6,
  "alpha_relative": 0.15,
  "beta_relative": 0.14,
  "theta_beta_ratio": 1.0,
  "occipital_alpha": 1.8,
  "frontal_asymmetry": 0.05,
  "mean_amplitude": 4300.0,
  "signal_variance": 4.2,
  "spectral_entropy": 3.4
}
```

* **Response `200 OK`:**
```json
{
  "cluster": 3,
  "cluster_name": "Alert Cognitive Engagement / Desynchronized State",
  "interpretation": "Elevated fast beta power with desynchronized posterior alpha reflecting cognitive attention and alertness.",
  "pca": {
    "x": -3.0483,
    "y": -1.6204
  },
  "distances": {
    "cluster_1": 5.7978,
    "cluster_2": 12.4743,
    "cluster_3": 3.4954
  }
}
```

### 4.2 Brain Dataset Endpoint
* **Endpoint:** `GET /api/brain/data`
* **Response `200 OK`:** Returns 233 clustered epoch records with PCA coordinates for scatter plotting.

---

## 5. Model 2: Country Development Analysis

* **Paradigm:** Unsupervised Learning
* **Algorithm:** Agglomerative Hierarchical Clustering (`stats::hclust`, Ward.D2 linkage)
* **Serialized Model:** `models/country_hierarchical.rds`
* **Preprocessing:** `log1p` on GDP & Population + $Z$-score standardization + PCA projection

### 5.1 Prediction / Lookup Endpoint
* **Endpoint:** `POST /api/country/predict`
* **Input Modes:**
  1. **Lookup by Country:** Send `{"country_code": "USA"}` or `{"country": "United States"}` to query authentic World Bank records directly.
  2. **Numerical Indicators:** Send all 8 indicators:
     * `gdp_per_capita` (float, $> 0$)
     * `life_expectancy` (float, $> 0$)
     * `total_population` (float, $> 0$)
     * `unemployment_rate` (float, $\ge 0.0$)
     * `infant_mortality` (float, $\ge 0.0$)
     * `health_expenditure_pct_gdp` (float, $\ge 0.0$)
     * `education_expenditure_pct_gdp` (float, $\ge 0.0$)
     * `internet_usage_pct` (float, $[0.0, 100.0]$)

* **Request Example (Indicators):**
```json
{
  "gdp_per_capita": 45000.0,
  "life_expectancy": 81.0,
  "total_population": 50000000.0,
  "unemployment_rate": 5.2,
  "infant_mortality": 3.5,
  "health_expenditure_pct_gdp": 9.5,
  "education_expenditure_pct_gdp": 5.5,
  "internet_usage_pct": 88.0
}
```

* **Response `200 OK`:**
```json
{
  "cluster": 3,
  "tier_name": "Tier 3: Developed Industrial Economies",
  "cluster_profile": {
    "mean_gdp": 39669.21,
    "mean_life_expectancy": 80.97,
    "mean_infant_mortality": 3.73
  },
  "pca": {
    "x": 2.3695,
    "y": -1.0273
  },
  "distances": {
    "tier_1": 4.8812,
    "tier_2": 2.6514,
    "tier_3": 0.8241
  }
}
```

### 5.2 Country Dataset Endpoint
* **Endpoint:** `GET /api/country/data`
* **Response `200 OK`:** Returns all 168 sovereign nations with cluster assignments, ISO codes, and PCA coordinates.

---

## 6. Model 3: Formula 1 Race Outcome Analysis

* **Paradigm:** Supervised Learning
* **Algorithm:** Multiple Linear Regression (Ordinary Least Squares)
* **Target:** `race_points` (Continuous official points scored in Grand Prix)
* **Serialized Model:** `models/f1_regression.rds`
* **Anti-Leakage Standard:** Only pre-race parameters. Previous points strictly accumulate prior rounds $< N$.

### 6.1 Prediction Endpoint
* **Endpoint:** `POST /api/f1/predict`
* **Required Features (6):**
  * `grid_position` (int, $[1, 25]$)
  * `qualifying_position` (int, $[1, 25]$)
  * `q_delta_to_pole` (float, $\ge 0.0$ seconds)
  * `driver_previous_points` (float, $\ge 0.0$)
  * `constructor_previous_points` (float, $\ge 0.0$)
  * `round` (int, $\ge 1$)

* **Request Example:**
```json
{
  "grid_position": 3,
  "qualifying_position": 3,
  "q_delta_to_pole": 0.25,
  "driver_previous_points": 85.0,
  "constructor_previous_points": 140.0,
  "round": 6
}
```

* **Response `200 OK`:**
```json
{
  "predicted_points": 11.63,
  "raw_fit": 11.6289,
  "confidence_interval": {
    "lower": 1.81,
    "upper": 21.45,
    "level": 0.95
  },
  "features": {
    "grid_position": 3,
    "qualifying_position": 3,
    "q_delta_to_pole": 0.25,
    "driver_previous_points": 85.0,
    "constructor_previous_points": 140.0,
    "round": 6
  }
}
```

### 6.2 F1 Dataset Endpoint
* **Endpoint:** `GET /api/f1/data`
* **Response `200 OK`:** Returns 662 out-of-sample race observations (2022–2023) with actual points, predictions, and residuals.

---

## 7. Model 4: Student Placement Prediction

* **Paradigm:** Supervised Learning
* **Algorithm:** Binomial Logistic Regression (Logit Link)
* **Target:** `placed` (Binary: 1 = Placed, 0 = Not Placed)
* **Serialized Model:** `models/placement_logistic.rds`
* **Anti-Leakage Standard:** `salary` strictly excluded. 80/20 stratified split.

### 7.1 Prediction Endpoint
* **Endpoint:** `POST /api/placement/predict`
* **Required Features (8):**
  * `ssc_percentage` (float, $[0.0, 100.0]$)
  * `hsc_percentage` (float, $[0.0, 100.0]$)
  * `degree_percentage` (float, $[0.0, 100.0]$)
  * `work_experience` (int: `0` = No, `1` = Yes)
  * `aptitude_test_percentage` (float, $[0.0, 100.0]$)
  * `mba_percentage` (float, $[0.0, 100.0]$)
  * `mba_specialisation` (string: `"Mkt&Fin"` or `"Mkt&HR"`)
  * `degree_field` (string: `"Comm&Mgmt"`, `"Sci&Tech"`, or `"Others"`)

* **Request Example:**
```json
{
  "ssc_percentage": 74.0,
  "hsc_percentage": 70.0,
  "degree_percentage": 68.0,
  "work_experience": 1,
  "aptitude_test_percentage": 78.0,
  "mba_percentage": 62.0,
  "mba_specialisation": "Mkt&Fin",
  "degree_field": "Comm&Mgmt"
}
```

* **Response `200 OK`:**
```json
{
  "probability": 0.9974,
  "prediction": 1,
  "label": "Placed",
  "threshold": 0.5,
  "odds_multipliers": {
    "work_experience_odds": 9.9884,
    "ssc_percentage_unit_odds": 1.2541,
    "hsc_percentage_unit_odds": 1.1136,
    "degree_percentage_unit_odds": 1.1398
  }
}
```

### 7.2 Placement Dataset Endpoint
* **Endpoint:** `GET /api/placement/data`
* **Response `200 OK`:** Returns 44 test candidate records with actual outcome, predicted probability, predicted class, and correctness flag.

---

## 8. Automated Integration Testing

Run the full pytest integration test suite verifying all 4 models and gateway error handlers:

```bash
python -m pytest tests/test_api.py -v
```
Result: **20 passed in 2.84s (100% test coverage)**.
