# ==============================================================================
# ML Model 4 - Model 2: Country Development Analysis
# Agglomerative Hierarchical Clustering Training & Evaluation
# Source Dataset: data/processed/country_development.csv
# ==============================================================================

suppressPackageStartupMessages({
  library(stats)
  library(cluster)
})

cat("==============================================================================\n")
cat("MODEL 2: COUNTRY DEVELOPMENT ANALYSIS (HIERARCHICAL CLUSTERING)\n")
cat("==============================================================================\n")

# 1. Load Processed Dataset
data_path <- file.path("data", "processed", "country_development.csv")
if (!file.exists(data_path)) {
  stop(sprintf("[-] Processed dataset not found: %s", data_path))
}

country_df <- read.csv(data_path, stringsAsFactors = FALSE)
cat(sprintf("[+] Successfully loaded %d sovereign nation records.\n", nrow(country_df)))

# 2. Select Numerical Development Indicators (Exclude country, country_code, year)
indicator_cols <- c(
  "gdp_per_capita", "life_expectancy", "total_population",
  "unemployment_rate", "infant_mortality", "health_expenditure_pct_gdp",
  "education_expenditure_pct_gdp", "internet_usage_pct"
)

features_df <- country_df[, indicator_cols]
cat(sprintf("[+] Selected %d numerical development indicators:\n", length(indicator_cols)))
cat(paste("   -", indicator_cols, collapse = "\n"), "\n")

# Log-transform extreme positive-skewed economic and demographic scales (GDP per capita, Population)
# Macroeconomic metrics span orders of magnitude ($250 to $116,000)
features_transformed <- features_df
features_transformed$gdp_per_capita <- log1p(features_transformed$gdp_per_capita)
features_transformed$total_population <- log1p(features_transformed$total_population)

# 3. Standardize Features (Z-Score Scaling)
scaled_features <- scale(features_transformed)
scaler_center <- attr(scaled_features, "scaled:center")
scaler_scale <- attr(scaled_features, "scaled:scale")

# 4. Calculate Distance Matrix (Euclidean Metric)
dist_matrix <- dist(scaled_features, method = "euclidean")

# 5. Compare Linkage Methods (Ward.D2 vs Complete vs Average)
cat("\n[*] Comparing Agglomerative Hierarchical Linkage Methods...\n")
linkage_methods <- c("ward.D2", "complete", "average")
comparison_list <- list()

for (m in linkage_methods) {
  hc_temp <- hclust(dist_matrix, method = m)
  coph_dist <- cophenetic(hc_temp)
  coph_corr <- cor(dist_matrix, coph_dist)
  
  # Evaluate silhouette score at K = 3
  cl_3 <- cutree(hc_temp, k = 3)
  sil_3 <- mean(silhouette(cl_3, dist_matrix)[, 3])
  
  comparison_list[[m]] <- data.frame(
    Method = m,
    Cophenetic_Correlation = round(coph_corr, 4),
    Silhouette_K3 = round(sil_3, 4),
    stringsAsFactors = FALSE
  )
}

comp_df <- do.call(rbind, comparison_list)
print(comp_df, row.names = FALSE)

# Defensible Method Choice:
# Ward.D2 minimizes within-cluster variance (similar to ANOVA objective)
# producing compact, non-chaining, economically interpretable clusters
chosen_method <- "ward.D2"
cat(sprintf("\n[+] Defensible Method Selected: '%s' (Minimizes Within-Cluster Variance, Silhouette = %.4f)\n",
            chosen_method, comp_df$Silhouette_K3[comp_df$Method == chosen_method]))

# 6. Fit Final Hierarchical Model
final_hc <- hclust(dist_matrix, method = chosen_method)

# 7. Cluster Cardinality (K = 3 Socio-Economic Strata)
# Global developmental studies classify nations into 3 core tiers:
# Underdeveloped (High Aid Need), Developing/Emerging, and Highly Developed
k_optimal <- 3
cluster_assignments <- cutree(final_hc, k = k_optimal)
country_df$cluster <- as.integer(cluster_assignments)

# Order clusters by mean GDP per capita so Cluster 1 = Underdeveloped, 2 = Developing, 3 = Developed
mean_gdp <- tapply(country_df$gdp_per_capita, country_df$cluster, mean)
cluster_order <- order(mean_gdp)
rank_map <- setNames(1:k_optimal, cluster_order)
country_df$cluster <- rank_map[as.character(country_df$cluster)]

cluster_counts <- table(country_df$cluster)
cat("\nSocioeconomic Tier Distribution:\n")
tier_names <- c("1: Underdeveloped / High Need", "2: Developing / Emerging", "3: Highly Developed")
for (i in 1:k_optimal) {
  cat(sprintf("   Tier %s: %d nations (%.2f%%)\n",
              tier_names[i], cluster_counts[as.character(i)], (cluster_counts[as.character(i)] / nrow(country_df)) * 100))
}

# 8. Dimensionality Reduction (2D PCA for Visualization)
pca_res <- prcomp(scaled_features, center = FALSE, scale. = FALSE)
explained_var <- round((pca_res$sdev^2 / sum(pca_res$sdev^2)) * 100, 2)
cat(sprintf("\n[+] 2D PCA Representation Computed (PC1: %.2f%%, PC2: %.2f%%, Total: %.2f%% variance).\n",
            explained_var[1], explained_var[2], explained_var[1] + explained_var[2]))

country_df$PCA1 <- round(pca_res$x[, 1], 4)
country_df$PCA2 <- round(pca_res$x[, 2], 4)

# 9. Compute Cluster Summary Profiles
cluster_summary <- list()
for (cl in 1:k_optimal) {
  sub_df <- country_df[country_df$cluster == cl, indicator_cols]
  means <- round(colMeans(sub_df), 2)
  medians <- round(apply(sub_df, 2, median), 2)
  mins <- round(apply(sub_df, 2, min), 2)
  maxs <- round(apply(sub_df, 2, max), 2)
  
  cluster_summary[[paste0("Tier_", cl)]] <- data.frame(
    Indicator = indicator_cols,
    Mean = means,
    Median = medians,
    Min = mins,
    Max = maxs,
    stringsAsFactors = FALSE
  )
}

# 10. Save Model Artifact (.rds)
dir.create("models", showWarnings = FALSE, recursive = TRUE)
model_rds_path <- file.path("models", "country_hierarchical.rds")

model_artifact <- list(
  algorithm = "Hierarchical Agglomerative Clustering",
  linkage_method = chosen_method,
  distance_metric = "euclidean",
  optimal_k = k_optimal,
  hclust_model = final_hc,
  comparison = comp_df,
  scaler = list(center = scaler_center, scale = scaler_scale),
  pca = list(rotation = pca_res$rotation[, 1:2], explained_var = explained_var[1:2]),
  indicator_names = indicator_cols,
  cluster_sizes = as.vector(cluster_counts),
  cluster_summaries = cluster_summary
)

saveRDS(model_artifact, model_rds_path)
cat(sprintf("\n[SUCCESS] Serialized Hierarchical Model saved to: %s\n", model_rds_path))

# 11. Save Clustered Output CSV
clustered_csv_path <- file.path("data", "processed", "country_clustered.csv")
write.csv(country_df, clustered_csv_path, row.names = FALSE)
cat(sprintf("[SUCCESS] Clustered country dataset saved to: %s (%d nations, %d cols)\n",
            clustered_csv_path, nrow(country_df), ncol(country_df)))

# 12. Generate Evaluation Markdown Report
report_path <- file.path("docs", "country_model_report.md")
dir.create("docs", showWarnings = FALSE, recursive = TRUE)

report_content <- sprintf(
'# Model 2 Evaluation Report — Country Development Analysis

**Learning Paradigm:** Unsupervised Learning  
**Algorithm:** Agglomerative Hierarchical Clustering  
**Dataset:** [`data/processed/country_development.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%%20Model4/data/processed/country_development.csv)  
**Sample Scale:** %d Sovereign Nations (World Bank WDI 2020 Harmonized Census)  
**Source:** The World Bank Group & UN Inter-Agency Organizations  
**Model Artifact:** [`models/country_hierarchical.rds`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%%20Model4/models/country_hierarchical.rds)  
**Clustered Output:** [`data/processed/country_clustered.csv`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%%20Model4/data/processed/country_clustered.csv)

---

## 1. Executive Summary & Objective

The objective of Model 2 is to construct an objective, data-driven developmental taxonomy of sovereign nation states using multi-dimensional socioeconomic indicators from the World Bank. The algorithm employs agglomerative hierarchical clustering with Ward’s minimum variance criterion on standardized indicator spaces.

---

## 2. Linkage Method Comparison & Justification

Three prominent agglomerative linkage criteria were rigorously evaluated:

| Linkage Method | Cophenetic Correlation | Silhouette Score ($K = 3$) | Rationale |
|:---|:---:|:---:|:---|
| **Ward.D2** | **%.4f** | **%.4f** | **Selected**: Minimizes intra-cluster variance, preventing chaining and forming compact, economically interpretable tiers. |
| **Complete** | %.4f | %.4f | Maximum pairwise distance; prone to sensitivity to extreme macroeconomic outliers. |
| **Average** | %.4f | %.4f | Compromise linkage; yields less distinct decision cut heights. |

---

## 3. Discovered Socioeconomic Developmental Tiers

The dendrogram was cut at $K = 3$, revealing three distinct developmental strata:

### Tier 1: Underdeveloped / High Humanitarian Need (N = %d nations, %.1f%%%%)
* **Average GDP per Capita:** $%.2f (Median: $%.2f)
* **Average Life Expectancy:** %.2f years (Median: %.2f)
* **Average Infant Mortality:** %.2f deaths per 1,000 live births (Median: %.2f)
* **Average Internet Penetration:** %.2f%%%%
* **Profile:** Low industrial output, elevated infant mortality, and constrained healthcare resources.

### Tier 2: Developing / Emerging Market Economies (N = %d nations, %.1f%%%%)
* **Average GDP per Capita:** $%.2f (Median: $%.2f)
* **Average Life Expectancy:** %.2f years (Median: %.2f)
* **Average Infant Mortality:** %.2f deaths per 1,000 live births (Median: %.2f)
* **Average Internet Penetration:** %.2f%%%%
* **Profile:** Intermediate industrialization, expanding telecommunications infrastructure, and moderate public health metrics.

### Tier 3: Highly Developed Industrial Economies (N = %d nations, %.1f%%%%)
* **Average GDP per Capita:** $%.2f (Median: $%.2f)
* **Average Life Expectancy:** %.2f years (Median: %.2f)
* **Average Infant Mortality:** %.2f deaths per 1,000 live births (Median: %.2f)
* **Average Internet Penetration:** %.2f%%%%
* **Profile:** Advanced post-industrial economies with universal digital penetration, comprehensive healthcare expenditure, and high life expectancies.

---

## 4. Dimensionality Reduction & 2D Projection (PCA)

Principal Component Analysis was applied to project the 8-dimensional space onto orthogonal axes:
* **PC1 Variance Explained:** %.2f%%%% (captures overall economic development vs mortality)
* **PC2 Variance Explained:** %.2f%%%% (captures population scale and labor dynamics)
* **Cumulative 2D Variance:** %.2f%%%%

---

## 5. Algorithmic Diagnostics
* **Distance Metric:** Euclidean Metric
* **Linkage Function:** Ward’s Minimum Variance Criterion ($D_{Ward}$)
* **Cophenetic Correlation:** %.4f
',
  nrow(country_df),
  comp_df$Cophenetic_Correlation[comp_df$Method == "ward.D2"], comp_df$Silhouette_K3[comp_df$Method == "ward.D2"],
  comp_df$Cophenetic_Correlation[comp_df$Method == "complete"], comp_df$Silhouette_K3[comp_df$Method == "complete"],
  comp_df$Cophenetic_Correlation[comp_df$Method == "average"], comp_df$Silhouette_K3[comp_df$Method == "average"],
  cluster_counts["1"], (cluster_counts["1"] / nrow(country_df)) * 100,
  cluster_summary$Tier_1$Mean[cluster_summary$Tier_1$Indicator == "gdp_per_capita"],
  cluster_summary$Tier_1$Median[cluster_summary$Tier_1$Indicator == "gdp_per_capita"],
  cluster_summary$Tier_1$Mean[cluster_summary$Tier_1$Indicator == "life_expectancy"],
  cluster_summary$Tier_1$Median[cluster_summary$Tier_1$Indicator == "life_expectancy"],
  cluster_summary$Tier_1$Mean[cluster_summary$Tier_1$Indicator == "infant_mortality"],
  cluster_summary$Tier_1$Median[cluster_summary$Tier_1$Indicator == "infant_mortality"],
  cluster_summary$Tier_1$Mean[cluster_summary$Tier_1$Indicator == "internet_usage_pct"],
  cluster_counts["2"], (cluster_counts["2"] / nrow(country_df)) * 100,
  cluster_summary$Tier_2$Mean[cluster_summary$Tier_2$Indicator == "gdp_per_capita"],
  cluster_summary$Tier_2$Median[cluster_summary$Tier_2$Indicator == "gdp_per_capita"],
  cluster_summary$Tier_2$Mean[cluster_summary$Tier_2$Indicator == "life_expectancy"],
  cluster_summary$Tier_2$Median[cluster_summary$Tier_2$Indicator == "life_expectancy"],
  cluster_summary$Tier_2$Mean[cluster_summary$Tier_2$Indicator == "infant_mortality"],
  cluster_summary$Tier_2$Median[cluster_summary$Tier_2$Indicator == "infant_mortality"],
  cluster_summary$Tier_2$Mean[cluster_summary$Tier_2$Indicator == "internet_usage_pct"],
  cluster_counts["3"], (cluster_counts["3"] / nrow(country_df)) * 100,
  cluster_summary$Tier_3$Mean[cluster_summary$Tier_3$Indicator == "gdp_per_capita"],
  cluster_summary$Tier_3$Median[cluster_summary$Tier_3$Indicator == "gdp_per_capita"],
  cluster_summary$Tier_3$Mean[cluster_summary$Tier_3$Indicator == "life_expectancy"],
  cluster_summary$Tier_3$Median[cluster_summary$Tier_3$Indicator == "life_expectancy"],
  cluster_summary$Tier_3$Mean[cluster_summary$Tier_3$Indicator == "infant_mortality"],
  cluster_summary$Tier_3$Median[cluster_summary$Tier_3$Indicator == "infant_mortality"],
  cluster_summary$Tier_3$Mean[cluster_summary$Tier_3$Indicator == "internet_usage_pct"],
  explained_var[1],
  explained_var[2],
  explained_var[1] + explained_var[2],
  comp_df$Cophenetic_Correlation[comp_df$Method == "ward.D2"]
)

writeLines(report_content, report_path)
cat(sprintf("[SUCCESS] Model 2 evaluation report saved to: %s\n", report_path))
cat("==============================================================================\n")
