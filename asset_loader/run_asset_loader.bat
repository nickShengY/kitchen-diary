@echo off
title Kitchen Diary Asset Loader
cd /d "%~dp0"

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo Python is not installed or not in PATH.
    echo Please install Python 3.8 or later from https://www.python.org
    pause
    exit /b 1
)

REM Check if virtual environment exists
if not exist "venv" (
    echo Creating virtual environment...
    python -m venv venv
)

REM Activate virtual environment
call venv\Scripts\activate.bat

REM Install/update dependencies
echo Checking dependencies...
pip install -r requirements.txt -q

REM Run the application
echo Starting Kitchen Diary Asset Loader...
python asset_loader.py

REM Deactivate on exit
deactivate
