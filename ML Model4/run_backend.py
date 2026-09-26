"""
ML Model 4 - Dual Backend Runner
Orchestrates both R Plumber ML Inference (:8000) and Flask REST Gateway (:5000)
Cross-platform compatible (Windows, macOS, Linux)
"""

import sys
import os
import time
import subprocess
import signal
import urllib.request
import json
import shutil

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
PLUMBER_SCRIPT = os.path.join(BASE_DIR, "R", "run_plumber.R")
FLASK_SCRIPT = os.path.join(BASE_DIR, "backend", "app.py")

def find_rscript():
    # 1. Check PATH
    r_path = shutil.which("Rscript")
    if r_path:
        return r_path

    # 2. Common Windows paths
    candidates = [
        os.path.expandvars(r"%LOCALAPPDATA%\Programs\R\bin\Rscript.exe"),
        r"C:\Program Files\R\R-4.6.1\bin\Rscript.exe",
        r"C:\Program Files\R\R-4.4.1\bin\Rscript.exe",
        r"C:\Program Files\R\R-4.3.2\bin\Rscript.exe"
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    return None

def wait_for_plumber(url="http://127.0.0.1:8000/health", timeout=15):
    print("[*] Waiting for R Plumber microservice to initialize models in RAM...")
    start = time.time()
    while time.time() - start < timeout:
        try:
            with urllib.request.urlopen(url, timeout=1) as resp:
                if resp.status == 200:
                    data = json.loads(resp.read())
                    print(f"[+] R Plumber is online! Models loaded: {data.get('models_loaded', {})}")
                    return True
        except Exception:
            time.sleep(0.5)
    return False

def main():
    print("=" * 72)
    print(" ML MODEL 4 — FULL STACK ML PLATFORM BACKEND LAUNCHER")
    print("=" * 72)

    rscript = find_rscript()
    if not rscript:
        print("[-] ERROR: Rscript not found on system PATH or standard directories.")
        print("    Please install R or ensure Rscript is added to PATH.")
        sys.exit(1)

    print(f"[+] Found Rscript binary: {rscript}")
    print(f"[+] Found Python executable: {sys.executable}")

    # Launch R Plumber process
    print("\n[*] Starting R Plumber ML Inference Service on http://127.0.0.1:8000...")
    plumber_proc = subprocess.Popen([rscript, PLUMBER_SCRIPT], cwd=BASE_DIR)

    def cleanup(sig=None, frame=None):
        print("\n[*] Shutting down ML Model 4 services...")
        if plumber_proc.poll() is None:
            plumber_proc.terminate()
            plumber_proc.wait()
        print("[+] All services halted cleanly.")
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    if not wait_for_plumber():
        print("[-] WARNING: Plumber did not respond within 15 seconds. Proceeding anyway...")

    # Launch Flask gateway
    print("\n[*] Starting Flask REST API Gateway on http://127.0.0.1:5000...")
    print("[*] Open your browser at: http://127.0.0.1:5000\n")
    try:
        subprocess.run([sys.executable, FLASK_SCRIPT], cwd=BASE_DIR)
    except KeyboardInterrupt:
        cleanup()
    finally:
        cleanup()

if __name__ == "__main__":
    main()
