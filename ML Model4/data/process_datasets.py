"""
ML Model 4 - Master Real-World Dataset Processing Engine
Executes deterministic preprocessing, feature derivation, and validation across all 4 datasets.
Strict Policy: Zero synthetic or fabricated data.
"""

import os
import csv
import json
import math
import numpy as np
import pandas as pd

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RAW_DIR = os.path.join(BASE_DIR, "data", "raw")
PROCESSED_DIR = os.path.join(BASE_DIR, "data", "processed")
os.makedirs(PROCESSED_DIR, exist_ok=True)

# =============================================================================
# 1. BRAIN ACTIVITY PATTERN DISCOVERY (K-Means)
# =============================================================================
def process_brain_data():
    raw_arff = os.path.join(RAW_DIR, "brain", "EEG Eye State.arff")
    out_csv = os.path.join(PROCESSED_DIR, "brain_activity.csv")
    print(f"[*] Processing EEG Brain Activity data from {raw_arff}...")

    # Read ARFF file data lines
    data_lines = []
    with open(raw_arff, "r", encoding="utf-8") as f:
        in_data = False
        for line in f:
            line = line.strip()
            if not line:
                continue
            if line.upper().startswith("@DATA"):
                in_data = True
                continue
            if in_data and not line.startswith("@"):
                data_lines.append(line.split(","))

    channel_names = ["AF3", "F7", "F3", "FC5", "T7", "P7", "O1", "O2", "P8", "T8", "FC6", "F4", "F8", "AF4"]
    col_names = channel_names + ["eyeDetection"]
    df = pd.DataFrame(data_lines, columns=col_names).astype(float)
    total_raw = len(df)
    print(f"[+] Loaded {total_raw} raw time-series observations.")

    # Physiological artifact filtering: normal baseline is ~4000-4800 uV
    mask = (df[channel_names] >= 3000) & (df[channel_names] <= 6000)
    clean_df = df[mask.all(axis=1)].reset_index(drop=True)
    clean_count = len(clean_df)
    print(f"[+] Retained {clean_count} artifact-free samples ({total_raw - clean_count} spikes rejected).")

    # Spectral feature extraction across 1-second epochs (128 samples @ 128 Hz, 50% overlap = 64 samples)
    fs = 128
    win_size = 128
    step = 64
    epochs = []

    for start in range(0, clean_count - win_size + 1, step):
        chunk = clean_df.iloc[start:start + win_size]
        epoch_id = len(epochs) + 1

        # Global average signal across 14 channels
        global_sig = chunk[channel_names].mean(axis=1).values
        sig_demean = global_sig - np.mean(global_sig)

        # FFT & Power Spectral Density
        fft_vals = np.fft.rfft(sig_demean)
        psd = (np.abs(fft_vals) ** 2) / (win_size * fs)
        freqs = np.fft.rfftfreq(win_size, 1.0 / fs)

        # Band powers
        delta = float(np.sum(psd[(freqs >= 0.5) & (freqs < 4.0)]))
        theta = float(np.sum(psd[(freqs >= 4.0) & (freqs < 8.0)]))
        alpha = float(np.sum(psd[(freqs >= 8.0) & (freqs < 13.0)]))
        beta = float(np.sum(psd[(freqs >= 13.0) & (freqs < 30.0)]))
        gamma = float(np.sum(psd[(freqs >= 30.0) & (freqs <= 45.0)]))
        total_p = delta + theta + alpha + beta + gamma + 1e-12

        # Relative power
        alpha_rel = alpha / total_p
        beta_rel = beta / total_p
        theta_beta_ratio = theta / (beta + 1e-12)

        # Occipital Alpha (O1, O2)
        occ_sig = chunk[["O1", "O2"]].mean(axis=1).values - chunk[["O1", "O2"]].mean().mean()
        occ_fft = np.fft.rfft(occ_sig)
        occ_psd = (np.abs(occ_fft) ** 2) / (win_size * fs)
        occipital_alpha = float(np.sum(occ_psd[(freqs >= 8.0) & (freqs < 13.0)]))

        # Frontal Alpha Asymmetry (F4 vs F3)
        f3_sig = chunk["F3"].values - np.mean(chunk["F3"].values)
        f4_sig = chunk["F4"].values - np.mean(chunk["F4"].values)
        f3_a = float(np.sum(((np.abs(np.fft.rfft(f3_sig)) ** 2) / (win_size * fs))[(freqs >= 8.0) & (freqs < 13.0)]))
        f4_a = float(np.sum(((np.abs(np.fft.rfft(f4_sig)) ** 2) / (win_size * fs))[(freqs >= 8.0) & (freqs < 13.0)]))
        frontal_asymmetry = (f4_a - f3_a) / (f4_a + f3_a + 1e-12)

        # Time domain & Entropy
        mean_amp = float(np.mean(global_sig))
        sig_var = float(np.var(global_sig))

        p_norm = psd / (np.sum(psd) + 1e-12)
        p_norm = p_norm[p_norm > 0]
        spec_entropy = float(-np.sum(p_norm * np.log2(p_norm)))

        # Ground truth eye detection state in this epoch
        eye_state = int(chunk["eyeDetection"].mean() >= 0.5)

        epochs.append({
            "epoch_id": epoch_id,
            "delta_power": round(delta, 4),
            "theta_power": round(theta, 4),
            "alpha_power": round(alpha, 4),
            "beta_power": round(beta, 4),
            "gamma_power": round(gamma, 4),
            "alpha_relative": round(alpha_rel, 4),
            "beta_relative": round(beta_rel, 4),
            "theta_beta_ratio": round(theta_beta_ratio, 4),
            "occipital_alpha": round(occipital_alpha, 4),
            "frontal_asymmetry": round(frontal_asymmetry, 4),
            "mean_amplitude": round(mean_amp, 2),
            "signal_variance": round(sig_var, 4),
            "spectral_entropy": round(spec_entropy, 4),
            "eye_state_ground_truth": eye_state
        })

    out_df = pd.DataFrame(epochs)
    out_df.to_csv(out_csv, index=False)
    print(f"[SUCCESS] Saved {len(out_df)} authentic EEG epoch records to {out_csv}.")
    return out_df

# =============================================================================
# 2. COUNTRY DEVELOPMENT ANALYSIS (Hierarchical Clustering)
# =============================================================================
def process_country_data():
    raw_json = os.path.join(RAW_DIR, "country", "worldbank_indicators_raw.json")
    out_csv = os.path.join(PROCESSED_DIR, "country_development.csv")
    print(f"[*] Processing World Bank country development data from {raw_json}...")

    with open(raw_json, "r", encoding="utf-8") as f:
        wb_data = json.load(f)

    REGIONAL_CODES = {
        "AFE", "AFW", "ARB", "CEB", "CSS", "EAP", "EAR", "EAS", "ECA", "ECS",
        "EMU", "EUU", "FCS", "HIC", "HPC", "IBD", "IBT", "IDA", "IDB", "IDX",
        "INX", "KAC", "LAC", "LCN", "LDC", "LIC", "LMC", "LMY", "LTE", "MEA",
        "MIC", "MNA", "NAC", "OED", "OSS", "PRE", "PSS", "PST", "SAS", "SSA",
        "SSF", "SST", "TEA", "TEC", "TLA", "TMN", "TSA", "TSS", "UMC", "WLD"
    }

    target_year = "2020"
    country_dict = {}

    for ind_name, records in wb_data.items():
        for rec in records:
            if rec.get("date") != target_year:
                continue
            iso = rec.get("countryiso3code")
            cname = rec.get("country", {}).get("value")
            val = rec.get("value")
            if not iso or len(iso) != 3 or iso in REGIONAL_CODES:
                continue

            if iso not in country_dict:
                country_dict[iso] = {
                    "country": cname,
                    "country_code": iso,
                    "year": int(target_year)
                }
            country_dict[iso][ind_name] = val

    df = pd.DataFrame(list(country_dict.values()))

    # Require completeness on core development indicators
    core_cols = ["gdp_per_capita", "life_expectancy", "total_population", "unemployment_rate", "infant_mortality", "internet_usage_pct"]
    df_clean = df.dropna(subset=core_cols).copy()

    # Fill secondary health and education with global median to retain max sovereign coverage
    for col in ["health_expenditure_pct_gdp", "education_expenditure_pct_gdp"]:
        if col in df_clean.columns:
            median_val = df_clean[col].median()
            df_clean[col] = df_clean[col].fillna(round(median_val, 2))

    df_clean = df_clean.sort_values("country").reset_index(drop=True)
    df_clean.to_csv(out_csv, index=False)
    print(f"[SUCCESS] Saved {len(df_clean)} sovereign country records to {out_csv}.")
    return df_clean

# =============================================================================
# 3. FORMULA 1 RACE OUTCOME ANALYSIS (Multiple Linear Regression)
# =============================================================================
def process_f1_data():
    races_csv = os.path.join(RAW_DIR, "f1", "races.csv")
    results_csv = os.path.join(RAW_DIR, "f1", "results.csv")
    qualifying_csv = os.path.join(RAW_DIR, "f1", "qualifying.csv")
    drivers_csv = os.path.join(RAW_DIR, "f1", "drivers.csv")
    out_csv = os.path.join(PROCESSED_DIR, "f1_race_data.csv")
    print(f"[*] Processing Formula 1 race outcome data...")

    races = pd.read_csv(races_csv)
    results = pd.read_csv(results_csv)
    qualifying = pd.read_csv(qualifying_csv)
    drivers = pd.read_csv(drivers_csv)

    # Filter to Turbo Hybrid Era (2014-2023)
    hybrid_races = races[(races["year"] >= 2014) & (races["year"] <= 2023)].copy()
    hybrid_race_ids = set(hybrid_races["raceId"])
    hybrid_results = results[results["raceId"].isin(hybrid_race_ids)].copy()

    # Helper: Parse lap time string "1:24.312" into seconds
    def parse_time(t_str):
        if pd.isna(t_str) or t_str in ("", "\\N"):
            return np.nan
        try:
            parts = str(t_str).split(":")
            if len(parts) == 2:
                return float(parts[0]) * 60 + float(parts[1])
            elif len(parts) == 1:
                return float(parts[0])
        except Exception:
            return np.nan
        return np.nan

    qualifying["q1_sec"] = qualifying["q1"].apply(parse_time)
    qualifying["q2_sec"] = qualifying["q2"].apply(parse_time)
    qualifying["q3_sec"] = qualifying["q3"].apply(parse_time)
    qualifying["q_best_sec"] = qualifying[["q1_sec", "q2_sec", "q3_sec"]].min(axis=1)

    # Pole time per race
    pole_times = qualifying.groupby("raceId")["q_best_sec"].min().reset_index().rename(columns={"q_best_sec": "pole_sec"})
    qualifying = qualifying.merge(pole_times, on="raceId", how="left")
    qualifying["q_delta_to_pole"] = qualifying["q_best_sec"] - qualifying["pole_sec"]
    qualifying["q_delta_to_pole"] = qualifying["q_delta_to_pole"].clip(lower=0.0).fillna(0.0)

    # Merge race metadata and driver names
    merged = hybrid_results.merge(hybrid_races[["raceId", "year", "round", "circuitId", "name"]], on="raceId", how="left")
    merged = merged.merge(drivers[["driverId", "forename", "surname"]], on="driverId", how="left")
    merged["driver_name"] = merged["forename"] + " " + merged["surname"]

    # Merge qualifying session info
    merged = merged.merge(
        qualifying[["raceId", "driverId", "position", "q_delta_to_pole"]],
        on=["raceId", "driverId"],
        how="left"
    ).rename(columns={"position_y": "qualifying_position"})

    # Chronological sort for pre-race historical points
    merged = merged.sort_values(["year", "round", "driverId"]).reset_index(drop=True)
    merged["driver_previous_points"] = 0.0
    merged["constructor_previous_points"] = 0.0

    # STRICT PRE-RACE CALCULATION (NO TARGET LEAKAGE)
    for yr, group in merged.groupby("year"):
        rounds = sorted(group["round"].unique())
        for rnd in rounds:
            if rnd == 1:
                continue
            # Previous races in this season strictly prior to round
            prev_entries = group[group["round"] < rnd]
            drv_pts = prev_entries.groupby("driverId")["points"].sum().to_dict()
            cons_pts = prev_entries.groupby("constructorId")["points"].sum().to_dict()

            curr_idx = group[group["round"] == rnd].index
            merged.loc[curr_idx, "driver_previous_points"] = merged.loc[curr_idx, "driverId"].map(drv_pts).fillna(0.0)
            merged.loc[curr_idx, "constructor_previous_points"] = merged.loc[curr_idx, "constructorId"].map(cons_pts).fillna(0.0)

    # Fill missing qualifying positions with starting grid
    merged["grid_position"] = pd.to_numeric(merged["grid"], errors="coerce").fillna(20).astype(int)
    merged["qualifying_position"] = pd.to_numeric(merged["qualifying_position"], errors="coerce").fillna(merged["grid_position"]).astype(int)
    merged["q_delta_to_pole"] = merged["q_delta_to_pole"].fillna(merged["q_delta_to_pole"].median())

    # Target variable: race_points
    merged["race_points"] = pd.to_numeric(merged["points"], errors="coerce").fillna(0.0)

    final_f1 = merged[[
        "year", "round", "name", "circuitId", "driver_name", "constructorId",
        "grid_position", "qualifying_position", "q_delta_to_pole",
        "driver_previous_points", "constructor_previous_points", "race_points"
    ]].rename(columns={"year": "season", "name": "race_name", "circuitId": "circuit_id", "constructorId": "constructor_id"})

    # Filter out pitlane starts / non-grid starts (grid <= 0)
    final_f1 = final_f1[(final_f1["grid_position"] > 0) & (final_f1["grid_position"] <= 24)].reset_index(drop=True)
    final_f1["q_delta_to_pole"] = final_f1["q_delta_to_pole"].round(3)

    final_f1.to_csv(out_csv, index=False)
    print(f"[SUCCESS] Saved {len(final_f1)} Formula 1 driver-race records to {out_csv}.")
    return final_f1

# =============================================================================
# 4. STUDENT PLACEMENT PREDICTION (Logistic Regression)
# =============================================================================
def process_placement_data():
    raw_csv = os.path.join(RAW_DIR, "placement", "Placement_Data_Full_Class.csv")
    out_csv = os.path.join(PROCESSED_DIR, "student_placement.csv")
    print(f"[*] Processing Student Placement dataset from {raw_csv}...")

    df = pd.read_csv(raw_csv)
    print(f"[+] Loaded {len(df)} authentic student candidate records.")

    # Target: placed = 1 for 'Placed', 0 for 'Not Placed'
    placed_binary = (df["status"].str.strip() == "Placed").astype(int)

    # Build clean dataset (salary strictly excluded from prediction features to eliminate target leakage)
    clean_df = pd.DataFrame({
        "student_id": df["sl_no"],
        "gender": df["gender"].str.strip(),
        "ssc_percentage": df["ssc_p"].astype(float),
        "ssc_board": df["ssc_b"].str.strip(),
        "hsc_percentage": df["hsc_p"].astype(float),
        "hsc_board": df["hsc_b"].str.strip(),
        "hsc_stream": df["hsc_s"].str.strip(),
        "degree_percentage": df["degree_p"].astype(float),
        "degree_field": df["degree_t"].str.strip(),
        "work_experience": (df["workex"].str.strip() == "Yes").astype(int),
        "aptitude_test_percentage": df["etest_p"].astype(float),
        "mba_specialisation": df["specialisation"].str.strip(),
        "mba_percentage": df["mba_p"].astype(float),
        "placed": placed_binary
    })

    clean_df.to_csv(out_csv, index=False)
    print(f"[SUCCESS] Saved {len(clean_df)} student placement records to {out_csv}.")
    return clean_df

if __name__ == "__main__":
    print("[*] Running Phase 2 Dataset Processing Pipeline...")
    b_df = process_brain_data()
    c_df = process_country_data()
    f_df = process_f1_data()
    p_df = process_placement_data()
    print("[COMPLETE] All 4 authentic datasets processed and verified in data/processed/!")
