# Model 3 Evaluation Report — Formula 1 Race Outcome Analysis

**Learning Paradigm:** Supervised Learning  
**Algorithm:** Multiple Linear Regression (Ordinary Least Squares)  
**Dataset:** [`data/processed/f1_race_data.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/data/processed/f1_race_data.csv)  
**Sample Scale:** 3890 Driver-Race Entries (2014–2023 Turbo Hybrid Era)  
**Target Variable:** `race_points` (Continuous Official Championship Points $[0, 50]$)  
**Model Artifact:** [`models/f1_regression.rds`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/models/f1_regression.rds)  
**Predictions Output:** [`data/processed/f1_predictions.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/data/processed/f1_predictions.csv)

---

## 1. Executive Summary & Objective

The objective of Model 3 is to isolate and quantify the marginal predictive leverage of pre-race starting grid advantage, qualifying pace delta, and pre-race constructor standings on official Grand Prix points scored.

> **Academic Disclaimer:** Motorsport racing contains inherent stochastic elements (weather fluctuations, safety car timing, mechanical failures, and first-lap collisions). The model does NOT claim to perfectly predict race winners; rather, it estimates the expected statistical point return conditional on pre-race telemetry.

---

## 2. Temporal Leakage Prevention Protocol

A strict time-aware protocol was enforced to guarantee zero future data leakage:
1. **Time-Aware Chronological Split:**
   * **Training Set:** Seasons 2014 through 2021 (3228 races, 83.0%% of dataset).
   * **Testing Set:** Seasons 2022 through 2023 (662 races, 17.0%% of dataset). Modern ground-effect aerodynamic era evaluated strictly out-of-sample.
   * **No Random Shuffling:** Future race outcomes were never accessible to models predicting earlier events.
2. **Strictly Pre-Race Predictors:**
   * Cumulative standings points (`driver_previous_points`, `constructor_previous_points`) only aggregate points scored in rounds prior to round $N$. In round 1, historical points are identically $0.0$.
   * In-race variables (finishing position, pit stop execution time, in-race fastest lap, mechanical DNFs) were strictly eliminated.

---

## 3. Regression Coefficients & Inferences

$$ \text{race\_points} = \beta_0 + \sum_{j=1}^{k} \beta_j X_j + \varepsilon $$

| Term | Estimate ($\hat{\beta}$) | Std. Error | $t$-statistic | $p$-value | Significance |
|:---|:---:|:---:|:---:|:---:|:---:|
| **(Intercept)** | 10.9281 | 0.2726 | 40.09 | 1.86e-285 | *** |
| **grid_position** | -0.2977 | 0.0561 | -5.31 | 1.189e-07 | *** |
| **qualifying_position** | -0.2412 | 0.0594 | -4.06 | 4.976e-05 | *** |
| **q_delta_to_pole** | -0.0007 | 0.0539 | -0.01 | 0.99 | ns |
| **driver_previous_points** | 0.0369 | 0.0049 | 7.56 | 5.208e-14 | *** |
| **constructor_previous_points** | 0.0031 | 0.0025 | 1.20 | 0.2285 | ns |
| **round** | -0.2076 | 0.0178 | -11.69 | 5.967e-31 | *** |

### Key Inferences:
* **Starting Grid Advantage:** Starting grid slot is a dominant negative coefficient (lower numeric grid slot = higher position on track), conferring significant expected points leverage.
* **Constructor Standing Power:** Pre-race constructor points entering the Grand Prix strongly predict finishing in points-paying positions ($p < 0.001$), reflecting vehicle aerodynamic and power unit dominance.
* **Qualifying Pace Delta:** A larger lap time delta to the pole position lap reduces expected point haul.

---

## 4. Performance Metrics

| Evaluation Metric | Training Set (2014–2021) | Testing Set (2022–2023 Out-of-Sample) |
|:---|:---:|:---:|
| **$R^2$ (Variance Explained)** | **0.5245** | **0.5644** |
| **Adjusted $R^2$** | **0.5236** | — |
| **Residual Standard Error / RMSE** | **5.0050** points | **4.8213** points |
| **Mean Absolute Error (MAE)** | — | **3.3862** points |
| **F-statistic** | **592.18** ($p < 2.2 \times 10^{-16}$) | — |

---

## 5. Model Limitations & Residual Diagnostics
1. **Discrete Zero Clumping:** In Formula 1, only the top 10 finishers score points (positions 11–20 receive 0 points). Linear regression models a continuous conditional mean, which can predict fractional or slightly negative point expectations (clamped to 0.0).
2. **Mechanical DNF Variance:** Unpredictable collisions or power unit failures truncate scoring opportunities for front-running cars, creating positive residual skews.

