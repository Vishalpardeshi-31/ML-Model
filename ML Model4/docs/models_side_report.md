# ML Model 4 — Comprehensive Models Side Report
### Technical Performance, Algorithmic Specifications & Evaluation Metrics

**Project:** ML Model 4 — Production-Quality Academic Machine Learning Platform  
**System Status:** Phase 3 Complete (Models Trained, Evaluated & Serialized)  
**Strict Data Standard:** 100% Verified Real-World Data • Zero Synthetic / Fabricated Records

---

## 1. Executive Performance Dashboard

| World / Research Module | Learning Paradigm | Machine Learning Algorithm | Primary Evaluation Metrics | Final Performance Score | Dataset Scale & Split | Status |
|:---|:---|:---|:---|:---|:---|:---:|
| **01. Brain Activity Pattern Discovery** | **Unsupervised** | **K-Means Clustering** | • Average Silhouette Width<br>• Within-Cluster Sum of Squares (WCSS)<br>• 2D PCA Variance Explained | • **Silhouette: 0.2664**<br>• **WCSS: 1849.65** ($K = 3$)<br>• **PCA Variance: 60.06%** | 233 Real-World Epochs<br>(14 Scalp Electrodes @ 128 Hz) | **Trained & Saved**<br>[`models/brain_kmeans.rds`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/models/brain_kmeans.rds) |
| **02. Country Development Analysis** | **Unsupervised** | **Agglomerative Hierarchical Clustering** | • Cophenetic Correlation<br>• Average Silhouette ($K = 3$)<br>• 2D PCA Variance Explained | • **Cophenetic Corr: 0.6007**<br>• **Silhouette: 0.1904**<br>• **PCA Variance: 66.67%** | 168 Sovereign Nations<br>(8 World Bank WDI Indicators) | **Trained & Saved**<br>[`models/country_hierarchical.rds`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/models/country_hierarchical.rds) |
| **03. Formula 1 Race Outcome Analysis** | **Supervised** | **Multiple Linear Regression** | • Out-of-Sample $R^2$<br>• Root Mean Squared Error (RMSE)<br>• Mean Absolute Error (MAE) | • **Test $R^2$: 0.5644** (56.4% Var)<br>• **Test RMSE: 4.8213 points**<br>• **Test MAE: 3.3862 points** | 3,890 Driver-Races<br>Train: 3,228 (83%) [2014-21]<br>Test: 662 (17%) [2022-23] | **Trained & Saved**<br>[`models/f1_regression.rds`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/models/f1_regression.rds) |
| **04. Student Placement Prediction** | **Supervised** | **Binomial Logistic Regression** | • Out-of-Sample Accuracy<br>• Precision & Recall<br>• Area Under ROC Curve (AUC) | • **Test Accuracy: 84.09%**<br>• **Precision: 89.66%**<br>• **Recall: 86.67%**<br>• **ROC-AUC: 0.9310** | 215 Student Candidates<br>Train: 171 (80%)<br>Test: 44 (20% Stratified) | **Trained & Saved**<br>[`models/placement_logistic.rds`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/models/placement_logistic.rds) |

---

## 2. Model 1 Deep-Dive: Brain Activity Pattern Discovery

### 2.1 Algorithmic Architecture
* **Algorithm:** K-Means Clustering (`stats::kmeans`)
* **Learning Paradigm:** Unsupervised Pattern Discovery
* **Distance Metric:** Standardized Euclidean Distance on $Z$-score normalized features
* **Convergence:** Converged in 3 iterations with 50 random restarts (`nstart = 50`)

### 2.2 Input Feature Space (13 Numerical Features)
1. `delta_power`: Slow-wave oscillatory energy (0.5–4.0 Hz)
2. `theta_power`: Drowsiness / memory encoding rhythm (4.0–8.0 Hz)
3. `alpha_power`: Posterior dominant relaxation rhythm (8.0–13.0 Hz)
4. `beta_power`: Active cognitive focus / alert engagement (13.0–30.0 Hz)
5. `gamma_power`: High-frequency cross-modal binding (30.0–45.0 Hz)
6. `alpha_relative`: Normalized spectral ratio $\text{Alpha} / \text{Total Power}$
7. `beta_relative`: Normalized spectral ratio $\text{Beta} / \text{Total Power}$
8. `theta_beta_ratio`: Cognitive arousal marker ($\text{Theta} / \text{Beta}$)
9. `occipital_alpha`: Bilateral primary visual cortex alpha power ($O1, O2$)
10. `frontal_asymmetry`: Prefrontal hemispheric emotional index $(F4 - F3) / (F4 + F3)$
11. `mean_amplitude`: Time-domain baseline potential ($\mu\text{V}$)
12. `signal_variance`: Time-domain signal energy / amplitude dispersion
13. `spectral_entropy`: Shannon information entropy of normalized power spectral density

### 2.3 Hyperparameter Selection ($K$)
The optimal cluster count was determined empirically across candidate values $K \in [2, 8]$ using both the Elbow Method (WCSS) and Average Silhouette Width:

| Candidate Clusters ($K$) | Total WCSS | Average Silhouette Score | Mathematical Interpretation |
|:---:|:---:|:---:|:---|
| $K = 2$ | 2120.74 | 0.3126 | Degenerate binary boundary (isolates a tiny 2.5% outlier burst) |
| **$K = 3$ (Selected)** | **1849.65** | **0.2664** | **Optimal multi-state partition** (meaningful functional grouping) |
| $K = 4$ | 1616.25 | 0.1923 | Sub-segmentation of the active beta cluster |
| $K = 5$ | 1460.57 | 0.1691 | Diminishing returns on variance explained |
| $K = 6$ | 1363.37 | 0.1574 | Silhouette deterioration |
| $K = 7$ | 1277.35 | 0.1598 | Over-segmentation |
| $K = 8$ | 1202.43 | 0.1617 | Cluster fragmentation |

### 2.4 Discovered Cluster Profiles & Electrophysiological Interpretations
* **Cluster 1: Relaxed Wakefulness / Idle Posterior Alpha State**
  * **Size:** 80 epochs (**34.33%** of recording)
  * **Key Features:** High `occipital_alpha` (mean: 4.12 $\mu\text{V}^2/\text{Hz}$), high `alpha_power` (mean: 3.51), low `theta_beta_ratio` (0.88).
  * **Interpretation:** Characterized by elevated posterior occipital alpha synchronization, corresponding to relaxed wakefulness and sensory idle states (eyes closed).
* **Cluster 2: High-Amplitude Slow-Wave Transient State**
  * **Size:** 6 epochs (**2.58%** of recording)
  * **Key Features:** Extreme `delta_power` (mean: 4.29 $\mu\text{V}^2/\text{Hz}$), very high `signal_variance` (mean: 1104.2).
  * **Interpretation:** Transient physiological high-voltage delta bursts or deep synchronized state shifts.
* **Cluster 3: Alert Cognitive Engagement / Desynchronized State**
  * **Size:** 147 epochs (**63.09%** of recording)
  * **Key Features:** Elevated `beta_power` (mean: 3.28 $\mu\text{V}^2/\text{Hz}$), suppressed occipital alpha (mean: 1.34), high `spectral_entropy` (mean: 3.82).
  * **Interpretation:** Characterized by low-voltage fast beta rhythms, indicating active cognitive attention, alertness, and cortical desynchronization (eyes open / mental engagement).

> **Academic Precaution:** Discovered clusters represent latent electrophysiological activation states and oscillatory spectral regimes. They do **NOT** represent medical diagnoses or pathological classifications.

---

## 3. Model 2 Deep-Dive: Country Development Analysis

### 3.1 Algorithmic Architecture
* **Algorithm:** Agglomerative Hierarchical Clustering (`stats::hclust`)
* **Learning Paradigm:** Unsupervised Taxonomic Clustering
* **Linkage Method:** **Ward.D2** (Minimum Variance Criterion)
* **Distance Metric:** Euclidean Metric on $Z$-score standardized indicators

### 3.2 Linkage Comparison & Justification
Three prominent agglomerative linkage algorithms were compared on the 168 sovereign nations:

| Linkage Algorithm | Cophenetic Correlation | Silhouette Score ($K = 3$) | Empirical Decision Rationale |
|:---|:---:|:---:|:---|
| **Ward.D2 (Selected)** | **0.6007** | **0.1904** | **Selected**: Minimizes within-cluster variance sum-of-squares; creates well-balanced, spherical, non-chaining developmental tiers. |
| **Complete Linkage** | 0.6412 | 0.1622 | Maximum pairwise distance; excessively sensitive to macroeconomic outliers (e.g. Monaco, Luxembourg). |
| **Average Linkage** | 0.7158 | 0.2236 | UPGMA distance; produces loose boundary cuts and highly unbalanced tier sizes. |

### 3.3 Discovered Socioeconomic Developmental Tiers ($K = 3$)

```
                        Global Sovereign Nations (N = 168)
                                       │
                 ┌─────────────────────┴─────────────────────┐
                 │                                           │
         Tier 1: Underdeveloped                      Higher Development
          (N = 38, 22.62%)                                   │
                                            ┌────────────────┴────────────────┐
                                            │                                 │
                                   Tier 2: Developing                Tier 3: Developed
                                    (N = 99, 58.93%)                 (N = 31, 18.45%)
```

#### Detailed Cluster Profiles:
1. **Tier 1: Underdeveloped / High Humanitarian Need (38 Nations, 22.62%)**
   * **GDP per Capita:** Mean = **$1,489** | Median = **$982** (Min: $253, Max: $4,850)
   * **Life Expectancy:** Mean = **61.4 years** | Median = **61.8 years** (Min: 53.1)
   * **Infant Mortality:** Mean = **47.3 deaths/1,000** | Median = **45.2 deaths/1,000**
   * **Internet Usage:** Mean = **27.6%** | Median = **24.5%**
   * **Public Healthcare Spend:** Mean = **5.82% of GDP**
2. **Tier 2: Developing / Emerging Market Economies (99 Nations, 58.93%)**
   * **GDP per Capita:** Mean = **$8,898** | Median = **$5,353**
   * **Life Expectancy:** Mean = **73.1 years** | Median = **73.4 years**
   * **Infant Mortality:** Mean = **13.6 deaths/1,000** | Median = **12.6 deaths/1,000**
   * **Internet Usage:** Mean = **69.8%** | Median = **72.1%**
   * **Public Healthcare Spend:** Mean = **6.91% of GDP**
3. **Tier 3: Highly Developed Industrial Economies (31 Nations, 18.45%)**
   * **GDP per Capita:** Mean = **$45,671** | Median = **$42,600** (Max: $116,860)
   * **Life Expectancy:** Mean = **81.4 years** | Median = **82.2 years** (Max: 84.6)
   * **Infant Mortality:** Mean = **3.0 deaths/1,000** | Median = **2.9 deaths/1,000** (Min: 1.8)
   * **Internet Usage:** Mean = **86.7%** | Median = **88.2%** (Max: 100%)
   * **Public Healthcare Spend:** Mean = **8.73% of GDP**

---

## 4. Model 3 Deep-Dive: Formula 1 Race Outcome Analysis

### 4.1 Algorithmic Architecture
* **Algorithm:** Multiple Linear Regression (`stats::lm`, Ordinary Least Squares)
* **Learning Paradigm:** Supervised Predictive Regression
* **Target Variable:** `race_points` (Continuous official Grand Prix championship points awarded)
* **Temporal Scope:** Modern Turbo Hybrid V6 Era (Seasons 2014–2023, 198 Grands Prix)

### 4.2 Strict Temporal Anti-Leakage Protocol
1. **Time-Aware Chronological Partitioning:**
   * **Training Partition:** Seasons 2014 through 2021 (3,228 observations, **83.0%** of data).
   * **Testing Partition:** Seasons 2022 through 2023 (662 observations, **17.0%** of data).
   * Evaluated strictly out-of-sample across the new 2022 ground-effect regulation era.
2. **Strictly Pre-Race Predictors:**
   * `driver_previous_points`: Cumulative points scored by the driver strictly in rounds $< \text{current round}$. In round 1, previous points are identically $0.0$.
   * `constructor_previous_points`: Cumulative points scored by the constructor strictly in rounds $< \text{current round}$.
   * Post-race and in-race variables (finishing position, pit stop execution time, in-race fastest lap, mechanical DNFs) were **strictly eliminated**.

### 4.3 Regression Parameter Estimates & Inferences

$$\text{race\_points} = 10.928 - 0.298(\text{grid}) - 0.241(\text{quali\_pos}) - 0.001(\text{q\_delta}) + 0.037(\text{driver\_prev\_pts}) + 0.003(\text{cons\_prev\_pts}) - 0.208(\text{round})$$

| Model Term | Coefficient ($\hat{\beta}$) | Standard Error | $t$-statistic | $p$-value | Significance |
|:---|:---:|:---:|:---:|:---:|:---:|
| **(Intercept)** | 10.9281 | 0.2726 | 40.09 | $< 10^{-280}$ | *** |
| **`grid_position`** | -0.2977 | 0.0561 | -5.31 | $1.19 \times 10^{-7}$ | *** |
| **`qualifying_position`** | -0.2412 | 0.0594 | -4.06 | $4.98 \times 10^{-5}$ | *** |
| **`q_delta_to_pole`** | -0.0007 | 0.0539 | -0.01 | $0.990$ | ns |
| **`driver_previous_points`** | 0.0369 | 0.0049 | 7.56 | $5.21 \times 10^{-14}$ | *** |
| **`constructor_previous_points`** | 0.0031 | 0.0025 | 1.20 | $0.228$ | ns |
| **`round`** | -0.2076 | 0.0178 | -11.69 | $5.97 \times 10^{-31}$ | *** |

### 4.4 Out-of-Sample Performance Comparison

| Metric | Training Set (2014–2021) | Testing Set (2022–2023 Out-of-Sample) | Technical Interpretation |
|:---|:---:|:---:|:---|
| **$R^2$ (Variance Explained)** | **0.5245** | **0.5644** | Explains 56.4% of points variance on unseen future regulation seasons. |
| **Adjusted $R^2$** | **0.5236** | — | Penalized for degrees of freedom. |
| **RMSE (Error Magnitude)** | 5.0050 points | **4.8213 points** | Average prediction deviation from actual race points. |
| **MAE (Mean Absolute Error)** | — | **3.3862 points** | Average absolute point error per driver. |
| **F-statistic** | **592.18** ($p < 10^{-16}$) | — | Overall regression equation is highly statistically significant. |

---

## 5. Model 4 Deep-Dive: Student Placement Prediction

### 5.1 Algorithmic Architecture
* **Algorithm:** Binomial Logistic Regression (`stats::glm`, family = binomial, logit link)
* **Learning Paradigm:** Supervised Probabilistic Classification
* **Target Variable:** `placed` (Binary: 1 = Placed [68.8%], 0 = Not Placed [31.2%])
* **Source:** CMS Business School, Jain University (215 authentic student records)
* **Anti-Leakage Enforcement:** The raw feature `salary` was **strictly eliminated**. Including salary would introduce 100% artificial target leakage.

### 5.2 Logistic Regression Parameters & Odds Ratios

$$\ln\left(\frac{p}{1 - p}\right) = -12.52 + 0.226(\text{ssc\_p}) + 0.108(\text{hsc\_p}) + 0.131(\text{degree\_p}) + 2.301(\text{work\_exp}) - 0.029(\text{etest\_p}) - 0.238(\text{mba\_p}) - 0.528(\text{spec\_HR}) - 1.147(\text{field\_SciTech})$$

| Predictor Term | Coefficient ($\hat{\beta}$) | Standard Error | Wald $z$ | $p$-value | Odds Ratio ($\text{OR}$) | 95% CI Lower | 95% CI Upper | Sig. |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **(Intercept)** | -12.5216 | 4.2501 | -2.95 | $0.0032$ | 0.0000 | 0.0000 | 0.0151 | ** |
| **`ssc_percentage`** | 0.2264 | 0.0464 | 4.87 | $1.09 \times 10^{-6}$ | **1.2541** | 1.1449 | 1.3736 | *** |
| **`hsc_percentage`** | 0.1076 | 0.0392 | 2.74 | $0.0061$ | **1.1136** | 1.0312 | 1.2026 | ** |
| **`degree_percentage`** | 0.1309 | 0.0572 | 2.29 | $0.0220$ | **1.1398** | 1.0190 | 1.2749 | * |
| **`work_experience`** | 2.3014 | 0.7976 | 2.89 | $0.0039$ | **9.9884** | 2.0921 | 47.6883 | ** |
| **`aptitude_test_percentage`** | -0.0292 | 0.0251 | -1.16 | $0.2442$ | 0.9712 | 0.9246 | 1.0202 | ns |
| **`mba_percentage`** | -0.2376 | 0.0657 | -3.61 | $0.0003$ | **0.7886** | 0.6932 | 0.8970 | *** |
| **`mba_spec (Mkt&HR)`** | -0.5284 | 0.6060 | -0.87 | $0.3832$ | 0.5896 | 0.1798 | 1.9334 | ns |
| **`degree_field (Sci&Tech)`** | -1.1470 | 0.6613 | -1.73 | $0.0828$ | 0.3176 | 0.0869 | 1.1607 | . |

### 5.3 Out-of-Sample Test Evaluation (N = 44 Candidates, Threshold = 0.50)

```
                       Actual Placed (1)      Actual Unplaced (0)
Predicted Placed:              26 (TP)                 3 (FP)
Predicted Unplaced:             4 (FN)                11 (TN)
```

* **Test Accuracy:** **84.09%** (37 out of 44 correctly predicted)
* **Precision (Positive Predictive Value):** **89.66%** (26 / 29)
* **Recall (Sensitivity):** **86.67%** (26 / 30)
* **Specificity (True Negative Rate):** **78.57%** (11 / 14)
* **F1-Score:** **0.8814**
* **Area Under ROC Curve (ROC-AUC):** **0.9310** (Strong threshold discrimination separation)
* **Residual Deviance:** 81.02 on 161 DF (Null: 211.72, $p < 10^{-20}$)
* **Akaike Information Criterion (AIC):** 101.02

---

## 6. Model Artifacts & Cross-Model Integrity Audit

Every trained model and prediction artifact has been verified and stored on disk:

```
models/
├── brain_kmeans.rds             [2.3 KB]  K-Means object (K=3, cluster profiles, scale attributes, PCA)
├── country_hierarchical.rds     [4.0 KB]  Ward.D2 hclust object (K=3 tiers, cophenetic distance, PCA)
├── f1_regression.rds            [216 KB]  Multiple Linear Regression OLS object (train/test temporal metrics)
└── placement_logistic.rds       [31.8 KB] Binomial GLM object (odds ratios, ROC-AUC, confusion matrix)

data/processed/
├── brain_clustered.csv          [233 rows x 18 cols]  Includes cluster assignments & PCA1, PCA2
├── country_clustered.csv        [168 rows x 14 cols]  Includes socioeconomic tiers & PCA1, PCA2
├── f1_predictions.csv           [662 rows x 9 cols]   Out-of-sample 2022-2023 predictions with residuals
└── placement_predictions.csv    [44 rows x 11 cols]   Independent test predictions, probabilities, accuracy flags
```

This side report serves as the complete technical reference for the ML Model 4 computational engine.
