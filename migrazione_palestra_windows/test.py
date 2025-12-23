import sys
print(f"Python: {sys.version}")

try:
    import pyodbc
    print("✓ pyodbc installato")
    print(f"  Driver disponibili: {pyodbc.drivers()}")
except ImportError:
    print("✗ pyodbc NON installato")

try:
    import mysql.connector
    print("✓ mysql-connector-python installato")
except ImportError:
    print("✗ mysql-connector-python NON installato")

print("\nTest completato!")