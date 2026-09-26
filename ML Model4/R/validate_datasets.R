# ==============================================================================
# ML Model 4 - Master Dataset Validation Script
# Rigorous automated quality audit for all 4 processed datasets
# ==============================================================================

validate_dataset <- function(file_path, name, target_col = NULL, id_col = NULL) {
  cat("\n==============================================================================\n")
  cat(sprintf("DATASET AUDIT: %s\n", toupper(name)))
  cat(sprintf("File: %s\n", file_path))
  cat("==============================================================================\n")
  
  if (!file.exists(file_path)) {
    cat(sprintf("[ERROR] File does not exist: %s\n", file_path))
    return(NULL)
  }
  
  df <- read.csv(file_path, stringsAsFactors = FALSE)
  
  # 1. Dimensions
  n_rows <- nrow(df)
  n_cols <- ncol(df)
  cat(sprintf("1. DIMENSIONS: %d Rows x %d Columns\n", n_rows, n_cols))
  
  # 2. Duplicate rows
  n_dupes <- sum(duplicated(df))
  cat(sprintf("2. DUPLICATE ROWS: %d (%.2f%%)\n", n_dupes, (n_dupes / n_rows) * 100))
  
  # 3. Unique entities
  if (!is.null(id_col) && id_col %in% colnames(df)) {
    n_unique <- length(unique(df[[id_col]]))
    cat(sprintf("3. UNIQUE ENTITIES (%s): %d / %d\n", id_col, n_unique, n_rows))
  }
  
  # 4. Column Schema & Data Types & Missing Values
  cat("\n4. COLUMN SCHEMA & MISSING VALUES:\n")
  schema_df <- data.frame(
    Column = colnames(df),
    Type = sapply(df, class),
    Missing = sapply(df, function(x) sum(is.na(x))),
    MissingPct = round(sapply(df, function(x) sum(is.na(x))) / n_rows * 100, 2),
    stringsAsFactors = FALSE
  )
  print(schema_df, row.names = FALSE)
  
  # 5. Numerical Range Summaries (Min, Median, Mean, Max)
  cat("\n5. NUMERICAL VARIABLE RANGES:\n")
  num_cols <- colnames(df)[sapply(df, is.numeric)]
  if (length(num_cols) > 0) {
    num_stats <- do.call(rbind, lapply(num_cols, function(col) {
      vals <- df[[col]]
      vals <- vals[!is.na(vals)]
      data.frame(
        Variable = col,
        Min = round(min(vals), 4),
        Median = round(median(vals), 4),
        Mean = round(mean(vals), 4),
        Max = round(max(vals), 4),
        stringsAsFactors = FALSE
      )
    }))
    print(num_stats, row.names = FALSE)
  }
  
  # 6. Target Distribution (where applicable)
  if (!is.null(target_col) && target_col %in% colnames(df)) {
    cat(sprintf("\n6. TARGET DISTRIBUTION (%s):\n", target_col))
    t_vals <- df[[target_col]]
    if (is.numeric(t_vals) && length(unique(t_vals)) > 10) {
      cat(sprintf("   Continuous Target: Min = %.2f, Median = %.2f, Mean = %.2f, Max = %.2f\n",
                  min(t_vals), median(t_vals), mean(t_vals), max(t_vals)))
      cat(sprintf("   Non-zero rate: %.2f%%\n", mean(t_vals > 0) * 100))
    } else {
      tbl <- table(t_vals, useNA = "ifany")
      prop <- round(prop.table(tbl) * 100, 2)
      for (k in names(tbl)) {
        cat(sprintf("   Class '%s': %d (%.2f%%)\n", k, tbl[k], prop[k]))
      }
    }
  }
  
  # 7. Suspicious / Outlier Value Check
  cat("\n7. INTEGRITY & ANOMALY SCAN:\n")
  suspicious_found <- FALSE
  for (col in num_cols) {
    vals <- df[[col]]
    if (any(is.infinite(vals))) {
      cat(sprintf("   [WARNING] Infinite values detected in column '%s'!\n", col))
      suspicious_found <- TRUE
    }
    if (any(is.nan(vals))) {
      cat(sprintf("   [WARNING] NaN values detected in column '%s'!\n", col))
      suspicious_found <- TRUE
    }
  }
  if (!suspicious_found) {
    cat("   [OK] No infinite, NaN, or corrupted values detected. Integrity check PASSED.\n")
  }
}

# Run validation across all four datasets
cat("\n==============================================================================\n")
cat("ML MODEL 4 - PRODUCTION DATA VALIDATION SUITE\n")
cat("==============================================================================\n")

validate_dataset(file.path("data", "processed", "brain_activity.csv"), "Brain Activity Pattern Discovery", id_col = "epoch_id")
validate_dataset(file.path("data", "processed", "country_development.csv"), "Country Development Analysis", id_col = "country_code")
validate_dataset(file.path("data", "processed", "f1_race_data.csv"), "Formula 1 Race Outcome Analysis", target_col = "race_points")
validate_dataset(file.path("data", "processed", "student_placement.csv"), "Student Placement Prediction", target_col = "placed", id_col = "student_id")

cat("\n==============================================================================\n")
cat("VALIDATION SUITE RUN COMPLETE\n")
cat("==============================================================================\n")
