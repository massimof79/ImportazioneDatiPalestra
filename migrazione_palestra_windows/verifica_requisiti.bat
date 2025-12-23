@echo off
REM ============================================================
REM Script di verifica requisiti per migrazione database
REM VERSIONE WINDOWS
REM ============================================================

setlocal enabledelayedexpansion

echo ============================================================
echo          VERIFICA REQUISITI DI SISTEMA
echo ============================================================
echo.

set ERRORI=0

REM Verifica Python
echo [Verifica 1/5] Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo [XX] Python NON installato
    echo     Scarica da: https://www.python.org/downloads/
    set /a ERRORI+=1
) else (
    for /f "tokens=2" %%i in ('python --version') do echo [OK] Python %%i installato
)

REM Verifica pip
echo.
echo [Verifica 2/5] pip...
pip --version >nul 2>&1
if errorlevel 1 (
    echo [XX] pip NON funzionante
    echo     Prova: python -m pip --version
    set /a ERRORI+=1
) else (
    echo [OK] pip installato e funzionante
)

REM Verifica pyodbc
echo.
echo [Verifica 3/5] Libreria pyodbc...
python -c "import pyodbc" >nul 2>&1
if errorlevel 1 (
    echo [XX] pyodbc NON installato
    echo     Installa con: pip install pyodbc
    set /a ERRORI+=1
) else (
    echo [OK] pyodbc installato
    python -c "import pyodbc; drivers = pyodbc.drivers(); print('    Driver ODBC disponibili:'); [print('      -', d) for d in drivers]"
)

REM Verifica mysql-connector-python
echo.
echo [Verifica 4/5] Libreria mysql-connector-python...
python -c "import mysql.connector" >nul 2>&1
if errorlevel 1 (
    echo [XX] mysql-connector-python NON installato
    echo     Installa con: pip install mysql-connector-python
    set /a ERRORI+=1
) else (
    echo [OK] mysql-connector-python installato
)

REM Verifica MySQL
echo.
echo [Verifica 5/5] MySQL Server...
mysql --version >nul 2>&1
if errorlevel 1 (
    echo [!!] MySQL client non trovato
    echo     Assicurati che MySQL/MariaDB sia installato
    set /a ERRORI+=1
) else (
    for /f "tokens=*" %%i in ('mysql --version') do echo [OK] %%i
)

echo.
echo ============================================================

if %ERRORI% EQU 0 (
    echo [OK] TUTTI I REQUISITI SONO SODDISFATTI!
    echo.
    echo Puoi procedere con la migrazione.
    echo Esegui: migra.bat
) else (
    echo [XX] ATTENZIONE: Trovati %ERRORI% problemi
    echo.
    echo Risolvi i problemi sopra indicati prima di procedere.
    echo Consulta: INSTALLAZIONE_WINDOWS.txt
)

echo ============================================================
echo.

pause
