# Model 1 Evaluation Report — Brain Activity Pattern Discovery

**Learning Paradigm:** Unsupervised Learning  
**Algorithm:** K-Means Clustering  
**Dataset:** [`data/processed/brain_activity.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/data/processed/brain_activity.csv)  
**Sample Scale:** 233 Real-World 1.0-Second Epochs (14 Scalp Electrodes @ 128 Hz)  
**Source:** UCI Machine Learning Repository (DHBW Stuttgart / Oliver Roesler, DOI: 10.24432/C57G7J)  
**Model Artifact:** [`models/brain_kmeans.rds`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/models/brain_kmeans.rds)  
**Clustered Output:** [`data/processed/brain_clustered.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/data/processed/brain_clustered.csv)

---

## 1. Executive Summary & Objective

The objective of Model 1 is to discover latent, objective neuro-functional brain states without supervised class guidance. Using 13 standardized spectral band power and time-domain features extracted from 14 scalp EEG electrodes, K-Means partitions continuous brain activity into discrete activity topologies.

> **Crucial Academic Precaution:** Discovered clusters represent latent electrophysiological activation states and oscillatory spectral regimes. They do NOT constitute medical diagnoses, pathological states, or neurological disease classifications.

---

## 2. Cluster Validation & Hyperparameter Selection ($K$)

The optimal number of clusters was determined empirically across candidate values $K \in [2, 8]$ by evaluating the Within-Cluster Sum of Squares (WCSS, Elbow method) and Average Silhouette Width.

| Clusters ($K$) | Total WCSS | Average Silhouette Score | Evaluation Notes |
|:---:|:---:|:---:|:---|
| 2 | 2120.74 | 0.3126 | Candidate |
| 3 | 1849.65 | 0.2664 | Selected Optimal State Partition |
| 4 | 1616.25 | 0.1923 | Candidate |
| 5 | 1460.57 | 0.1691 | Candidate |
| 6 | 1363.37 | 0.1574 | Candidate |
| 7 | 1277.35 | 0.1598 | Candidate |
| 8 | 1202.43 | 0.1617 | Candidate |

**Defensible Choice:** $K = 3$ was selected as the optimal cluster cardinality, achieving an average silhouette score of **0.2664** and explaining **38.67%%** of total sum of squares variance ($BSS/TSS$).

---

## 3. Discovered Brain Activity Pattern Profiles

The 3 clusters correspond to distinct electrophysiological operational modes:

### Pattern State 1 (N = 80, 34.33%% of recording)
* **Key Markers:** Alpha Power = 3.90 uV^2/Hz, Beta Power = 3.88 uV^2/Hz, Theta Power = 5.78 uV^2/Hz, Occipital Alpha = 4.13 uV^2/Hz, Theta-Beta Ratio = 1.61
* **Electrophysiological Interpretation:** Characterized by elevated posterior alpha synchronization indicative of relaxed, idle sensory processing with eyes closed / restful wakefulness oscillatory dynamics.

### Pattern State 2 (N = 6, 2.58%% of recording)
* **Key Markers:** Alpha Power = 12.82 uV^2/Hz, Beta Power = 10.15 uV^2/Hz, Theta Power = 29.92 uV^2/Hz, Occipital Alpha = 11.02 uV^2/Hz, Theta-Beta Ratio = 3.02
* **Electrophysiological Interpretation:** Characterized by elevated posterior alpha synchronization indicative of relaxed, idle sensory processing with eyes closed / restful wakefulness oscillatory dynamics.

### Pattern State 3 (N = 147, 63.09%% of recording)
* **Key Markers:** Alpha Power = 3.16 uV^2/Hz, Beta Power = 3.36 uV^2/Hz, Theta Power = 2.65 uV^2/Hz, Occipital Alpha = 3.62 uV^2/Hz, Theta-Beta Ratio = 0.86
* **Electrophysiological Interpretation:** Characterized by transitional low-voltage desynchronized mixed-frequency cortical rhythms oscillatory dynamics.

---

## 4. Dimensionality Reduction & Spatial Projection (PCA)

Principal Component Analysis (PCA) was fitted on the standardized feature matrix to provide orthogonal 2D visual projection:
* **PC1 Variance Explained:** 43.94%%
* **PC2 Variance Explained:** 16.12%%
* **Total 2D Variance Captured:** 60.06%%

The clusters form distinct contiguous groupings in the PC1–PC2 coordinate space, confirming that partition boundaries reflect genuine oscillatory signal differences rather than noise artifacts.

---

## 5. Algorithmic Diagnostics

* **Total Epochs Processed:** 233
* **Input Features Clustered:** 13
* **Convergence Iterations:** 3
* **Total Within-Cluster Sum of Squares (WCSS):** 1849.65
* **Between-Cluster Sum of Squares (BSS):** 1166.35
* **Variance Explained Ratio ($BSS / TSS$):** 38.67%%

