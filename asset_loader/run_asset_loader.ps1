# Kitchen Diary Asset Loader - PowerShell Launcher
$ErrorActionPreference = "Stop"

# Change to script directory
Set-Location $PSScriptRoot

# Check Python installation
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Found $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Python is not installed or not in PATH." -ForegroundColor Red
    Write-Host "Please install Python 3.8 or later from https://www.python.org"
    Read-Host "Press Enter to exit"
    exit 1
}

# Create virtual environment if it doesn't exist
if (-not (Test-Path "venv")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& ".\venv\Scripts\Activate.ps1"

# Install dependencies
Write-Host "Checking dependencies..." -ForegroundColor Yellow
pip install -r requirements.txt -q

# Run the application
Write-Host "Starting Kitchen Diary Asset Loader..." -ForegroundColor Green
python asset_loader.py

# Deactivate on exit
deactivate
