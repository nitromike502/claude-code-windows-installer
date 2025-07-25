@echo off
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0\src\installer.ps1" %*
pause