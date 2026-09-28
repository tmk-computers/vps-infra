@echo off
REM ==============================================================================
REM 🚀 VPS-INFRA UNIFIED CLI WRAPPER (WINDOWS)
REM ==============================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0infra.ps1" %*
