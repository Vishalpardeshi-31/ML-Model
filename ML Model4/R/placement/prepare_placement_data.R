# ==============================================================================
# ML Model 4 - Student Placement Prediction
# Data Preparation & Categorical Encoding Script
# Algorithm: Logistic Regression (Supervised)
# Target: placed (1 = Placed, 0 = Not Placed)
# Source: CMS Business School, Jain University (Ben Roshan D / Dr. D. Ganatra)
# ==============================================================================

raw_csv <- file.path("data", "raw", "placement", "Placement_Data_Full_Class.csv")
output_csv <- file.path("data", "processed", "student_placement.csv")

cat("[*] Initializing Student Placement Feature Preparation Pipeline...\n")

if (!file.exists(raw_csv)) {
  stop(sprintf("[-] Raw CSV not found: %s. Run data acquisition first.", raw_csv))
}

# 1. Load raw student placement data
raw_students <- read.csv(raw_csv, stringsAsFactors = FALSE)
cat(sprintf("[+] Loaded raw student dataset: %d candidates, %d attributes.\n",
            nrow(raw_students), ncol(raw_students)))

# 2. Schema Validation
expected_cols <- c("sl_no", "gender", "ssc_p", "ssc_b", "hsc_p", "hsc_b", "hsc_s",
                   "degree_p", "degree_t", "workex", "etest_p", "specialisation", "mba_p", "status")

for (c in expected_cols) {
  if (!c %in% colnames(raw_students)) {
    stop(sprintf("[-] Required column missing from raw dataset: %s", c))
  }
}

# 3. Target Variable Mapping (Binary)
# Target: placed = 1 for 'Placed', 0 for 'Not Placed'
raw_students$placed <- ifelse(trimws(raw_students$status) == "Placed", 1, 0)

target_counts <- table(raw_students$placed)
cat(sprintf("[+] Target distribution: %d Placed (1), %d Not Placed (0). Total: %d.\n",
            target_counts["1"], target_counts["0"], nrow(raw_students)))

# 4. Clean and Encode Features
# Explicit rule: 'salary' is ONLY available post-hiring for placed students and represents severe target leakage!
# 'salary' is strictly removed from the prediction feature matrix.

clean_students <- data.frame(
  student_id = raw_students$sl_no,
  gender = trimws(raw_students$gender),
  ssc_percentage = as.numeric(raw_students$ssc_p),
  ssc_board = trimws(raw_students$ssc_b),
  hsc_percentage = as.numeric(raw_students$hsc_p),
  hsc_board = trimws(raw_students$hsc_b),
  hsc_stream = trimws(raw_students$hsc_s),
  degree_percentage = as.numeric(raw_students$degree_p),
  degree_field = trimws(raw_students$degree_t),
  work_experience = ifelse(trimws(raw_students$workex) == "Yes", 1, 0),
  aptitude_test_percentage = as.numeric(raw_students$etest_p),
  mba_specialisation = trimws(raw_students$specialisation),
  mba_percentage = as.numeric(raw_students$mba_p),
  placed = raw_students$placed,
  stringsAsFactors = FALSE
)

# Verify complete records
missing_vals <- colSums(is.na(clean_students))
cat("[+] Missing values per column in clean dataset:\n")
print(missing_vals)

# 5. Write final processed CSV
dir.create(dirname(output_csv), showWarnings = FALSE, recursive = TRUE)
write.csv(clean_students, output_csv, row.names = FALSE)

cat(sprintf("[SUCCESS] Saved student placement dataset to %s (%d candidates, %d columns).\n",
            output_csv, nrow(clean_students), ncol(clean_students)))
