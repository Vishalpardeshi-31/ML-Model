# ML Model 4 — Academic Machine Learning Platform

> *"Four Worlds. Four Machine Learning Models."*

**ML Model 4** is an interactive, production-quality academic Machine Learning research platform unifying four real-world analytical paradigms across unsupervised discovery and supervised inference:

| # | Research World | Learning Paradigm | Algorithm | Domain | Verified Real-World Source |
|---|---|---|---|---|---|
| **01** | **Brain Activity Pattern Discovery** | Unsupervised | **K-Means Clustering** | Computational Neurophysiology | [UCI ML Repository](https://archive.ics.uci.edu/dataset/264/eeg+eye+state) (EEG Eye State) |
| **02** | **Country Development Analysis** | Unsupervised | **Agglomerative Hierarchical Clustering** | Global Macroeconomics & Demographics | [World Bank WDI](https://databank.worldbank.org/source/world-development-indicators) & UN IGME |
| **03** | **Formula 1 Race Outcome Analysis** | Supervised | **Multiple Linear Regression** | Motorsport Performance Telemetry | [Ergast / Jolpica-F1 Archive](https://github.com/jolpica/jolpica-f1) (2014–2024 V6 Era) |
| **04** | **Student Placement Prediction** | Supervised | **Binomial Logistic Regression** | Higher Education & Employability | [CMS Business School](https://www.kaggle.com/datasets/benroshan/factors-affecting-campus-placement) (Jain University) |

---

## 🏛️ System Architecture

The platform is designed with a decoupled, high-throughput microservice architecture:

```
[ Browser / Single-Page Application ]
  ├── Vanilla JavaScript + Canvas Data Particles
  ├── Chart.js Visualizations
  ├── GSAP Micro-Animations
  └── Lucide Technical Iconography
           │
           ▼ (HTTP JSON)
[ Flask REST API Gateway ] (:5000)
  ├── Static Frontend Asset Server
  ├── Request Validation & Routing
  ├── Health Endpoint: GET /api/health
  └── CORS & Security Headers
           │
           ▼ (HTTP JSON REST)
[ R Plumber Microservice ] (:8000)
  ├── Zero Subprocess Overhead
  ├── Persistent In-Memory Models
  └── Statistical Execution Pipeline
           │
           ▼
[ R Machine Learning Solvers ]
  ├── kmeans() Core Solver
  ├── hclust(method = "ward.D2")
  ├── lm() Multiple Linear Regression
  └── glm(family = binomial) Logistic Regression
```

---

## 📂 Project Structure

```
ML-Model-4/
├── frontend/
│   ├── index.html            # Futuristic AI research laboratory interface
│   ├── style.css             # Glassmorphism panels, dark aesthetic, typography
│   └── script.js             # Canvas particle constellation, health telemetry, modal engine
│
├── backend/
│   ├── app.py                # Flask REST API gateway & asset server
│   └── requirements.txt      # Python dependencies (Flask, flask-cors, requests)
│
├── R/
│   ├── brain/                # K-Means clustering R scripts & Plumber endpoint
│   ├── country/              # Hierarchical clustering R scripts & Plumber endpoint
│   ├── f1/                   # Multiple Linear Regression R scripts & Plumber endpoint
│   └── placement/            # Logistic Regression R scripts & Plumber endpoint
│
├── data/
│   ├── raw/                  # Pristine raw downloads directly from public sources
│   │   ├── brain/
│   │   ├── country/
│   │   ├── f1/
│   │   └── placement/
│   │
│   ├── processed/            # Cleaned, standardized, non-synthetic datasets (Phase 2)
│   │   ├── brain_activity.csv
│   │   ├── country_development.csv
│   │   ├── f1_race_data.csv
│   │   └── student_placement.csv
│   │
│   └── data_sources.md       # Exhaustive scientific provenance specification
│
├── models/                   # Serialized model artifacts (.rds)
├── docs/                     # Academic documentation & mathematical specifications
└── README.md
```

---

## 🛡️ Strict Data Provenance Policy

This repository adheres to a strict scientific standard: **Zero fabricated, synthetic, placeholder, or artificially duplicated data.**

Every dataset is traceable to an authoritative academic, intergovernmental, or verified institutional archive:
* Complete audit specifications, citations, variable descriptions, scales, and licensing details are formally documented in [`data/data_sources.md`](file:///c:/Users/Vishal/OneDrive/Desktop/ML%20Model4/data/data_sources.md).

---

## 🚀 Running the Platform (Phase 4 Development)

### 1. Prerequisites
* **Python 3.10+**
* **R 4.3+** with packages `plumber`, `jsonlite`, `stats`, `cluster`
* Modern Web Browser (Chrome, Edge, Firefox, Safari)

### 2. Install Python Dependencies
```bash
python -m pip install -r backend/requirements.txt pytest
```

### 3. Start Both Services (Recommended Method)
You can launch both the R Plumber ML Inference Service (`:8000`) and the Flask REST API Gateway (`:5000`) with a single command:

**On Windows:**
```cmd
run_backend.bat
```
*or via Python:*
```bash
python run_backend.py
```

### 4. Starting Services Manually (Separate Terminals)

**Terminal 1 — R Plumber Microservice:**
```bash
Rscript R/run_plumber.R
```
*Initializes all four serialized `.rds` models into RAM and listens on `http://127.0.0.1:8000`.*

**Terminal 2 — Flask REST Gateway:**
```bash
python backend/app.py
```
*Gateway listens on `http://127.0.0.1:5000`, serves the Single-Page Application, validates incoming requests, and proxies predictions to R Plumber.*

### 5. Access the Frontend
Open [**http://127.0.0.1:5000**](http://127.0.0.1:5000) in your web browser. Click **"Side Report"** in the navigation header to inspect live model parameters, formulas, and accuracy metrics.

---

## 🧪 Automated Integration Testing

Run the full end-to-end integration test suite verifying that all four real R models, validation routines, error handlers, and fallback responses are operational:

```bash
python -m pytest tests/test_api.py -v
```

**Test Coverage:**
* ✅ Valid real-world predictions across all 4 ML models
* ✅ Missing feature detection & structured error returns (HTTP 400)
* ✅ Non-numerical and invalid data type rejections (HTTP 400)
* ✅ Out-of-bounds numerical and domain value checks (HTTP 400)
* ✅ R Plumber service offline handling & fault tolerance (HTTP 503)
* ✅ Read-only dataset visualization endpoints (`/api/*/data`)

---

## 📚 Technical Documentation & Reports

* 📖 [**`docs/api.md`**](docs/api.md) — Comprehensive REST API Specification (Endpoints, Request/Response JSON schemas, Validation rules).
* 📊 [**`docs/models_side_report.md`**](docs/models_side_report.md) — Models Technical Side Report (Algorithms, Metrics, Confusion Matrix, R², Silhouette).
* 🛡️ [**`docs/data_quality_report.md`**](docs/data_quality_report.md) — Data Quality Audit & Anti-Leakage Verification.
* 🧬 [**`data/data_sources.md`**](data/data_sources.md) — Scientific Data Provenance & Citations.
