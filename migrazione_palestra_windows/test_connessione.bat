@echo off
REM ============================================================
REM Script di test connessione database
REM ============================================================

echo ============================================================
echo          TEST CONNESSIONE DATABASE
echo ============================================================
echo.

REM Crea script Python temporaneo
echo import sys > test_conn.py
echo import os >> test_conn.py
echo. >> test_conn.py
echo # Modifica questi valori se necessario >> test_conn.py
echo ACCESS_DB_PATH = r'C:\yuki.mdb'  # MODIFICA >> test_conn.py
echo MYSQL_HOST = 'localhost' >> test_conn.py
echo MYSQL_USER = 'root' >> test_conn.py
echo MYSQL_PASS = ''  # MODIFICA se necessario >> test_conn.py
echo. >> test_conn.py
echo print("Test 1: Connessione database Access") >> test_conn.py
echo print("-" * 50) >> test_conn.py
echo try: >> test_conn.py
echo     import pyodbc >> test_conn.py
echo     if os.path.exists(ACCESS_DB_PATH): >> test_conn.py
echo         conn_str = r'DRIVER={Microsoft Access Driver (*.mdb, *.accdb)};DBQ=' + ACCESS_DB_PATH >> test_conn.py
echo         conn = pyodbc.connect(conn_str) >> test_conn.py
echo         print("[OK] Connessione Access riuscita!") >> test_conn.py
echo         cursor = conn.cursor() >> test_conn.py
echo         tables = [table.table_name for table in cursor.tables(tableType='TABLE')] >> test_conn.py
echo         print(f"[OK] Trovate {len(tables)} tabelle") >> test_conn.py
echo         print("     Tabelle:", ', '.join(tables[:5])) >> test_conn.py
echo         conn.close() >> test_conn.py
echo     else: >> test_conn.py
echo         print(f"[XX] File non trovato: {ACCESS_DB_PATH}") >> test_conn.py
echo         print("     Modifica ACCESS_DB_PATH in questo script") >> test_conn.py
echo except Exception as e: >> test_conn.py
echo     print(f"[XX] Errore: {e}") >> test_conn.py
echo. >> test_conn.py
echo print("\nTest 2: Connessione MySQL") >> test_conn.py
echo print("-" * 50) >> test_conn.py
echo try: >> test_conn.py
echo     import mysql.connector >> test_conn.py
echo     conn = mysql.connector.connect( >> test_conn.py
echo         host=MYSQL_HOST, >> test_conn.py
echo         user=MYSQL_USER, >> test_conn.py
echo         password=MYSQL_PASS >> test_conn.py
echo     ) >> test_conn.py
echo     print("[OK] Connessione MySQL riuscita!") >> test_conn.py
echo     cursor = conn.cursor() >> test_conn.py
echo     cursor.execute("SHOW DATABASES") >> test_conn.py
echo     dbs = [db[0] for db in cursor.fetchall()] >> test_conn.py
echo     print(f"[OK] Trovati {len(dbs)} database") >> test_conn.py
echo     if 'gestione_palestra' in dbs: >> test_conn.py
echo         print("     Database 'gestione_palestra' ESISTE (sara' cancellato)") >> test_conn.py
echo     else: >> test_conn.py
echo         print("     Database 'gestione_palestra' NON esiste (sara' creato)") >> test_conn.py
echo     conn.close() >> test_conn.py
echo except Exception as e: >> test_conn.py
echo     print(f"[XX] Errore: {e}") >> test_conn.py
echo     print("     Verifica che MySQL sia in esecuzione") >> test_conn.py
echo     print("     Controlla username/password") >> test_conn.py
echo. >> test_conn.py
echo print("\n" + "=" * 50) >> test_conn.py
echo print("Test completato!") >> test_conn.py
echo print("=" * 50) >> test_conn.py

REM Esegui il test
python test_conn.py

REM Pulisci
del test_conn.py

echo.
pause
