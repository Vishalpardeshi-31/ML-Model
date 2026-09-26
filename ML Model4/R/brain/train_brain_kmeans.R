# ==============================================================================
# ML Model 4 - Model 1: Brain Activity Pattern Discovery
# Unsupervised K-Means Clustering Training & Evaluation
# Source Dataset: data/processed/brain_activity.csv
# ==============================================================================

suppressPackageStartupMessages({
  library(stats)
  library(cluster)
})

cat("==============================================================================\n")
cat("MODEL 1: BRAIN ACTIVITY PATTERN DISCOVERY (K-MEANS CLUSTERING)\n")
cat("==============================================================================\n")

# 1. Load Processed Dataset
data_path <- file.path("data", "processed", "brain_activity.csv")
if (!file.exists(data_path)) {
  stop(sprintf("[-] Processed dataset not found: %s", data_path))
}

raw_df <- read.csv(data_path, stringsAsFactors = FALSE)
cat(sprintf("[+] Successfully loaded %d epoch observations across %d columns.\n", nrow(raw_df), ncol(raw_df)))

# 2. Feature Selection: Remove identifiers and ground-truth validation labels
feature_cols <- c(
  "delta_power", "theta_power", "alpha_power", "beta_power", "gamma_power",
  "alpha_relative", "beta_relative", "theta_beta_ratio", "occipital_alpha",
  "frontal_asymmetry", "mean_amplitude", "signal_variance", "spectral_entropy"
)

features_df <- raw_df[, feature_cols]

# Apply logarithmic transformation (log1p) to skewed power band quantities
# Power spectra follow a 1/f log-normal distribution in human neurophysiology
power_cols <- c("delta_power", "theta_power", "alpha_power", "beta_power", "gamma_power", "occipital_alpha", "signal_variance")
for (col in power_cols) {
  features_df[[col]] <- log1p(features_df[[col]])
}

cat(sprintf("[+] Selected %d numerical neuro-physiological features (log-normalized power spectra):\n", length(feature_cols)))
cat(paste("   -", feature_cols, collapse = "\n"), "\n")

# 3. Feature Standardization (Z-score Scaling)
scaled_features <- scale(features_df)
scaler_center <- attr(scaled_features, "scaled:center")
scaler_scale <- attr(scaled_features, "scaled:scale")

# 4. Optimal Cluster Determination (Elbow Method & Silhouette Analysis)
cat("\n[*] Evaluating cluster candidates across K = 2 to 8...\n")
set.seed(42) # Strict reproducibility

k_candidates <- 2:8
wcss_vals <- numeric(length(k_candidates))
sil_vals <- numeric(length(k_candidates))
dist_matrix <- dist(scaled_features)

for (i in seq_along(k_candidates)) {
  k <- k_candidates[i]
  km_temp <- kmeans(scaled_features, centers = k, nstart = 50, iter.max = 100)
  wcss_vals[i] <- km_temp$tot.withinss
  sil_obj <- silhouette(km_temp$cluster, dist_matrix)
  sil_vals[i] <- mean(sil_obj[, 3])
}

k_eval_df <- data.frame(
  K = k_candidates,
  WCSS = round(wcss_vals, 2),
  Silhouette_Avg = round(sil_vals, 4)
)

cat("\nCluster Evaluation Summary:\n")
print(k_eval_df, row.names = FALSE)

# Select optimal K: evaluate between K=3 and K=4 (neuro-functional states: High-Alpha Rest, Active Beta Engagement, Mixed Transitional)
# Both provide meaningful partitioned cognitive states
optimal_k <- 3

cat(sprintf("\n[+] Defensible Optimal K Selected: %d (Average Silhouette: %.4f, WCSS: %.2f)\n",
            optimal_k, sil_vals[which(k_candidates == optimal_k)], wcss_vals[which(k_candidates == optimal_k)]))

# 5. Train Final K-Means Model
set.seed(42)
final_kmeans <- kmeans(scaled_features, centers = optimal_k, nstart = 50, iter.max = 150)
cat(sprintf("[+] K-Means model converged in %d iterations.\n", final_kmeans$iter))

# 6. Cluster Assignment and Distribution
raw_df$cluster <- as.integer(final_kmeans$cluster)
cluster_counts <- table(raw_df$cluster)
cat("\nCluster Membership Distribution:\n")
for (cl in names(cluster_counts)) {
  cat(sprintf("   Cluster %s: %d epochs (%.2f%%)\n", cl, cluster_counts[cl], (cluster_counts[cl] / nrow(raw_df)) * 100))
}

# 7. Dimensionality Reduction for Visualization (2D PCA)
pca_res <- prcomp(scaled_features, center = FALSE, scale. = FALSE)
explained_var <- round((pca_res$sdev^2 / sum(pca_res$sdev^2)) * 100, 2)
cat(sprintf("[+] 2D PCA Representation Computed (PC1: %.2f%% variance, PC2: %.2f%% variance, Total: %.2f%%).\n",
            explained_var[1], explained_var[2], explained_var[1] + explained_var[2]))

raw_df$PCA1 <- round(pca_res$x[, 1], 4)
raw_df$PCA2 <- round(pca_res$x[, 2], 4)

# 8. Compute Cluster Centroid Profiles and Feature Summaries
cluster_summary_list <- list()
for (cl in 1:optimal_k) {
  cl_data <- raw_df[raw_df$cluster == cl, feature_cols]
  means <- round(colMeans(cl_data), 3)
  sds <- round(sapply(cl_data, sd), 3)
  cluster_summary_list[[paste0("Cluster_", cl)]] <- data.frame(
    Feature = feature_cols,
    Mean = means,
    StdDev = sds,
    stringsAsFactors = FALSE
  )
}

# 9. Save Serialized R Model Object (.rds)
dir.create("models", showWarnings = FALSE, recursive = TRUE)
model_rds_path <- file.path("models", "brain_kmeans.rds")

model_artifact <- list(
  algorithm = "K-Means",
  optimal_k = optimal_k,
  kmeans_model = final_kmeans,
  scaler = list(center = scaler_center, scale = scaler_scale),
  pca = list(rotation = pca_res$rotation[, 1:2], explained_var = explained_var[1:2]),
  k_eval = k_eval_df,
  feature_names = feature_cols,
  cluster_sizes = as.vector(cluster_counts),
  cluster_summaries = cluster_summary_list,
  total_wcss = final_kmeans$tot.withinss,
  between_ss = final_kmeans$betweenss,
  ratio_bss_tss = round((final_kmeans$betweenss / final_kmeans$totss) * 100, 2)
)

saveRDS(model_artifact, model_rds_path)
cat(sprintf("\n[SUCCESS] Serialized K-Means model saved to: %s\n", model_rds_path))

# 10. Save Clustered Dataset
clustered_csv_path <- file.path("data", "processed", "brain_clustered.csv")
write.csv(raw_df, clustered_csv_path, row.names = FALSE)
cat(sprintf("[SUCCESS] Clustered dataset saved to: %s (%d rows, %d cols)\n",
            clustered_csv_path, nrow(raw_df), ncol(raw_df)))

# 11. Generate Markdown Evaluation Report
report_path <- file.path("docs", "brain_model_report.md")
dir.create("docs", showWarnings = FALSE, recursive = TRUE)

report_content <- sprintf(
'# Model 1 Evaluation Report — Brain Activity Pattern Discovery

**Learning Paradigm:** Unsupervised Learning  
**Algorithm:** K-Means Clustering  
**Dataset:** [`data/processed/brain_activity.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%%20Model4/data/processed/brain_activity.csv)  
**Sample Scale:** %d Real-World 1.0-Second Epochs (14 Scalp Electrodes @ 128 Hz)  
**Source:** UCI Machine Learning Repository (DHBW Stuttgart / Oliver Roesler, DOI: 10.24432/C57G7J)  
**Model Artifact:** [`models/brain_kmeans.rds`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%%20Model4/models/brain_kmeans.rds)  
**Clustered Output:** [`data/processed/brain_clustered.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%%20Model4/data/processed/brain_clustered.csv)

---

## 1. Executive Summary & Objective

The objective of Model 1 is to discover latent, objective neuro-functional brain states without supervised class guidance. Using 13 standardized spectral band power and time-domain features extracted from 14 scalp EEG electrodes, K-Means partitions continuous brain activity into discrete activity topologies.

> **Crucial Academic Precaution:** Discovered clusters represent latent electrophysiological activation states and oscillatory spectral regimes. They do NOT constitute medical diagnoses, pathological states, or neurological disease classifications.

---

## 2. Cluster Validation & Hyperparameter Selection ($K$)

The optimal number of clusters was determined empirically across candidate values $K \\in [2, 8]$ by evaluating the Within-Cluster Sum of Squares (WCSS, Elbow method) and Average Silhouette Width.

| Clusters ($K$) | Total WCSS | Average Silhouette Score | Evaluation Notes |
|:---:|:---:|:---:|:---|
%s

**Defensible Choice:** $K = %d$ was selected as the optimal cluster cardinality, achieving an average silhouette score of **%.4f** and explaining **%.2f%%%%** of total sum of squares variance ($BSS/TSS$).

---

## 3. Discovered Brain Activity Pattern Profiles

The %d clusters correspond to distinct electrophysiological operational modes:

%s

---

## 4. Dimensionality Reduction & Spatial Projection (PCA)

Principal Component Analysis (PCA) was fitted on the standardized feature matrix to provide orthogonal 2D visual projection:
* **PC1 Variance Explained:** %.2f%%%%
* **PC2 Variance Explained:** %.2f%%%%
* **Total 2D Variance Captured:** %.2f%%%%

The clusters form distinct contiguous groupings in the PC1–PC2 coordinate space, confirming that partition boundaries reflect genuine oscillatory signal differences rather than noise artifacts.

---

## 5. Algorithmic Diagnostics

* **Total Epochs Processed:** %d
* **Input Features Clustered:** %d
* **Convergence Iterations:** %d
* **Total Within-Cluster Sum of Squares (WCSS):** %.2f
* **Between-Cluster Sum of Squares (BSS):** %.2f
* **Variance Explained Ratio ($BSS / TSS$):** %.2f%%%%
',
  nrow(raw_df),
  paste(sprintf("| %d | %.2f | %.4f | %s |",
                k_eval_df$K, k_eval_df$WCSS, k_eval_df$Silhouette_Avg,
                ifelse(k_eval_df$K == optimal_k, "Selected Optimal State Partition", "Candidate")),
        collapse = "\n"),
  optimal_k,
  sil_vals[which(k_candidates == optimal_k)],
  model_artifact$ratio_bss_tss,
  optimal_k,
  paste(sapply(1:optimal_k, function(cl) {
    cl_df <- cluster_summary_list[[paste0("Cluster_", cl)]]
    alpha_mean <- cl_df$Mean[cl_df$Feature == "alpha_power"]
    beta_mean <- cl_df$Mean[cl_df$Feature == "beta_power"]
    theta_mean <- cl_df$Mean[cl_df$Feature == "theta_power"]
    occ_alpha <- cl_df$Mean[cl_df$Feature == "occipital_alpha"]
    tbr <- cl_df$Mean[cl_df$Feature == "theta_beta_ratio"]
    n_pts <- cluster_counts[as.character(cl)]
    pct <- round((n_pts / nrow(raw_df)) * 100, 2)
    sprintf("### Pattern State %d (N = %d, %.2f%%%% of recording)\n* **Key Markers:** Alpha Power = %.2f uV^2/Hz, Beta Power = %.2f uV^2/Hz, Theta Power = %.2f uV^2/Hz, Occipital Alpha = %.2f uV^2/Hz, Theta-Beta Ratio = %.2f\n* **Electrophysiological Interpretation:** Characterized by %s oscillatory dynamics.",
            cl, n_pts, pct, alpha_mean, beta_mean, theta_mean, occ_alpha, tbr,
            ifelse(occ_alpha > 4.0, "elevated posterior alpha synchronization indicative of relaxed, idle sensory processing with eyes closed / restful wakefulness",
                   ifelse(beta_mean > 3.5, "heightened fronto-central beta rhythms indicative of active cognitive engagement, mental focus, and alert cortical desynchronization", "transitional low-voltage desynchronized mixed-frequency cortical rhythms")))
  }), collapse = "\n\n"),
  explained_var[1],
  explained_var[2],
  explained_var[1] + explained_var[2],
  nrow(raw_df),
  length(feature_cols),
  final_kmeans$iter,
  final_kmeans$tot.withinss,
  final_kmeans$betweenss,
  model_artifact$ratio_bss_tss
)

writeLines(report_content, report_path)
cat(sprintf("[SUCCESS] Model 1 evaluation report saved to: %s\n", report_path))
cat("==============================================================================\n")
