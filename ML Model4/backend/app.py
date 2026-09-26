"""
ML Model 4 - Academic Machine Learning Platform
Backend REST API Gateway (Flask)
Connects the Single Page Frontend to the R Plumber Inference Microservice
"""

import os
import json
import requests
import pandas as pd
from flask import Flask, jsonify, send_from_directory, request
from flask_cors import CORS

# -----------------------------------------------------------------------------
# Configuration & Paths
# -----------------------------------------------------------------------------
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
FRONTEND_DIR = os.path.join(BASE_DIR, "frontend")
DATA_DIR = os.path.join(BASE_DIR, "data", "processed")
MODELS_DIR = os.path.join(BASE_DIR, "models")
R_PLUMBER_URL = os.environ.get("R_PLUMBER_URL", "http://127.0.0.1:8000")

app = Flask(__name__, static_folder=FRONTEND_DIR, static_url_path="")

# Configure CORS specifically for local development origins
CORS(app, resources={
    r"/api/*": {
        "origins": [
            "http://127.0.0.1:5000",
            "http://localhost:5000",
            "http://127.0.0.1:8000",
            "http://localhost:8000"
        ]
    }
})

# Helper to load models metadata once
METADATA_FILE = os.path.join(MODELS_DIR, "model_metadata.json")
cached_metadata = None

def get_models_metadata():
    global cached_metadata
    if cached_metadata is None and os.path.exists(METADATA_FILE):
        with open(METADATA_FILE, "r", encoding="utf-8") as f:
            cached_metadata = json.load(f)
    return cached_metadata or {"models": []}

# -----------------------------------------------------------------------------
# Error Handling Helpers
# -----------------------------------------------------------------------------
def error_response(message: str, status_code: int = 400):
    return jsonify({
        "error": True,
        "message": message
    }), status_code

def forward_to_plumber(endpoint: str, payload: dict):
    """
    Forwards a validated request payload to the R Plumber inference microservice.
    Catches connection failures, timeouts, and structured error responses.
    """
    url = f"{R_PLUMBER_URL}{endpoint}"
    try:
        resp = requests.post(url, json=payload, timeout=5)
        try:
            data = resp.json()
        except Exception:
            return error_response(f"Non-JSON response from R Plumber: {resp.text[:200]}", 502)

        if resp.status_code != 200:
            msg = data.get("message", "Inference failed in R computational engine.") if isinstance(data, dict) else str(data)
            return error_response(msg, resp.status_code)

        return jsonify(data), 200

    except requests.exceptions.ConnectionError:
        return error_response(
            "R Plumber ML microservice is unreachable at http://127.0.0.1:8000. "
            "Please ensure the R service is running via 'Rscript R/run_plumber.R'.",
            503
        )
    except requests.exceptions.Timeout:
        return error_response("R Plumber ML microservice timed out during inference execution.", 504)
    except Exception as e:
        return error_response(f"Gateway communication error: {str(e)}", 500)

# -----------------------------------------------------------------------------
# Frontend Routes
# -----------------------------------------------------------------------------
@app.route("/", methods=["GET"])
def index():
    return send_from_directory(FRONTEND_DIR, "index.html")

@app.route("/<path:path>", methods=["GET"])
def static_files(path):
    if os.path.exists(os.path.join(FRONTEND_DIR, path)):
        return send_from_directory(FRONTEND_DIR, path)
    return send_from_directory(FRONTEND_DIR, "index.html")

# -----------------------------------------------------------------------------
# System & Health Endpoints
# -----------------------------------------------------------------------------
@app.route("/api/health", methods=["GET"])
def health_check():
    """
    Comprehensive health check probing both Flask gateway and R Plumber engine.
    """
    r_status = {"status": "offline", "url": R_PLUMBER_URL}
    try:
        r_resp = requests.get(f"{R_PLUMBER_URL}/health", timeout=2)
        if r_resp.status_code == 200:
            r_status = r_resp.json()
    except Exception:
        pass

    return jsonify({
        "status": "ok",
        "project": "ML Model 4",
        "gateway": "Flask REST API",
        "r_service": r_status
    }), 200

@app.route("/api/models", methods=["GET"])
def list_models():
    """
    Returns verified model architectures, feature schemas, hyperparameters,
    and performance metrics from models/model_metadata.json.
    """
    meta = get_models_metadata()
    return jsonify(meta), 200

@app.route("/api/models/report", methods=["GET"])
def models_report():
    """
    Comprehensive computational models performance side report.
    """
    meta = get_models_metadata()
    # Also return organized by model ID for easy lookup
    models_dict = {m["id"]: m for m in meta.get("models", [])}
    return jsonify({
        "project": "ML Model 4",
        "title": "Comprehensive Model Performance Side Report",
        "models": models_dict
    }), 200

# -----------------------------------------------------------------------------
# Model 1: Brain Activity Pattern Discovery (K-Means)
# -----------------------------------------------------------------------------
@app.route("/api/brain/predict", methods=["POST"])
def brain_predict():
    data = request.get_json(silent=True)
    if not data or not isinstance(data, dict):
        return error_response("Malformed or missing JSON request body.")

    # 1. Lookup by authentic epoch_id if provided
    if "epoch_id" in data and str(data["epoch_id"]).strip():
        try:
            ep_id = int(data["epoch_id"])
            return forward_to_plumber("/brain/predict", {"epoch_id": ep_id})
        except (ValueError, TypeError):
            return error_response("epoch_id must be a valid integer.")

    required_features = [
        "delta_power", "theta_power", "alpha_power", "beta_power", "gamma_power",
        "alpha_relative", "beta_relative", "theta_beta_ratio", "occipital_alpha",
        "frontal_asymmetry", "mean_amplitude", "signal_variance", "spectral_entropy"
    ]

    missing = [f for f in required_features if f not in data]
    if missing:
        return error_response(f"Missing required EEG features: {', '.join(missing)}")

    # Validate numerical types and ranges
    clean_payload = {}
    for f in required_features:
        try:
            val = float(data[f])
        except (ValueError, TypeError):
            return error_response(f"Feature '{f}' must be a valid numerical value.")

        # Power spectral features must be non-negative
        if f in ["delta_power", "theta_power", "alpha_power", "beta_power", "gamma_power", "occipital_alpha", "signal_variance"] and val < 0:
            return error_response(f"Feature '{f}' cannot be negative.")

        if f in ["alpha_relative", "beta_relative"] and not (0.0 <= val <= 1.0):
            return error_response(f"Relative ratio '{f}' must be between 0.0 and 1.0.")

        if f == "frontal_asymmetry" and not (-1.0 <= val <= 1.0):
            return error_response("Frontal asymmetry index must be between -1.0 and 1.0.")

        clean_payload[f] = val

    return forward_to_plumber("/brain/predict", clean_payload)

# -----------------------------------------------------------------------------
# Model 2: Country Development Analysis (Hierarchical Clustering)
# -----------------------------------------------------------------------------
@app.route("/api/country/predict", methods=["POST"])
def country_predict():
    data = request.get_json(silent=True)
    if not data or not isinstance(data, dict):
        return error_response("Malformed or missing JSON request body.")

    # 1. Lookup by country code or name
    if "country_code" in data and str(data["country_code"]).strip():
        return forward_to_plumber("/country/predict", {"country_code": str(data["country_code"]).strip().upper()})
    if "country" in data and str(data["country"]).strip():
        return forward_to_plumber("/country/predict", {"country": str(data["country"]).strip()})

    # 2. Input 8 development indicators
    indicators = [
        "gdp_per_capita", "life_expectancy", "total_population",
        "unemployment_rate", "infant_mortality", "health_expenditure_pct_gdp",
        "education_expenditure_pct_gdp", "internet_usage_pct"
    ]
    missing = [ind for ind in indicators if ind not in data]
    if missing:
        return error_response(f"Missing required development indicators or country identifier: {', '.join(missing)}")

    clean_payload = {}
    for ind in indicators:
        try:
            val = float(data[ind])
        except (ValueError, TypeError):
            return error_response(f"Indicator '{ind}' must be a valid numerical value.")

        if ind in ["gdp_per_capita", "total_population"] and val <= 0:
            return error_response(f"Indicator '{ind}' must be strictly greater than 0.")

        if ind in ["unemployment_rate", "infant_mortality", "health_expenditure_pct_gdp", "education_expenditure_pct_gdp"] and val < 0:
            return error_response(f"Indicator '{ind}' cannot be negative.")

        if ind == "internet_usage_pct" and not (0.0 <= val <= 100.0):
            return error_response("Internet usage percentage must be between 0.0 and 100.0%.")

        clean_payload[ind] = val

    return forward_to_plumber("/country/predict", clean_payload)

# -----------------------------------------------------------------------------
# Model 3: Formula 1 Race Outcome Analysis (Multiple Linear Regression)
# -----------------------------------------------------------------------------
@app.route("/api/f1/predict", methods=["POST"])
def f1_predict():
    data = request.get_json(silent=True)
    if not data or not isinstance(data, dict):
        return error_response("Malformed or missing JSON request body.")

    required_fields = [
        "grid_position", "qualifying_position", "q_delta_to_pole",
        "driver_previous_points", "constructor_previous_points", "round"
    ]
    missing = [f for f in required_fields if f not in data]
    if missing:
        return error_response(f"Missing required pre-race predictors: {', '.join(missing)}")

    try:
        grid_pos = int(data["grid_position"])
        quali_pos = int(data["qualifying_position"])
        q_delta = float(data["q_delta_to_pole"])
        driver_pts = float(data["driver_previous_points"])
        const_pts = float(data["constructor_previous_points"])
        round_num = int(data["round"])
    except (ValueError, TypeError):
        return error_response("All F1 predictors must be valid numerical values.")

    if not (1 <= grid_pos <= 25):
        return error_response("Starting grid position must be between 1 and 25.")
    if not (1 <= quali_pos <= 25):
        return error_response("Qualifying position must be between 1 and 25.")
    if q_delta < 0.0:
        return error_response("Qualifying delta to pole cannot be negative.")
    if driver_pts < 0.0 or const_pts < 0.0:
        return error_response("Championship previous points cannot be negative.")
    if round_num < 1:
        return error_response("Calendar round number must be at least 1.")

    clean_payload = {
        "grid_position": grid_pos,
        "qualifying_position": quali_pos,
        "q_delta_to_pole": q_delta,
        "driver_previous_points": driver_pts,
        "constructor_previous_points": const_pts,
        "round": round_num
    }

    return forward_to_plumber("/f1/predict", clean_payload)

# -----------------------------------------------------------------------------
# Model 4: Student Placement Prediction (Logistic Regression)
# -----------------------------------------------------------------------------
@app.route("/api/placement/predict", methods=["POST"])
def placement_predict():
    data = request.get_json(silent=True)
    if not data or not isinstance(data, dict):
        return error_response("Malformed or missing JSON request body.")

    required_fields = [
        "ssc_percentage", "hsc_percentage", "degree_percentage",
        "work_experience", "aptitude_test_percentage", "mba_percentage",
        "mba_specialisation", "degree_field"
    ]
    missing = [f for f in required_fields if f not in data]
    if missing:
        return error_response(f"Missing required student profile predictors: {', '.join(missing)}")

    try:
        ssc = float(data["ssc_percentage"])
        hsc = float(data["hsc_percentage"])
        deg = float(data["degree_percentage"])
        wexp = int(data["work_experience"])
        etest = float(data["aptitude_test_percentage"])
        mba = float(data["mba_percentage"])
    except (ValueError, TypeError):
        return error_response("Academic scores and work experience must be valid numerical values.")

    for score_name, score_val in [("10th SSC", ssc), ("12th HSC", hsc), ("Degree", deg), ("Aptitude test", etest), ("MBA", mba)]:
        if not (0.0 <= score_val <= 100.0):
            return error_response(f"{score_name} percentage must be between 0.0 and 100.0%.")

    if wexp not in [0, 1]:
        return error_response("Work experience must be 0 (No prior experience) or 1 (Prior experience).")

    mba_spec = str(data["mba_specialisation"]).strip()
    deg_field = str(data["degree_field"]).strip()

    allowed_specs = ["Mkt&Fin", "Mkt&HR"]
    allowed_fields = ["Comm&Mgmt", "Sci&Tech", "Others"]

    if mba_spec not in allowed_specs:
        return error_response(f"Invalid MBA specialisation '{mba_spec}'. Allowed options: {', '.join(allowed_specs)}.")

    if deg_field not in allowed_fields:
        return error_response(f"Invalid undergraduate degree field '{deg_field}'. Allowed options: {', '.join(allowed_fields)}.")

    clean_payload = {
        "ssc_percentage": ssc,
        "hsc_percentage": hsc,
        "degree_percentage": deg,
        "work_experience": wexp,
        "aptitude_test_percentage": etest,
        "mba_percentage": mba,
        "mba_specialisation": mba_spec,
        "degree_field": deg_field
    }

    return forward_to_plumber("/placement/predict", clean_payload)

# -----------------------------------------------------------------------------
# Read-Only Dataset Visualization Endpoints
# -----------------------------------------------------------------------------
@app.route("/api/brain/data", methods=["GET"])
def brain_data():
    file_path = os.path.join(DATA_DIR, "brain_clustered.csv")
    if not os.path.exists(file_path):
        return error_response("Brain clustered dataset not found.", 404)
    df = pd.read_csv(file_path)
    cols = [
        "epoch_id", "cluster", "PCA1", "PCA2",
        "delta_power", "theta_power", "alpha_power", "beta_power", "gamma_power",
        "alpha_relative", "beta_relative", "theta_beta_ratio", "occipital_alpha",
        "frontal_asymmetry", "mean_amplitude", "signal_variance", "spectral_entropy"
    ]
    return jsonify({
        "total_records": len(df),
        "data": df[cols].to_dict(orient="records")
    }), 200

@app.route("/api/country/data", methods=["GET"])
def country_data():
    file_path = os.path.join(DATA_DIR, "country_clustered.csv")
    if not os.path.exists(file_path):
        return error_response("Country clustered dataset not found.", 404)
    df = pd.read_csv(file_path)
    cols = ["country", "country_code", "cluster", "PCA1", "PCA2", "gdp_per_capita", "life_expectancy", "infant_mortality", "internet_usage_pct"]
    return jsonify({
        "total_countries": len(df),
        "data": df[cols].to_dict(orient="records")
    }), 200

@app.route("/api/f1/data", methods=["GET"])
def f1_data():
    file_path = os.path.join(DATA_DIR, "f1_predictions.csv")
    if not os.path.exists(file_path):
        return error_response("F1 predictions dataset not found.", 404)
    df = pd.read_csv(file_path)
    if "actual_points" not in df.columns and "race_points" in df.columns:
        df["actual_points"] = df["race_points"]
    cols = ["season", "round", "race_name", "driver_name", "grid_position", "actual_points", "predicted_points", "residual"]
    return jsonify({
        "total_races": len(df),
        "data": df[cols].to_dict(orient="records")
    }), 200

@app.route("/api/placement/data", methods=["GET"])
def placement_data():
    file_path = os.path.join(DATA_DIR, "placement_predictions.csv")
    if not os.path.exists(file_path):
        return error_response("Placement predictions dataset not found.", 404)
    df = pd.read_csv(file_path)
    cols = ["student_id", "actual_placed", "predicted_probability", "predicted_class", "correct", "ssc_percentage", "degree_percentage", "work_experience"]
    return jsonify({
        "total_candidates": len(df),
        "data": df[cols].to_dict(orient="records")
    }), 200

# -----------------------------------------------------------------------------
# Application Entry Point
# -----------------------------------------------------------------------------
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    debug = os.environ.get("FLASK_DEBUG", "True").lower() in ("true", "1")
    print(f"[*] ML Model 4 Gateway running on http://127.0.0.1:{port}")
    app.run(host="0.0.0.0", port=port, debug=debug)
