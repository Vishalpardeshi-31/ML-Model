# Model 2 Evaluation Report — Country Development Analysis

**Learning Paradigm:** Unsupervised Learning  
**Algorithm:** Agglomerative Hierarchical Clustering  
**Dataset:** [`data/processed/country_development.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/data/processed/country_development.csv)  
**Sample Scale:** 168 Sovereign Nations (World Bank WDI 2020 Harmonized Census)  
**Source:** The World Bank Group & UN Inter-Agency Organizations  
**Model Artifact:** [`models/country_hierarchical.rds`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/models/country_hierarchical.rds)  
**Clustered Output:** [`data/processed/country_clustered.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/data/processed/country_clustered.csv)

---

## 1. Executive Summary & Objective

The objective of Model 2 is to construct an objective, data-driven developmental taxonomy of sovereign nation states using multi-dimensional socioeconomic indicators from the World Bank. The algorithm employs agglomerative hierarchical clustering with Ward’s minimum variance criterion on standardized indicator spaces.

---

## 2. Linkage Method Comparison & Justification

Three prominent agglomerative linkage criteria were rigorously evaluated:

| Linkage Method | Cophenetic Correlation | Silhouette Score ($K = 3$) | Rationale |
|:---|:---:|:---:|:---|
| **Ward.D2** | **0.6007** | **0.1904** | **Selected**: Minimizes intra-cluster variance, preventing chaining and forming compact, economically interpretable tiers. |
| **Complete** | 0.6412 | 0.1622 | Maximum pairwise distance; prone to sensitivity to extreme macroeconomic outliers. |
| **Average** | 0.7158 | 0.2236 | Compromise linkage; yields less distinct decision cut heights. |

---

## 3. Discovered Socioeconomic Developmental Tiers

The dendrogram was cut at $K = 3$, revealing three distinct developmental strata:

### Tier 1: Underdeveloped / High Humanitarian Need (N = 38 nations, 22.6%%)
* **Average GDP per Capita:** $1234.69 (Median: $952.44)
* **Average Life Expectancy:** 62.13 years (Median: 61.63)
* **Average Infant Mortality:** 47.48 deaths per 1,000 live births (Median: 46.35)
* **Average Internet Penetration:** 23.77%%
* **Profile:** Low industrial output, elevated infant mortality, and constrained healthcare resources.

### Tier 2: Developing / Emerging Market Economies (N = 99 nations, 58.9%%)
* **Average GDP per Capita:** $10865.19 (Median: $5561.19)
* **Average Life Expectancy:** 72.97 years (Median: 72.99)
* **Average Infant Mortality:** 14.35 deaths per 1,000 live births (Median: 12.20)
* **Average Internet Penetration:** 70.33%%
* **Profile:** Intermediate industrialization, expanding telecommunications infrastructure, and moderate public health metrics.

### Tier 3: Highly Developed Industrial Economies (N = 31 nations, 18.5%%)
* **Average GDP per Capita:** $39669.21 (Median: $41098.97)
* **Average Life Expectancy:** 80.97 years (Median: 81.36)
* **Average Infant Mortality:** 3.73 deaths per 1,000 live births (Median: 3.20)
* **Average Internet Penetration:** 89.78%%
* **Profile:** Advanced post-industrial economies with universal digital penetration, comprehensive healthcare expenditure, and high life expectancies.

---

## 4. Dimensionality Reduction & 2D Projection (PCA)

Principal Component Analysis was applied to project the 8-dimensional space onto orthogonal axes:
* **PC1 Variance Explained:** 50.65%% (captures overall economic development vs mortality)
* **PC2 Variance Explained:** 16.02%% (captures population scale and labor dynamics)
* **Cumulative 2D Variance:** 66.67%%

---

## 5. Algorithmic Diagnostics
* **Distance Metric:** Euclidean Metric
* **Linkage Function:** Ward’s Minimum Variance Criterion ($D_{Ward}$)
* **Cophenetic Correlation:** 0.6007

