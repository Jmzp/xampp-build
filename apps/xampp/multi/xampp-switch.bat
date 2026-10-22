@echo off
rem Switches the active PHP or MariaDB version, see xampp-switch.ps1
rem Usage: xampp-switch php 8.3 ^| xampp-switch mysql 11.8 ^| xampp-switch list ^| xampp-switch
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0xampp-switch.ps1" %*
exit /b %ERRORLEVEL%
