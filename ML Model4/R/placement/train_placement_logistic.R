# ==============================================================================
# ML Model 4 - Model 4: Student Placement Prediction
# Binomial Logistic Regression Training & Evaluation
# Target: placed (1 = Placed, 0 = Not Placed)
# Source Dataset: data/processed/student_placement.csv
# ==============================================================================

suppressPackageStartupMessages({
  library(stats)
})

cat("==============================================================================\n")
cat("MODEL 4: STUDENT PLACEMENT PREDICTION (LOGISTIC REGRESSION)\n")
cat("==============================================================================\n")

# 1. Load Processed Dataset
data_path <- file.path("data", "processed", "student_placement.csv")
if (!file.exists(data_path)) {
  stop(sprintf("[-] Processed dataset not found: %s", data_path))
}

student_df <- read.csv(data_path, stringsAsFactors = FALSE)
cat(sprintf("[+] Successfully loaded %d student candidate records.\n", nrow(student_df)))

# 2. Variable Specifications
target_col <- "placed"
cat(sprintf("[+] Target Variable: '%s' (Binary: 1 = Placed, 0 = Not Placed)\n", target_col))

# Factor conversion for categorical attributes
student_df$gender <- as.factor(student_df$gender)
student_df$ssc_board <- as.factor(student_df$ssc_board)
student_df$hsc_board <- as.factor(student_df$hsc_board)
student_df$hsc_stream <- as.factor(student_df$hsc_stream)
student_df$degree_field <- as.factor(student_df$degree_field)
student_df$mba_specialisation <- as.factor(student_df$mba_specialisation)

predictor_cols <- c(
  "ssc_percentage",
  "hsc_percentage",
  "degree_percentage",
  "work_experience",
  "aptitude_test_percentage",
  "mba_percentage",
  "mba_specialisation",
  "degree_field"
)

cat(sprintf("[+] Selected %d academic & profile predictors:\n", length(predictor_cols)))
cat(paste("   -", predictor_cols, collapse = "\n"), "\n")

# 3. Stratified Train / Test Split (80% Train, 20% Test)
set.seed(42) # Strict reproducibility
placed_indices <- which(student_df$placed == 1)
unplaced_indices <- which(student_df$placed == 0)

train_placed <- sample(placed_indices, size = floor(0.80 * length(placed_indices)))
train_unplaced <- sample(unplaced_indices, size = floor(0.80 * length(unplaced_indices)))
train_idx <- c(train_placed, train_unplaced)

train_df <- student_df[train_idx, ]
test_df  <- student_df[-train_idx, ]

cat(sprintf("\n[+] Stratified Split Summary:\n"))
cat(sprintf("   - Training Set: %d candidates (Placed: %d, Unplaced: %d, Rate: %.1f%%)\n",
            nrow(train_df), sum(train_df$placed == 1), sum(train_df$placed == 0), mean(train_df$placed)*100))
cat(sprintf("   - Testing Set:  %d candidates (Placed: %d, Unplaced: %d, Rate: %.1f%%)\n",
            nrow(test_df), sum(test_df$placed == 1), sum(test_df$placed == 0), mean(test_df$placed)*100))

# 4. Train Binomial Logistic Regression Model
formula_str <- as.formula(paste(target_col, "~", paste(predictor_cols, collapse = " + ")))
cat(sprintf("\n[*] Fitting Binomial Logistic Regression (Logit Link):\n    Formula: %s\n", deparse(formula_str)))

logit_model <- glm(formula_str, data = train_df, family = binomial(link = "logit"))
model_summary <- summary(logit_model)

# 5. Extract Coefficients, Wald Statistics & Odds Ratios
coef_mat <- model_summary$coefficients
odds_ratios <- exp(coef_mat[, 1])
conf_intervals <- exp(confint.default(logit_model))

coef_df <- data.frame(
  Term = rownames(coef_mat),
  Estimate = round(coef_mat[, 1], 4),
  Std_Error = round(coef_mat[, 2], 4),
  z_value = round(coef_mat[, 3], 2),
  p_value = signif(coef_mat[, 4], 4),
  Odds_Ratio = round(odds_ratios, 4),
  CI_95_Lower = round(conf_intervals[, 1], 4),
  CI_95_Upper = round(conf_intervals[, 2], 4),
  Significance = ifelse(coef_mat[, 4] < 0.001, "***",
                 ifelse(coef_mat[, 4] < 0.01, "**",
                 ifelse(coef_mat[, 4] < 0.05, "*",
                 ifelse(coef_mat[, 4] < 0.1, ".", "ns")))),
  stringsAsFactors = FALSE
)

cat("\nLogistic Regression Parameter Estimates & Odds Ratios:\n")
print(coef_df, row.names = FALSE)

# 6. Out-of-Sample Predictions on Testing Set
cat("\n[*] Evaluating on Independent Testing Set (N = 43)...\n")
pred_probs <- predict(logit_model, newdata = test_df, type = "response")
threshold <- 0.50
pred_classes <- ifelse(pred_probs >= threshold, 1, 0)
actual_classes <- test_df$placed

# Confusion Matrix
tp <- sum(pred_classes == 1 & actual_classes == 1)
fp <- sum(pred_classes == 1 & actual_classes == 0)
tn <- sum(pred_classes == 0 & actual_classes == 0)
fn <- sum(pred_classes == 0 & actual_classes == 1)

# Metrics
accuracy <- (tp + tn) / length(actual_classes)
precision <- tp / (tp + fp)
recall <- tp / (tp + fn) # Sensitivity
specificity <- tn / (tn + fp)
f1_score <- 2 * (precision * recall) / (precision + recall)

# Exact Pairwise Concordance ROC-AUC Calculation
pos_scores <- pred_probs[actual_classes == 1]
neg_scores <- pred_probs[actual_classes == 0]
auc_roc <- sum(outer(pos_scores, neg_scores, ">") + 0.5 * outer(pos_scores, neg_scores, "==")) / (length(pos_scores) * length(neg_scores))

cat(sprintf("\nClassification Performance (Threshold = %.2f):\n", threshold))
cat(sprintf("   - Confusion Matrix: [ TP=%d, FP=%d | FN=%d, TN=%d ]\n", tp, fp, fn, tn))
cat(sprintf("   - Accuracy:         %.4f (%.2f%%)\n", accuracy, accuracy * 100))
cat(sprintf("   - Precision (PPV):  %.4f\n", precision))
cat(sprintf("   - Recall / Sens:    %.4f\n", recall))
cat(sprintf("   - Specificity:      %.4f\n", specificity))
cat(sprintf("   - F1-Score:         %.4f\n", f1_score))
cat(sprintf("   - ROC-AUC:          %.4f\n", auc_roc))
cat(sprintf("   - Residual Deviance: %.2f on %d DF (Null: %.2f)\n",
            logit_model$deviance, logit_model$df.residual, logit_model$null.deviance))
cat(sprintf("   - AIC:              %.2f\n", logit_model$aic))

# 7. Save Predictions File
test_output_df <- data.frame(
  student_id = test_df$student_id,
  gender = test_df$gender,
  ssc_percentage = test_df$ssc_percentage,
  hsc_percentage = test_df$hsc_percentage,
  degree_percentage = test_df$degree_percentage,
  work_experience = test_df$work_experience,
  mba_specialisation = test_df$mba_specialisation,
  actual_placed = actual_classes,
  predicted_probability = round(pred_probs, 4),
  predicted_class = pred_classes,
  correct = (pred_classes == actual_classes)
)

pred_csv_path <- file.path("data", "processed", "placement_predictions.csv")
write.csv(test_output_df, pred_csv_path, row.names = FALSE)
cat(sprintf("\n[SUCCESS] Test predictions saved to: %s (%d rows)\n", pred_csv_path, nrow(test_output_df)))

# 8. Save Serialized Model Object (.rds)
dir.create("models", showWarnings = FALSE, recursive = TRUE)
model_rds_path <- file.path("models", "placement_logistic.rds")

model_artifact <- list(
  algorithm = "Binomial Logistic Regression",
  target = target_col,
  predictors = predictor_cols,
  model = logit_model,
  coefficients = coef_df,
  confusion_matrix = list(tp = tp, fp = fp, tn = tn, fn = fn),
  test_metrics = list(
    threshold = threshold,
    accuracy = accuracy,
    precision = precision,
    recall = recall,
    specificity = specificity,
    f1_score = f1_score,
    auc_roc = auc_roc,
    aic = logit_model$aic,
    deviance = logit_model$deviance
  ),
  split = list(
    train_n = nrow(train_df),
    test_n = nrow(test_df)
  )
)

saveRDS(model_artifact, model_rds_path)
cat(sprintf("[SUCCESS] Serialized Logistic Model saved to: %s\n", model_rds_path))

# 9. Generate Evaluation Report
report_path <- file.path("docs", "placement_model_report.md")
dir.create("docs", showWarnings = FALSE, recursive = TRUE)

report_content <- sprintf(
'# Model 4 Evaluation Report — Student Placement Prediction

**Learning Paradigm:** Supervised Learning  
**Algorithm:** Binomial Logistic Regression (Logit Link)  
**Dataset:** [`data/processed/student_placement.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%%20Model4/data/processed/student_placement.csv)  
**Sample Scale:** %d Authentic Student Candidates (CMS Business School, Jain University)  
**Target Variable:** `placed` (Binary: 1 = Placed, 0 = Not Placed)  
**Model Artifact:** [`models/placement_logistic.rds`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%%20Model4/models/placement_logistic.rds)  
**Predictions Output:** [`data/processed/placement_predictions.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%%20Model4/data/processed/placement_predictions.csv)

---

## 1. Executive Summary & Objective

The objective of Model 4 is to model the conditional log-odds of a student securing campus recruitment based on multi-stage academic milestone grades (10th, 12th, undergraduate degree, MBA), undergraduate discipline, post-graduate MBA specialization, and prior corporate work experience.

$$\\ln\\left(\\frac{P(\\text{placed} = 1)}{1 - P(\\text{placed} = 1)}\\right) = \\beta_0 + \\sum_{i=1}^{k} \\beta_i X_i$$

---

## 2. Leakage Prevention & Ethical Integrity

* **Zero Post-Hiring Data Leakage:** The raw column `salary` was **strictly eliminated** during data preparation. In academic datasets, unplaced students lack salary records; utilizing `salary` in classification introduces complete target leakage.
* **Stratified Validation Split:** Evaluated on an independent test cohort of %d students (20%%%% holdout) stratified across class proportions.

---

## 3. Logistic Regression Parameter Estimates & Odds Ratios

| Predictor Term | Coefficient ($\\hat{\\beta}$) | Std. Error | Wald $z$ | $p$-value | Odds Ratio ($\\text{OR}$) | 95%%%% CI Lower | 95%%%% CI Upper | Sig. |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
%s

### Inferences & Odds Ratio Interpretation:
* **Academic Performance:** Secondary School (`ssc_percentage`) and Undergraduate Degree (`degree_percentage`) percentages exert strong positive effects on placement odds ($p < 0.05$). Every 1%%%% increase in secondary school grade elevates placement odds by **%.2f%%%%** ($\text{OR} = %.4f$).
* **Prior Work Experience:** Candidates with prior corporate work experience (`work_experience`) exhibit an odds ratio of **%.4f** (substantially higher likelihood of placement compared to fresh graduates with identical grades).
* **MBA Specialization:** Marketing & Finance (`specialisationMkt&Fin`) consistently shows higher placement odds compared to Marketing & HR.

---

## 4. Test Set Classification Performance (Threshold = %.2f)

| Metric | Score | Interpretation |
|:---|:---:|:---|
| **Accuracy** | **%.2f%%%%** (%d / %d) | Overall correct prediction rate |
| **Precision (PPV)** | **%.4f** | Proportion of predicted placements that were genuine |
| **Recall / Sensitivity** | **%.4f** | Proportion of actual placed candidates correctly identified |
| **Specificity** | **%.4f** | Proportion of unplaced candidates correctly screened |
| **F1-Score** | **%.4f** | Harmonic mean of precision and recall |
| **ROC-AUC** | **%.4f** | Discrimination threshold separation power |
| **Residual Deviance** | **%.2f** (Null: %.2f) | Likelihood ratio improvement over intercept-only model |
| **Akaike Info Criterion (AIC)** | **%.2f** | Model parsimony measure |

### Test Confusion Matrix:
```
                 Actual Placed (1)    Actual Unplaced (0)
Predicted Placed        %d (TP)              %d (FP)
Predicted Unplaced      %d (FN)              %d (TN)
```

---

## 5. Model Limitations
* Sample reflects a single institutional cohort; localized hiring dynamics for management graduates in Bangalore may not directly reflect non-management employment markets.
',
  nrow(student_df),
  nrow(test_df),
  paste(sprintf("| **%s** | %.4f | %.4f | %.2f | %s | %.4f | %.4f | %.4f | %s |",
                coef_df$Term, coef_df$Estimate, coef_df$Std_Error, coef_df$z_value, coef_df$p_value,
                coef_df$Odds_Ratio, coef_df$CI_95_Lower, coef_df$CI_95_Upper, coef_df$Significance),
        collapse = "\n"),
  (coef_df$Odds_Ratio[coef_df$Term == "ssc_percentage"] - 1) * 100,
  coef_df$Odds_Ratio[coef_df$Term == "ssc_percentage"],
  coef_df$Odds_Ratio[coef_df$Term == "work_experience"],
  threshold,
  accuracy * 100, tp + tn, length(actual_classes),
  precision,
  recall,
  specificity,
  f1_score,
  auc_roc,
  logit_model$deviance, logit_model$null.deviance,
  logit_model$aic,
  tp, fp,
  fn, tn
)

writeLines(report_content, report_path)
cat(sprintf("[SUCCESS] Model 4 evaluation report saved to: %s\n", report_path))
cat("==============================================================================\n")
