# Data Provenance & Real-World Sources Specification

**Project:** ML Model 4 — Academic Machine Learning Platform  
**Version:** Phase 2 Complete (Data Collection, Preprocessing & Quality Certification)  
**Date Accessed & Processed:** September 2026  
**Strict Policy:** Zero synthetic, fabricated, simulated, or duplicated data. Every dataset is traceable to verified peer-reviewed scientific repositories, official international statistical organizations, or authentic institutional archives.

---

## 1. Brain Activity Pattern Discovery

### Identification & Source Metadata
* **Source Name:** EEG Eye State Dataset
* **Source Organization:** Baden-Württemberg Cooperative State University (DHBW), Stuttgart, Germany & UCI Machine Learning Repository
* **Principal Investigators / Curators:** Oliver Roesler, David Balderas
* **Source URL:** [https://archive.ics.uci.edu/dataset/264/eeg+eye+state](https://archive.ics.uci.edu/dataset/264/eeg+eye+state)
* **Digital Object Identifier (DOI):** [10.24432/C57G7J](https://doi.org/10.24432/C57G7J)
* **Date Accessed:** September 2026
* **Source Nature:** Primary raw scientific laboratory recording
* **License / Usage:** Creative Commons Attribution 4.0 International (CC BY 4.0)

### Description & Equipment
Continuous 117-second electroencephalographic (EEG) time-series recordings captured via an Emotiv EPOC Neuroheadset operating at a sampling rate of 128 Hz. Electrodes are positioned according to the standard International 10-20 system:
`AF3`, `F7`, `F3`, `FC5`, `T7`, `P7`, `O1`, `O2`, `P8`, `T8`, `FC6`, `F4`, `F8`, `AF4`.

### Variables Obtained
* 14 continuous EEG electrode channels (microvolts $\mu V$)
* `eyeDetection`: Binary ground truth ocular state (0 = Eyes Open, 1 = Eyes Closed) verified via synchronized high-speed video frames

### Dataset Scale
* **Raw Records:** 14,980 time-series samples (128 Hz, 117s)
* **Final Processed Records:** 233 windowed spectral epochs (1-second windows, 50% overlap)
* **Missing Values:** 0 (0.0%)
* **Duplicate Rows:** 0 (0.0%)

### Transformation & Feature Engineering Performed
* Rejected 4 non-physiological sensor disconnection spikes outside $[3000\,\mu V, 6000\,\mu V]$.
* Segmented clean continuous signal into 1.0-second epochs (128 samples per epoch with 64 samples step / 50% overlap).
* Computed Welch power spectral density via Discrete Fourier Transform ($FFT$):
  - `delta_power` (0.5–4.0 Hz)
  - `theta_power` (4.0–8.0 Hz)
  - `alpha_power` (8.0–13.0 Hz)
  - `beta_power` (13.0–30.0 Hz)
  - `gamma_power` (30.0–45.0 Hz)
  - `alpha_relative` & `beta_relative`
  - `theta_beta_ratio` (cognitive arousal indicator)
  - `occipital_alpha` (bilateral visual cortex O1/O2 alpha)
  - `frontal_asymmetry` ($(F4 - F3)/(F4 + F3)$)
  - `mean_amplitude`, `signal_variance`, `spectral_entropy`
* Script: `R/brain/prepare_brain_data.R` (and `data/process_datasets.py`)
* Output: `data/processed/brain_activity.csv`

---

## 2. Country Development Analysis

### Identification & Source Metadata
* **Source Name:** World Development Indicators (WDI) Database
* **Source Organization:** The World Bank Group (with UN IGME, WHO, and UNESCO)
* **Source URL:** [https://databank.worldbank.org/source/world-development-indicators](https://databank.worldbank.org/source/world-development-indicators)
* **Direct API Endpoint:** `http://api.worldbank.org/v2/country/all/indicator/`
* **Date Accessed:** September 2026
* **Source Nature:** Primary intergovernmental statistical compilation
* **License / Usage:** Creative Commons Attribution 4.0 International (CC BY 4.0) — World Bank Open Data Terms

### Description & Scope
Harmonized socioeconomic, demographic, healthcare, and educational indicators compiled from officially recognized national accounts, central banks, and United Nations specialized agencies.

### Variables Obtained
* `gdp_per_capita`: Gross Domestic Product per capita in current US Dollars (World Bank WDI `NY.GDP.PCAP.CD`)
* `life_expectancy`: Average life expectancy at birth in years (`SP.DYN.LE00.IN`)
* `total_population`: Total sovereign population count (`SP.POP.TOTL`)
* `unemployment_rate`: Total unemployment as % of total labor force (`SL.UEM.TOTL.ZS`)
* `infant_mortality`: Infant mortality rate per 1,000 live births (`SP.DYN.IMRT.IN`)
* `health_expenditure_pct_gdp`: Current healthcare expenditure as % of GDP (`SH.XPD.CHEX.GD.ZS`)
* `education_expenditure_pct_gdp`: Total government education expenditure as % of GDP (`SE.XPD.TOTL.GD.ZS`)
* `internet_usage_pct`: Percentage of individuals using the Internet (`IT.NET.USER.ZS`)

### Dataset Scale
* **Raw Records:** 795 entries across 260 geopolitical entities per indicator
* **Final Processed Records:** 168 sovereign nations (Target Year: 2020)
* **Missing Values:** 0 (0.0%)
* **Duplicate Rows:** 0 (0.0%)

### Transformation & Cleaning Performed
* Filtered out 50+ World Bank regional/income group aggregates (`WLD`, `ARB`, `EUU`, `EAS`, `LCN`, `SSA`, etc.).
* Standardized to a uniform international census year ($2020$).
* Merged indicators by ISO 3166-1 alpha-3 nation codes.
* Script: `R/country/prepare_country_data.R` (and `data/process_datasets.py`)
* Output: `data/processed/country_development.csv`

---

## 3. Formula 1 Race Outcome Analysis

### Identification & Source Metadata
* **Source Name:** Historical Formula 1 Championship Relational Database (Ergast Archive)
* **Source Organization:** Ergast Developer API (Chris Hermansen) / Jolpica-F1 Open Source Project / FIA Official Timing
* **Source URL:** [https://github.com/jolpica/jolpica-f1](https://github.com/jolpica/jolpica-f1) / [https://ergast.com/mrd/](https://ergast.com/mrd/)
* **Date Accessed:** September 2026
* **Source Nature:** Relational historical database (derived from official FIA timing data)
* **License / Usage:** Open Database License (ODbL) / CC BY-NC-SA 3.0

### Description & Tables
Comprehensive relational database documenting all official World Championship Grand Prix events:
* `races.csv`: 1,101 Grand Prix events
* `results.csv`: 26,080 driver race classification entries
* `qualifying.csv`: 9,815 qualifying session lap times
* `drivers.csv`: Driver biographical records
* `constructor_standings.csv` & `driver_standings.csv`: Cumulative standings

### Variables Obtained & Engineered
* Predictors (STRICTLY PRE-RACE):
  - `season`: Championship year (2014–2023 modern era)
  - `round`: Grand Prix round number
  - `circuit_id`: Track identifier
  - `grid_position`: Official starting grid position ($1 \dots 22$)
  - `qualifying_position`: Official qualifying rank
  - `q_delta_to_pole`: Lap time difference in seconds between driver's best qualifying time and pole position
  - `driver_previous_points`: Cumulative points scored by driver in the season strictly in rounds $< \text{current round}$
  - `constructor_previous_points`: Cumulative constructor points in the season strictly in rounds $< \text{current round}$
* Target:
  - `race_points`: Official championship points awarded in the Grand Prix ($[0, 50]$)

### Dataset Scale
* **Raw Records:** 26,080 driver race entries
* **Final Processed Records:** 3,890 driver-race entries (2014–2023 Turbo Hybrid Era)
* **Missing Values:** 0 (0.0%)
* **Duplicate Rows:** 0 (0.0%)

### Transformation & Target Leakage Prevention
* Filtered to the 2014–2023 Turbo Hybrid Era (ensuring consistent qualifying format and points allocation).
* Excluded non-grid starts (`grid <= 0`).
* **Strict Anti-Leakage Protocol:** Pre-race points are computed exclusively from rounds prior to the current race. Post-race telemetry (race laps, in-race fastest lap, finish status) was completely excluded.
* Script: `R/f1/prepare_f1_data.R` (and `data/process_datasets.py`)
* Output: `data/processed/f1_race_data.csv`

---

## 4. Student Placement Prediction

### Identification & Source Metadata
* **Source Name:** Campus Recruitment Academic & Placement Dataset
* **Source Organization:** CMS Business School, Jain University, Bangalore, Karnataka, India
* **Curator / Contributor:** Ben Roshan D & Dr. Dhimant Ganatra
* **Source URL:** [https://www.kaggle.com/datasets/benroshan/factors-affecting-campus-placement](https://www.kaggle.com/datasets/benroshan/factors-affecting-campus-placement)
* **Academic Reference:** Evaluated in published literature (*MDPI Applied Sciences*, 2021; *IJACSA*, 2022)
* **Date Accessed:** September 2026
* **Source Nature:** Primary institutional student placement registry
* **License / Usage:** CC0: Public Domain / Open Academic Educational Access

### Description & Cohort
Authentic academic cohort database containing multi-tier grade percentages, degree specialization, prior work experience, and campus recruitment placement status for 215 students.

### Variables Obtained
* `student_id`: Unique serial candidate key (`1` to `215`)
* `gender`: Biological sex ('M', 'F')
* `ssc_percentage`: Secondary school 10th grade score percentage
* `ssc_board`: 10th board of examination ('Central', 'Others')
* `hsc_percentage`: Higher secondary 12th grade score percentage
* `hsc_board`: 12th board of examination ('Central', 'Others')
* `hsc_stream`: 12th academic stream ('Commerce', 'Science', 'Arts')
* `degree_percentage`: Undergraduate degree score percentage
* `degree_field`: Degree academic track ('Sci&Tech', 'Comm&Mgmt', 'Others')
* `work_experience`: Verified prior corporate work experience (1 = Yes, 0 = No)
* `aptitude_test_percentage`: Employability test score percentage
* `mba_specialisation`: MBA specialization track ('Mkt&Fin', 'Mkt&HR')
* `mba_percentage`: MBA score percentage
* `placed`: **Binary Classification Target** (1 = Placed [148 candidates, 68.84%], 0 = Not Placed [67 candidates, 31.16%])

### Dataset Scale
* **Raw Records:** 215 students
* **Final Processed Records:** 215 students (100% authentic, zero synthetic augmentation)
* **Missing Values:** 0 (0.0%)
* **Duplicate Rows:** 0 (0.0%)

### Transformation & Target Leakage Prevention
* Standardized variable names and whitespace.
* Mapped `status` to binary integer `placed` $\in \{0, 1\}$.
* **Target Leakage Elimination:** The raw column `salary` was **strictly eliminated**. Including `salary` would artificially leak placement status since unplaced students have NA salaries.
* Script: `R/placement/prepare_placement_data.R` (and `data/process_datasets.py`)
* Output: `data/processed/student_placement.csv`

---

## 5. Summary of Processed Data Assets

```
data/
├── raw/
│   ├── brain/
│   │   ├── EEG Eye State.arff               [1.7 MB, 14,980 rows]
│   │   └── eeg_eye_state.zip
│   ├── country/
│   │   └── worldbank_indicators_raw.json    [795 items x 8 indicators]
│   ├── f1/
│   │   ├── races.csv                        [1,101 races]
│   │   ├── results.csv                      [26,080 results]
│   │   ├── qualifying.csv                   [9,815 qualifying entries]
│   │   ├── drivers.csv                      [857 drivers]
│   │   ├── driver_standings.csv             [33,902 standings records]
│   │   └── constructor_standings.csv        [12,941 standings records]
│   └── placement/
│       └── Placement_Data_Full_Class.csv    [215 students]
│
├── processed/
│   ├── brain_activity.csv                   [233 rows x 15 cols, 0 missing]
│   ├── country_development.csv              [168 rows x 11 cols, 0 missing]
│   ├── f1_race_data.csv                     [3,890 rows x 12 cols, 0 missing]
│   └── student_placement.csv                [215 rows x 14 cols, 0 missing]
│
├── acquire_raw_data.py
├── process_datasets.py
├── validate_datasets.py
└── data_sources.md
```
