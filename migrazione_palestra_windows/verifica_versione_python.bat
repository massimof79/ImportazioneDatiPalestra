@echo off
echo ============================================================
echo    VERIFICA VERSIONE PYTHON E DRIVER NECESSARIO
echo ============================================================
echo.

echo Versione Python:
python --version
echo.

echo Architettura Python (32-bit o 64-bit):
python -c "import struct; print(struct.calcsize('P') * 8, 'bit')"
echo.

echo ============================================================
echo Driver ODBC attualmente installati:
echo ============================================================
python -c "import pyodbc; drivers = pyodbc.drivers(); print('Driver trovati:', len(drivers)); [print('  -', d) for d in drivers]"
echo.

echo ============================================================
echo QUALE VERSIONE SCARICARE?
echo ============================================================
echo.
python -c "import struct; bit = struct.calcsize('P') * 8; print('Il tuo Python e'' a', bit, 'bit'); print(''); print('Scarica Access Database Engine', bit, 'bit da:'); print('  64-bit: https://www.microsoft.com/download/details.aspx?id=54920' if bit == 64 else '  32-bit: https://www.microsoft.com/download/details.aspx?id=13255')"
echo.

pause
