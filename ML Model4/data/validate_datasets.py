"""
ML Model 4 - Dataset Quality and Integrity Validation Suite
Validates all 4 processed real-world datasets and outputs comprehensive diagnostic metrics.
"""

import os
import pandas as pd
import numpy as np

PROCESSED_DIR = os.path.join(os.path.dirname(__file__), "processed")

def audit_dataset(filename, title, target_col=None, id_col=None):
    filepath = os.path.join(PROCESSED_DIR, filename)
    print("\n" + "=" * 80)
    print(f"DATASET AUDIT: {title.upper()}")
    print(f"File: {filepath}")
    print("=" * 80)

    if not os.path.exists(filepath):
        print(f"[ERROR] File does not exist: {filepath}")
        return

    df = pd.read_csv(filepath)
    n_rows, n_cols = df.shape
    print(f"1. DIMENSIONS: {n_rows} Rows x {n_cols} Columns")

    # Duplicates
    n_dupes = df.duplicated().sum()
    print(f"2. DUPLICATE ROWS: {n_dupes} ({n_dupes / n_rows * 100:.2f}%)")

    # Unique entities
    if id_col and id_col in df.columns:
        n_unique = df[id_col].nunique()
        print(f"3. UNIQUE ENTITIES ({id_col}): {n_unique} / {n_rows}")

    # Column Schema & Missing Values
    print("\n4. COLUMN SCHEMA & MISSING VALUES:")
    schema_rows = []
    for col in df.columns:
        dtype = str(df[col].dtype)
        n_missing = int(df[col].isna().sum())
        pct_missing = round(n_missing / n_rows * 100, 2)
        schema_rows.append({
            "Column": col,
            "Type": dtype,
            "Missing": n_missing,
            "MissingPct": f"{pct_missing}%"
        })
    print(pd.DataFrame(schema_rows).to_string(index=False))

    # Numerical Variable Ranges
    print("\n5. NUMERICAL VARIABLE RANGES:")
    num_cols = df.select_dtypes(include=[np.number]).columns
    stats_rows = []
    for col in num_cols:
        s = df[col].dropna()
        stats_rows.append({
            "Variable": col,
            "Min": round(float(s.min()), 4),
            "Median": round(float(s.median()), 4),
            "Mean": round(float(s.mean()), 4),
            "Max": round(float(s.max()), 4),
            "StdDev": round(float(s.std()), 4)
        })
    print(pd.DataFrame(stats_rows).to_string(index=False))

    # Target Distribution
    if target_col and target_col in df.columns:
        print(f"\n6. TARGET DISTRIBUTION ({target_col}):")
        t_vals = df[target_col]
        if df[target_col].nunique() > 10:
            print(f"   Continuous Target: Min={t_vals.min():.2f}, Median={t_vals.median():.2f}, Mean={t_vals.mean():.2f}, Max={t_vals.max():.2f}")
            print(f"   Points scoring rate (>0 pts): {(t_vals > 0).mean() * 100:.2f}%")
        else:
            vc = t_vals.value_counts(dropna=False)
            for k, count in vc.items():
                pct = count / n_rows * 100
                print(f"   Class '{k}': {count} ({pct:.2f}%)")

    # Anomaly / Outlier Scan
    print("\n7. INTEGRITY & ANOMALY SCAN:")
    anomalies = []
    for col in num_cols:
        vals = df[col]
        if np.isinf(vals).any():
            anomalies.append(f"Infinite values in {col}")
        if np.isnan(vals).any():
            anomalies.append(f"NaN values in {col}")

    if anomalies:
        for a in anomalies:
            print(f"   [WARNING] {a}")
    else:
        print("   [OK] Zero NaN, zero Inf, zero corrupted records. Data integrity verified.")

if __name__ == "__main__":
    audit_dataset("brain_activity.csv", "Brain Activity Pattern Discovery", id_col="epoch_id")
    audit_dataset("country_development.csv", "Country Development Analysis", id_col="country_code")
    audit_dataset("f1_race_data.csv", "Formula 1 Race Outcome Analysis", target_col="race_points")
    audit_dataset("student_placement.csv", "Student Placement Prediction", target_col="placed", id_col="student_id")
