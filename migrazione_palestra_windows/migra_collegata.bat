@echo off
REM ============================================================
REM Script di lancio per la migrazione database palestra
REM VERSIONE WINDOWS
REM ============================================================

setlocal enabledelayedexpansion

echo ============================================================
echo        MIGRAZIONE DATABASE GESTIONE PALESTRA
echo ============================================================
echo.

REM Verifica Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [XX] Python non trovato!
    echo Installa Python da https://www.python.org/downloads/
    echo.
    pause
    exit /b 1
)

echo [OK] Python trovato

REM Verifica MySQL
mysql --version >nul 2>&1
if errorlevel 1 (
    echo [!!] MySQL client non trovato
    echo Assicurati che MySQL/MariaDB sia installato
    echo.
)

echo.
echo [!!] ATTENZIONE:
echo Questa operazione cancellera' COMPLETAMENTE il database 'gestione_palestra'
echo e reimportera' tutti i dati dal file Access.
echo.

set /p conferma="Sei sicuro di voler procedere? (SI/NO): "

if /i not "%conferma%"=="SI" (
    echo Operazione annullata.
    pause
    exit /b 0
)

echo.
echo Avvio migrazione...
echo.

REM Esegui lo script Python
python migrazione_COLLEGATA.py

if errorlevel 1 (
    echo.
    echo [XX] Errore durante la migrazione
    pause
    exit /b 1
) else (
    echo.
    echo [OK] Migrazione completata con successo!
    pause
    exit /b 0
)
