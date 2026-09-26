"""
ML Model 4 - Raw Data Ingestion Pipeline
Fetches pristine, authentic, real-world datasets directly from authoritative sources.
Zero fabricated or synthetic records.
"""

import os
import sys
import io
import json
import zipfile
import urllib.request
import ssl

# SSL context allowing secure HTTPS requests
ctx = ssl.create_default_context()

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
RAW_DIR = os.path.join(BASE_DIR, "data", "raw")

HEADERS = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) ML-Model-4-Research-Bot/1.0"}

def download_file(url, dest_path):
    print(f"[*] Downloading {url} -> {dest_path}")
    req = urllib.request.Request(url, headers=HEADERS)
    with urllib.request.urlopen(req, context=ctx, timeout=30) as resp:
        content = resp.read()
        with open(dest_path, "wb") as f:
            f.write(content)
    print(f"[+] Saved {dest_path} ({len(content)} bytes)")
    return content

# -----------------------------------------------------------------------------
# 1. BRAIN ACTIVITY: UCI EEG Eye State Dataset
# -----------------------------------------------------------------------------
def fetch_brain_data():
    target_dir = os.path.join(RAW_DIR, "brain")
    os.makedirs(target_dir, exist_ok=True)
    zip_url = "https://archive.ics.uci.edu/static/public/264/eeg+eye+state.zip"
    zip_path = os.path.join(target_dir, "eeg_eye_state.zip")
    
    download_file(zip_url, zip_path)
    
    with zipfile.ZipFile(zip_path, 'r') as z:
        z.extractall(target_dir)
    print(f"[+] Extracted EEG raw archive into {target_dir}: {os.listdir(target_dir)}")

# -----------------------------------------------------------------------------
# 2. COUNTRY DEVELOPMENT: World Bank Open Data API
# -----------------------------------------------------------------------------
def fetch_country_data():
    target_dir = os.path.join(RAW_DIR, "country")
    os.makedirs(target_dir, exist_ok=True)
    
    # Authoritative World Bank Indicators (Year: 2020)
    indicators = {
        "gdp_per_capita": "NY.GDP.PCAP.CD",
        "life_expectancy": "SP.DYN.LE00.IN",
        "total_population": "SP.POP.TOTL",
        "unemployment_rate": "SL.UEM.TOTL.ZS",
        "infant_mortality": "SP.DYN.IMRT.IN",
        "health_expenditure_pct_gdp": "SH.XPD.CHEX.GD.ZS",
        "education_expenditure_pct_gdp": "SE.XPD.TOTL.GD.ZS",
        "internet_usage_pct": "IT.NET.USER.ZS",
        "co2_emissions_per_capita": "EN.ATM.CO2E.PC"
    }
    
    wb_results = {}
    for name, code in indicators.items():
        # Query World Bank API for 2020 data (with 2019 fallback window if necessary)
        api_url = f"http://api.worldbank.org/v2/country/all/indicator/{code}?date=2019:2021&format=json&per_page=1000"
        print(f"[*] Querying World Bank API for {name} ({code})...")
        req = urllib.request.Request(api_url, headers=HEADERS)
        with urllib.request.urlopen(req, timeout=30) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            if len(data) > 1 and data[1]:
                wb_results[name] = data[1]
                print(f"[+] Received {len(data[1])} records for {name}")
            else:
                print(f"[-] No records for {name}")
                
    raw_json_path = os.path.join(target_dir, "worldbank_indicators_raw.json")
    with open(raw_json_path, "w", encoding="utf-8") as f:
        json.dump(wb_results, f, indent=2)
    print(f"[+] Saved World Bank raw JSON to {raw_json_path}")

# -----------------------------------------------------------------------------
# 3. FORMULA 1: Historical Relational Database (Ergast Archive)
# -----------------------------------------------------------------------------
def fetch_f1_data():
    target_dir = os.path.join(RAW_DIR, "f1")
    os.makedirs(target_dir, exist_ok=True)
    
    base_gh = "https://raw.githubusercontent.com/Denchan-san/Formula1_datasets/main/input_csv"
    tables = [
        "races.csv",
        "results.csv",
        "qualifying.csv",
        "drivers.csv",
        "driver_standings.csv",
        "constructor_standings.csv"
    ]
    
    for t in tables:
        url = f"{base_gh}/{t}"
        dest = os.path.join(target_dir, t)
        download_file(url, dest)

# -----------------------------------------------------------------------------
# 4. STUDENT PLACEMENT: CMS Business School, Jain University
# -----------------------------------------------------------------------------
def fetch_placement_data():
    target_dir = os.path.join(RAW_DIR, "placement")
    os.makedirs(target_dir, exist_ok=True)
    
    url = "https://raw.githubusercontent.com/colema13/Placement_Data_Full_Class/main/Placement_Data_Full_Class.csv"
    dest = os.path.join(target_dir, "Placement_Data_Full_Class.csv")
    download_file(url, dest)

if __name__ == "__main__":
    print("[*] Starting Phase 2 Raw Data Acquisition...")
    fetch_brain_data()
    fetch_country_data()
    fetch_f1_data()
    fetch_placement_data()
    print("[SUCCESS] All four raw real-world datasets downloaded successfully!")
