"""
ML Model 4 - Integration & Validation Test Suite
Tests Flask Gateway, R Plumber Service, and ML Models End-to-End
"""

import pytest
import requests
import json

FLASK_BASE_URL = "http://127.0.0.1:5000"
PLUMBER_BASE_URL = "http://127.0.0.1:8000"


# ==============================================================================
# 1. System Health & Metadata Tests
# ==============================================================================

def test_flask_health_endpoint():
    """Verify Flask /api/health probes both Flask and R Plumber."""
    resp = requests.get(f"{FLASK_BASE_URL}/api/health", timeout=3)
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["project"] == "ML Model 4"
    assert "r_service" in data
    assert data["r_service"]["status"] == "ok"
    assert data["r_service"]["models_loaded"]["brain_kmeans"] is True
    assert data["r_service"]["models_loaded"]["country_hierarchical"] is True
    assert data["r_service"]["models_loaded"]["f1_regression"] is True
    assert data["r_service"]["models_loaded"]["placement_logistic"] is True


def test_models_metadata_endpoint():
    """Verify /api/models returns complete metadata for all 4 models."""
    resp = requests.get(f"{FLASK_BASE_URL}/api/models", timeout=3)
    assert resp.status_code == 200
    data = resp.json()
    assert "models" in data
    assert len(data["models"]) == 4
    model_ids = [m["id"] for m in data["models"]]
    assert set(model_ids) == {"brain", "country", "f1", "placement"}


# ==============================================================================
# 2. Model 1: Brain Activity Pattern Discovery (K-Means) Tests
# ==============================================================================

@pytest.fixture
def valid_brain_payload():
    return {
        "delta_power": 2.5,
        "theta_power": 1.3,
        "alpha_power": 1.6,
        "beta_power": 1.4,
        "gamma_power": 0.6,
        "alpha_relative": 0.15,
        "beta_relative": 0.14,
        "theta_beta_ratio": 1.0,
        "occipital_alpha": 1.8,
        "frontal_asymmetry": 0.05,
        "mean_amplitude": 4300.0,
        "signal_variance": 4.2,
        "spectral_entropy": 3.4
    }


def test_brain_predict_valid(valid_brain_payload):
    """Test valid Brain K-Means prediction."""
    resp = requests.post(f"{FLASK_BASE_URL}/api/brain/predict", json=valid_brain_payload)
    assert resp.status_code == 200
    data = resp.json()
    assert "cluster" in data
    assert data["cluster"] in [1, 2, 3]
    assert "cluster_name" in data
    assert "pca" in data
    assert isinstance(data["pca"]["x"], (int, float))
    assert isinstance(data["pca"]["y"], (int, float))
    assert "distances" in data
    assert len(data["distances"]) == 3


def test_brain_predict_missing_feature(valid_brain_payload):
    """Test Brain prediction with a missing feature."""
    del valid_brain_payload["alpha_power"]
    resp = requests.post(f"{FLASK_BASE_URL}/api/brain/predict", json=valid_brain_payload)
    assert resp.status_code == 400
    data = resp.json()
    assert data["error"] is True
    assert "Missing required EEG features" in data["message"]


def test_brain_predict_invalid_type(valid_brain_payload):
    """Test Brain prediction with non-numerical string input."""
    valid_brain_payload["delta_power"] = "not-a-number"
    resp = requests.post(f"{FLASK_BASE_URL}/api/brain/predict", json=valid_brain_payload)
    assert resp.status_code == 400
    data = resp.json()
    assert data["error"] is True
    assert "must be a valid numerical value" in data["message"]


def test_brain_predict_invalid_value(valid_brain_payload):
    """Test Brain prediction with negative power spectral value."""
    valid_brain_payload["delta_power"] = -5.0
    resp = requests.post(f"{FLASK_BASE_URL}/api/brain/predict", json=valid_brain_payload)
    assert resp.status_code == 400
    data = resp.json()
    assert data["error"] is True
    assert "cannot be negative" in data["message"]


def test_brain_predict_epoch_id():
    """Test Brain prediction by real epoch_id lookup."""
    resp = requests.post(f"{FLASK_BASE_URL}/api/brain/predict", json={"epoch_id": 3})
    assert resp.status_code == 200
    data = resp.json()
    assert "cluster" in data
    assert data["cluster"] in [1, 2, 3]
    assert data["epoch_id"] == 3
    assert "input_features" in data
    assert "delta_power" in data["input_features"]


def test_brain_predict_invalid_epoch_id():
    """Test Brain prediction with out-of-range epoch_id."""
    resp = requests.post(f"{FLASK_BASE_URL}/api/brain/predict", json={"epoch_id": 9999999})
    assert resp.status_code == 404
    data = resp.json()
    assert data["error"] is True



# ==============================================================================
# 3. Model 2: Country Development Analysis (Hierarchical) Tests
# ==============================================================================

def test_country_predict_by_code():
    """Test Country lookup by authentic ISO country code."""
    resp = requests.post(f"{FLASK_BASE_URL}/api/country/predict", json={"country_code": "USA"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["matched_country"] == "United States"
    assert data["cluster"] == 3
    assert "Developed" in data["tier_name"]
    assert "pca" in data


def test_country_predict_by_name():
    """Test Country lookup by country name."""
    resp = requests.post(f"{FLASK_BASE_URL}/api/country/predict", json={"country": "India"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["matched_country"] == "India"
    assert data["cluster"] in [1, 2, 3]


def test_country_predict_by_indicators():
    """Test Country prediction using raw development indicators."""
    payload = {
        "gdp_per_capita": 48000.0,
        "life_expectancy": 82.0,
        "total_population": 40000000.0,
        "unemployment_rate": 4.5,
        "infant_mortality": 2.8,
        "health_expenditure_pct_gdp": 10.2,
        "education_expenditure_pct_gdp": 5.8,
        "internet_usage_pct": 91.5
    }
    resp = requests.post(f"{FLASK_BASE_URL}/api/country/predict", json=payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data["cluster"] == 3
    assert "Developed" in data["tier_name"]
    assert "pca" in data


def test_country_predict_missing_indicator():
    """Test Country prediction with missing indicator."""
    payload = {
        "gdp_per_capita": 48000.0,
        "life_expectancy": 82.0
    }
    resp = requests.post(f"{FLASK_BASE_URL}/api/country/predict", json=payload)
    assert resp.status_code == 400
    data = resp.json()
    assert data["error"] is True
    assert "Missing required development indicators" in data["message"]


def test_country_predict_invalid_value():
    """Test Country prediction with invalid negative GDP."""
    payload = {
        "gdp_per_capita": -100.0,
        "life_expectancy": 82.0,
        "total_population": 40000000.0,
        "unemployment_rate": 4.5,
        "infant_mortality": 2.8,
        "health_expenditure_pct_gdp": 10.2,
        "education_expenditure_pct_gdp": 5.8,
        "internet_usage_pct": 91.5
    }
    resp = requests.post(f"{FLASK_BASE_URL}/api/country/predict", json=payload)
    assert resp.status_code == 400
    data = resp.json()
    assert data["error"] is True
    assert "strictly greater than 0" in data["message"]


# ==============================================================================
# 4. Model 3: Formula 1 Race Outcome Analysis (Regression) Tests
# ==============================================================================

@pytest.fixture
def valid_f1_payload():
    return {
        "grid_position": 3,
        "qualifying_position": 3,
        "q_delta_to_pole": 0.22,
        "driver_previous_points": 85.0,
        "constructor_previous_points": 140.0,
        "round": 6
    }


def test_f1_predict_valid(valid_f1_payload):
    """Test valid F1 linear regression points prediction."""
    resp = requests.post(f"{FLASK_BASE_URL}/api/f1/predict", json=valid_f1_payload)
    assert resp.status_code == 200
    data = resp.json()
    assert "predicted_points" in data
    assert isinstance(data["predicted_points"], (int, float))
    assert data["predicted_points"] >= 0.0
    assert "confidence_interval" in data
    assert "lower" in data["confidence_interval"]
    assert "upper" in data["confidence_interval"]
    assert data["confidence_interval"]["lower"] <= data["confidence_interval"]["upper"]


def test_f1_predict_missing_feature(valid_f1_payload):
    """Test F1 prediction with missing grid_position."""
    del valid_f1_payload["grid_position"]
    resp = requests.post(f"{FLASK_BASE_URL}/api/f1/predict", json=valid_f1_payload)
    assert resp.status_code == 400
    data = resp.json()
    assert data["error"] is True
    assert "Missing required pre-race predictors" in data["message"]


def test_f1_predict_invalid_value(valid_f1_payload):
    """Test F1 prediction with out-of-bounds grid position."""
    valid_f1_payload["grid_position"] = 35  # Max 25
    resp = requests.post(f"{FLASK_BASE_URL}/api/f1/predict", json=valid_f1_payload)
    assert resp.status_code == 400
    data = resp.json()
    assert data["error"] is True
    assert "between 1 and 25" in data["message"]


# ==============================================================================
# 5. Model 4: Student Placement Prediction (Logistic) Tests
# ==============================================================================

@pytest.fixture
def valid_placement_payload():
    return {
        "ssc_percentage": 74.0,
        "hsc_percentage": 70.0,
        "degree_percentage": 68.0,
        "work_experience": 1,
        "aptitude_test_percentage": 78.0,
        "mba_percentage": 62.0,
        "mba_specialisation": "Mkt&Fin",
        "degree_field": "Comm&Mgmt"
    }


def test_placement_predict_valid(valid_placement_payload):
    """Test valid Placement logistic regression prediction."""
    resp = requests.post(f"{FLASK_BASE_URL}/api/placement/predict", json=valid_placement_payload)
    assert resp.status_code == 200
    data = resp.json()
    assert "probability" in data
    assert 0.0 <= data["probability"] <= 1.0
    assert "prediction" in data
    assert data["prediction"] in [0, 1]
    assert data["label"] in ["Placed", "Not Placed"]
    assert data["threshold"] == 0.5


def test_placement_predict_missing_feature(valid_placement_payload):
    """Test Placement prediction with missing ssc_percentage."""
    del valid_placement_payload["ssc_percentage"]
    resp = requests.post(f"{FLASK_BASE_URL}/api/placement/predict", json=valid_placement_payload)
    assert resp.status_code == 400
    data = resp.json()
    assert data["error"] is True
    assert "Missing required student profile predictors" in data["message"]


def test_placement_predict_invalid_percentage(valid_placement_payload):
    """Test Placement prediction with invalid percentage > 100."""
    valid_placement_payload["hsc_percentage"] = 125.0
    resp = requests.post(f"{FLASK_BASE_URL}/api/placement/predict", json=valid_placement_payload)
    assert resp.status_code == 400
    data = resp.json()
    assert data["error"] is True
    assert "between 0.0 and 100.0%" in data["message"]


def test_placement_predict_invalid_category(valid_placement_payload):
    """Test Placement prediction with unrecognized degree field."""
    valid_placement_payload["degree_field"] = "Music&Arts"
    resp = requests.post(f"{FLASK_BASE_URL}/api/placement/predict", json=valid_placement_payload)
    assert resp.status_code == 400
    data = resp.json()
    assert data["error"] is True
    assert "Invalid undergraduate degree field" in data["message"]


# ==============================================================================
# 6. Service Offline & Gateway Fault Tolerance
# ==============================================================================

def test_service_unavailable_handling():
    """Verify Flask returns clean 503 error if R Plumber endpoint is unreachable."""
    from backend.app import forward_to_plumber
    import backend.app as flask_app

    original_url = flask_app.R_PLUMBER_URL
    try:
        # Point to an unused local port
        flask_app.R_PLUMBER_URL = "http://127.0.0.1:9999"
        with flask_app.app.test_request_context():
            resp, code = forward_to_plumber("/brain/predict", {})
            assert code == 503
            data = resp.get_json()
            assert data["error"] is True
            assert "unreachable" in data["message"]
    finally:
        flask_app.R_PLUMBER_URL = original_url


# ==============================================================================
# 7. Visualization Data Endpoints Tests
# ==============================================================================

def test_data_endpoints():
    """Test all 4 read-only visualization data endpoints."""
    # Brain
    r = requests.get(f"{FLASK_BASE_URL}/api/brain/data")
    assert r.status_code == 200
    assert r.json()["total_records"] == 233

    # Country
    r = requests.get(f"{FLASK_BASE_URL}/api/country/data")
    assert r.status_code == 200
    assert r.json()["total_countries"] == 168

    # F1
    r = requests.get(f"{FLASK_BASE_URL}/api/f1/data")
    assert r.status_code == 200
    assert r.json()["total_races"] == 662

    # Placement
    r = requests.get(f"{FLASK_BASE_URL}/api/placement/data")
    assert r.status_code == 200
    assert r.json()["total_candidates"] == 44
