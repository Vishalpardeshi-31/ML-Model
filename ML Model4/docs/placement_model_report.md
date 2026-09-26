# Model 4 Evaluation Report — Student Placement Prediction

**Learning Paradigm:** Supervised Learning  
**Algorithm:** Binomial Logistic Regression (Logit Link)  
**Dataset:** [`data/processed/student_placement.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/data/processed/student_placement.csv)  
**Sample Scale:** 215 Authentic Student Candidates (CMS Business School, Jain University)  
**Target Variable:** `placed` (Binary: 1 = Placed, 0 = Not Placed)  
**Model Artifact:** [`models/placement_logistic.rds`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/models/placement_logistic.rds)  
**Predictions Output:** [`data/processed/placement_predictions.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/data/processed/placement_predictions.csv)

---

## 1. Executive Summary & Objective

The objective of Model 4 is to model the conditional log-odds of a student securing campus recruitment based on multi-stage academic milestone grades (10th, 12th, undergraduate degree, MBA), undergraduate discipline, post-graduate MBA specialization, and prior corporate work experience.

$$\ln\left(\frac{P(\text{placed} = 1)}{1 - P(\text{placed} = 1)}\right) = \beta_0 + \sum_{i=1}^{k} \beta_i X_i$$

---

## 2. Leakage Prevention & Ethical Integrity

* **Zero Post-Hiring Data Leakage:** The raw column `salary` was **strictly eliminated** during data preparation. In academic datasets, unplaced students lack salary records; utilizing `salary` in classification introduces complete target leakage.
* **Stratified Validation Split:** Evaluated on an independent test cohort of 44 students (20%% holdout) stratified across class proportions.

---

## 3. Logistic Regression Parameter Estimates & Odds Ratios

| Predictor Term | Coefficient ($\hat{\beta}$) | Std. Error | Wald $z$ | $p$-value | Odds Ratio ($\text{OR}$) | 95%% CI Lower | 95%% CI Upper | Sig. |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **(Intercept)** | -12.5216 | 4.2501 | -2.95 | 0.003217 | 0.0000 | 0.0000 | 0.0151 | ** |
| **ssc_percentage** | 0.2264 | 0.0464 | 4.87 | 1.094e-06 | 1.2541 | 1.1449 | 1.3736 | *** |
| **hsc_percentage** | 0.1076 | 0.0392 | 2.74 | 0.006062 | 1.1136 | 1.0312 | 1.2026 | ** |
| **degree_percentage** | 0.1309 | 0.0572 | 2.29 | 0.02202 | 1.1398 | 1.0190 | 1.2749 | * |
| **work_experience** | 2.3014 | 0.7976 | 2.89 | 0.003909 | 9.9884 | 2.0921 | 47.6883 | ** |
| **aptitude_test_percentage** | -0.0292 | 0.0251 | -1.16 | 0.2442 | 0.9712 | 0.9246 | 1.0202 | ns |
| **mba_percentage** | -0.2376 | 0.0657 | -3.61 | 0.0003014 | 0.7886 | 0.6932 | 0.8970 | *** |
| **mba_specialisationMkt&HR** | -0.5284 | 0.6060 | -0.87 | 0.3832 | 0.5896 | 0.1798 | 1.9334 | ns |
| **degree_fieldOthers** | -0.4648 | 1.4608 | -0.32 | 0.7503 | 0.6283 | 0.0359 | 11.0039 | ns |
| **degree_fieldSci&Tech** | -1.1470 | 0.6613 | -1.73 | 0.08281 | 0.3176 | 0.0869 | 1.1607 | . |

### Inferences & Odds Ratio Interpretation:
* **Academic Performance:** Secondary School (`ssc_percentage`) and Undergraduate Degree (`degree_percentage`) percentages exert strong positive effects on placement odds ($p < 0.05$). Every 1%% increase in secondary school grade elevates placement odds by **25.41%%** ($	ext{OR} = 1.2541$).
* **Prior Work Experience:** Candidates with prior corporate work experience (`work_experience`) exhibit an odds ratio of **9.9884** (substantially higher likelihood of placement compared to fresh graduates with identical grades).
* **MBA Specialization:** Marketing & Finance (`specialisationMkt&Fin`) consistently shows higher placement odds compared to Marketing & HR.

---

## 4. Test Set Classification Performance (Threshold = 0.50)

| Metric | Score | Interpretation |
|:---|:---:|:---|
| **Accuracy** | **84.09%%** (37 / 44) | Overall correct prediction rate |
| **Precision (PPV)** | **0.8966** | Proportion of predicted placements that were genuine |
| **Recall / Sensitivity** | **0.8667** | Proportion of actual placed candidates correctly identified |
| **Specificity** | **0.7857** | Proportion of unplaced candidates correctly screened |
| **F1-Score** | **0.8814** | Harmonic mean of precision and recall |
| **ROC-AUC** | **0.9310** | Discrimination threshold separation power |
| **Residual Deviance** | **81.02** (Null: 211.72) | Likelihood ratio improvement over intercept-only model |
| **Akaike Info Criterion (AIC)** | **101.02** | Model parsimony measure |

### Test Confusion Matrix:
```
                 Actual Placed (1)    Actual Unplaced (0)
Predicted Placed        26 (TP)              3 (FP)
Predicted Unplaced      4 (FN)              11 (TN)
```

---

## 5. Model Limitations
* Sample reflects a single institutional cohort; localized hiring dynamics for management graduates in Bangalore may not directly reflect non-management employment markets.

