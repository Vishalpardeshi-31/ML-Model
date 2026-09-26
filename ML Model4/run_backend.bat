@echo off
REM ==============================================================================
REM ML Model 4 — Development Backend Launcher (Windows)
REM Runs both R Plumber (:8000) and Flask (:5000) concurrently
REM ==============================================================================

echo [*] Launching ML Model 4 Platform Backend...
python run_backend.py
pause
