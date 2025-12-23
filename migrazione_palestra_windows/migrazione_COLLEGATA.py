#!/usr/bin/env python3
"""
Script per la migrazione SOLO DEI DATI dal vecchio database Access
al nuovo database MySQL (gestione_palestra)

VERSIONE CON COLLEGAMENTO ISCRIZIONI-PAGAMENTI

QUESTO SCRIPT ASSUME CHE LO SCHEMA SIA GIÀ STATO IMPORTATO!

Autore: Massimo
Data: Dicembre 2025
"""

import pyodbc
import mysql.connector
from datetime import datetime
import sys
import os

# Configurazione database MySQL
DB_CONFIG = {
    'host': 'localhost',
    'user': 'root',
    'password': '',  # Modifica se necessario
    'database': 'gestione_palestra'
}

# Path al file Access (modifica questo percorso)
ACCESS_DB_PATH = r'C:\yuki.mdb'  # MODIFICA QUESTO PATH


def stampa_messaggio(messaggio, tipo='INFO'):
    """Stampa messaggi formattati"""
    prefissi = {
        'INFO': '[OK]',
        'WARN': '[!!]',
        'ERROR': '[XX]',
        'STEP': '[>>]'
    }
    print(f"{prefissi.get(tipo, '[--]')} {messaggio}")


def trova_driver_access():
    """Trova il driver ODBC Access disponibile"""
    drivers = pyodbc.drivers()
    
    driver_preferiti = [
        'Microsoft Access Driver (*.mdb, *.accdb)',
        'Microsoft Access Driver (*.mdb)',
        'Driver do Microsoft Access (*.mdb)',
    ]
    
    for driver in driver_preferiti:
        if driver in drivers:
            return driver
    
    for driver in drivers:
        if 'access' in driver.lower() or 'mdb' in driver.lower():
            return driver
    
    return None


def connetti_access(db_path):
    """Crea connessione al database Access"""
    driver = trova_driver_access()
    
    if not driver:
        stampa_messaggio("PROBLEMA: Driver Microsoft Access non trovato!", 'ERROR')
        return None
    
    try:
        conn_str = f'DRIVER={{{driver}}};DBQ={db_path};'
        return pyodbc.connect(conn_str)
    except pyodbc.Error as e:
        stampa_messaggio(f"Errore connessione Access: {e}", 'ERROR')
        return None


def verifica_schema_mysql(mysql_cursor):
    """Verifica che lo schema sia già stato importato"""
    stampa_messaggio("Verifica schema database...", 'STEP')
    
    mysql_cursor.execute("SHOW TABLES")
    tabelle = mysql_cursor.fetchall()
    num_tabelle = len(tabelle)
    
    if num_tabelle == 0:
        stampa_messaggio("ERRORE: Nessuna tabella trovata!", 'ERROR')
        stampa_messaggio("", 'ERROR')
        stampa_messaggio("DEVI IMPORTARE LO SCHEMA PRIMA!", 'ERROR')
        stampa_messaggio("", 'INFO')
        stampa_messaggio("Metodo 1 - Da riga di comando:", 'INFO')
        stampa_messaggio("  mysql -u root -p < gestione_palestra.sql", 'INFO')
        stampa_messaggio("", 'INFO')
        stampa_messaggio("Metodo 2 - Con phpMyAdmin:", 'INFO')
        stampa_messaggio("  1. Apri http://localhost/phpmyadmin", 'INFO')
        stampa_messaggio("  2. Seleziona 'gestione_palestra'", 'INFO')
        stampa_messaggio("  3. Clicca 'Importa'", 'INFO')
        stampa_messaggio("  4. Seleziona gestione_palestra.sql", 'INFO')
        stampa_messaggio("  5. Clicca 'Esegui'", 'INFO')
        return False
    
    stampa_messaggio(f"Trovate {num_tabelle} tabelle - Schema OK!", 'INFO')
    
    # Mostra le tabelle
    print("  Tabelle trovate:")
    for tabella in tabelle:
        print(f"    - {tabella[0]}")
    
    return True


def leggi_tabella_access(conn, nome_tabella):
    """Legge tutti i record da una tabella Access"""
    try:
        cursor = conn.cursor()
        cursor.execute(f"SELECT * FROM [{nome_tabella}]")
        
        columns = [column[0] for column in cursor.description]
        
        records = []
        for row in cursor.fetchall():
            record = {}
            for i, col in enumerate(columns):
                record[col] = row[i]
            records.append(record)
        
        return records
    except pyodbc.Error as e:
        stampa_messaggio(f"Errore lettura tabella {nome_tabella}: {e}", 'ERROR')
        return []


def converti_data_italiana(data_str):
    """Converte data dal formato italiano gg/mm/aaaa a yyyy-mm-dd"""
    if not data_str or data_str.strip() == '':
        return None
    try:
        parti = data_str.strip().split('/')
        if len(parti) == 3:
            return f"{parti[2]}-{parti[1]:0>2}-{parti[0]:0>2}"
    except:
        pass
    return None


def converti_data_access(data_value):
    """Converte data dal formato Access/datetime a yyyy-mm-dd"""
    if not data_value:
        return None
    
    try:
        if isinstance(data_value, datetime):
            return data_value.strftime("%Y-%m-%d")
        
        if isinstance(data_value, str):
            if '/' in data_value:
                return converti_data_italiana(data_value)
            
            dt = datetime.strptime(data_value.strip(), "%Y-%m-%d %H:%M:%S")
            return dt.strftime("%Y-%m-%d")
    except:
        pass
    
    return None


def pulisci_stringa(valore):
    """Pulisce e restituisce una stringa, gestendo valori nulli"""
    if valore is None or valore == '':
        return None
    return str(valore).strip()


def pulisci_numero(valore, default=0):
    """Converte un valore in numero, gestendo valori nulli"""
    if valore is None or valore == '':
        return default
    try:
        return int(valore)
    except:
        try:
            return float(valore)
        except:
            return default


def formatta_nome_proprio(valore):
    """Formatta nome/cognome: prima lettera maiuscola, resto minuscolo"""
    if not valore or valore == '':
        return None
    
    # Converte in stringa e rimuove spazi extra
    testo = str(valore).strip()
    
    # Applica title case (ogni parola inizia con maiuscola)
    # Gestisce correttamente nomi composti come "De Luca", "Maria Teresa"
    testo_formattato = testo.title()
    
    return testo_formattato


def migra_clienti(access_conn, mysql_cursor):
    """Migra i dati dalla tabella Anagrafica alla tabella clienti"""
    stampa_messaggio("Migrazione clienti (Anagrafica -> clienti)...", 'STEP')
    
    anagrafica = leggi_tabella_access(access_conn, 'Anagrafica')
    count = 0
    errori = 0
    
    for record in anagrafica:
        try:
            id_orig = pulisci_numero(record.get('ID'))
            cognome = formatta_nome_proprio(record.get('Cognome')) or 'Sconosciuto'
            nome = formatta_nome_proprio(record.get('Nome')) or 'Sconosciuto'
            cf = pulisci_stringa(record.get('CodFiscale'))
            indirizzo = pulisci_stringa(record.get('Indirizzo'))
            tel_fisso = pulisci_stringa(record.get('TelFisso'))
            tel_mobile = pulisci_stringa(record.get('TelMobile'))
            telefono = tel_mobile or tel_fisso
            tessera = pulisci_numero(record.get('Tessera'), 0)
            note = pulisci_stringa(record.get('Note'))
            email = pulisci_stringa(record.get('email'))
            
            if tessera == 0:
                tessera = id_orig
            
            query = """
                INSERT INTO clienti 
                (id, cognome, nome, codice_fiscale, indirizzo, telefono, 
                 numero_tessera, email, note, data_nascita)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            data_nascita = '1980-01-01'
            
            mysql_cursor.execute(query, (
                id_orig, cognome, nome, cf, indirizzo, telefono,
                str(tessera), email, note, data_nascita
            ))
            count += 1
            
        except mysql.connector.Error as e:
            errori += 1
            if errori <= 5:
                stampa_messaggio(f"Errore cliente ID {record.get('ID')}: {e}", 'WARN')
            continue
    
    if errori > 5:
        stampa_messaggio(f"... e altri {errori - 5} errori", 'WARN')
    
    stampa_messaggio(f"{count} clienti migrati ({errori} errori)", 'INFO')
    return count


def migra_corsi(access_conn, mysql_cursor):
    """Migra i dati dalla tabella Discipline alla tabella corsi"""
    stampa_messaggio("Migrazione corsi (Discipline -> corsi)...", 'STEP')
    
    discipline = leggi_tabella_access(access_conn, 'Discipline')
    count = 0
    
    for record in discipline:
        try:
            id_orig = pulisci_numero(record.get('ID'))
            nome = pulisci_stringa(record.get('Nome')) or 'Corso Sconosciuto'
            descrizione = pulisci_stringa(record.get('Descrizione'))
            
            if nome.startswith('NO-'):
                continue
            
            query = """
                INSERT INTO corsi (id, nome, descrizione, codice_tornello)
                VALUES (%s, %s, %s, %s)
            """
            
            mysql_cursor.execute(query, (id_orig, nome, descrizione, '001'))
            count += 1
            
        except mysql.connector.Error as e:
            stampa_messaggio(f"Errore corso ID {record.get('ID')}: {e}", 'WARN')
            continue
    
    stampa_messaggio(f"{count} corsi migrati", 'INFO')
    return count


def migra_abbonamenti(access_conn, mysql_cursor):
    """Migra i dati dalla tabella TipiAbbonamento alla tabella abbonamenti"""
    stampa_messaggio("Migrazione abbonamenti (TipiAbbonamento -> abbonamenti)...", 'STEP')
    
    tipi_abb = leggi_tabella_access(access_conn, 'TipiAbbonamento')
    count = 0
    
    durate_standard = {
        'mensile': 30,
        'trimestrale': 90,
        'semestrale': 180,
        'annuale': 365,
        'biannuale': 730,
        '7 mesi': 210,
        '9 mesi': 270
    }
    
    for record in tipi_abb:
        try:
            id_orig = pulisci_numero(record.get('ID'))
            descrizione = pulisci_stringa(record.get('Descrizione'))
            tipo_cod = pulisci_stringa(record.get('Tipo'))
            
            if not descrizione:
                continue
            
            # Determina il tipo di abbonamento (scalare o tempo)
            tipo = 'scalare' if tipo_cod == 'S' else 'tempo'
            durata_giorni = None
            ingressi = None
            
            # Determina il tipo di iscrizione (I=generale, A=attività)
            # Se nel database Access c'è un indicatore, usalo, altrimenti determina dalla descrizione
            tipo_iscrizione = 'A'  # Default: attività
            
            # Se la descrizione contiene "iscrizione" ed è di tipo tempo, è iscrizione generale
            desc_lower = descrizione.lower()
            if 'iscrizione' in desc_lower and tipo == 'tempo':
                tipo_iscrizione = 'I'
            
            if tipo == 'tempo':
                for chiave, giorni in durate_standard.items():
                    if chiave in desc_lower:
                        durata_giorni = giorni
                        break
                
                if durata_giorni is None:
                    durata_giorni = 30
            else:
                ingressi = 10
            
            query = """
                INSERT INTO abbonamenti (id, nome, tipo, durata_giorni, ingressi, tipo_iscrizione)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            
            mysql_cursor.execute(query, (id_orig, descrizione, tipo, durata_giorni, ingressi, tipo_iscrizione))
            count += 1
            
        except mysql.connector.Error as e:
            stampa_messaggio(f"Errore abbonamento ID {record.get('ID')}: {e}", 'WARN')
            continue
    
    stampa_messaggio(f"{count} abbonamenti migrati", 'INFO')
    return count


def migra_iscrizioni(access_conn, mysql_cursor):
    """
    Migra le iscrizioni generali dalla tabella Anagrafica.
    Crea iscrizioni di tipo GENERALE (senza corso specifico) per ogni cliente.
    """
    stampa_messaggio("Migrazione iscrizioni generali (Anagrafica -> iscrizioni)...", 'STEP')
    
    anagrafica = leggi_tabella_access(access_conn, 'Anagrafica')
    count = 0
    
    # Mappa per tenere traccia delle iscrizioni create: cliente_id -> iscrizione_id
    mappa_iscrizioni_generali = {}
    
    for record in anagrafica:
        try:
            cliente_id = pulisci_numero(record.get('ID'))
            
            # Verifica che il cliente esista
            mysql_cursor.execute("SELECT id FROM clienti WHERE id = %s", (cliente_id,))
            if not mysql_cursor.fetchone():
                continue
            
            # Recupera la data di scadenza iscrizione dal database Access
            scadenza_str = pulisci_stringa(record.get('ScadenzaIscrizione'))
            data_scadenza = converti_data_italiana(scadenza_str)
            
            if not data_scadenza:
                # Se non c'è data scadenza, salta questa iscrizione
                continue
            
            # Calcola la data di inizio iscrizione (1 anno prima della scadenza)
            try:
                dt_scadenza = datetime.strptime(data_scadenza, "%Y-%m-%d")
                dt_iscrizione = dt_scadenza.replace(year=dt_scadenza.year - 1)
                data_iscrizione = dt_iscrizione.strftime("%Y-%m-%d")
            except:
                data_iscrizione = '2020-01-01'
            
            # Certificato medico
            certificato = pulisci_numero(record.get('Certificato'), 0)
            data_scad_cert = data_scadenza if certificato else None
            
            # Crea iscrizione GENERALE (senza corso_id)
            query = """
                INSERT INTO iscrizioni 
                (cliente_id, data_iscrizione, data_scadenza_iscrizione, 
                 certificato_medico, data_scadenza_certificato, corso_id)
                VALUES (%s, %s, %s, %s, %s, %s)
            """
            
            mysql_cursor.execute(query, (
                cliente_id, data_iscrizione, data_scadenza,
                certificato, data_scad_cert, None  # corso_id = NULL per iscrizione generale
            ))
            
            # Recupera l'ID dell'iscrizione appena creata
            iscrizione_id = mysql_cursor.lastrowid
            mappa_iscrizioni_generali[cliente_id] = iscrizione_id
            
            count += 1
            
        except mysql.connector.Error as e:
            stampa_messaggio(f"Errore iscrizione cliente {record.get('ID')}: {e}", 'WARN')
            continue
    
    stampa_messaggio(f"{count} iscrizioni generali migrate", 'INFO')
    
    # Salva la mappa per uso successivo
    return count, mappa_iscrizioni_generali


def migra_pagamenti_e_iscrizioni_corsi(access_conn, mysql_cursor, mappa_iscrizioni_generali, utente_id):
    """
    Migra i pagamenti e crea le iscrizioni ai corsi.
    RELAZIONE 1:1 - Ogni pagamento ha la sua iscrizione dedicata.
    """
    stampa_messaggio("Migrazione pagamenti e iscrizioni (1:1)...", 'STEP')
    
    pagamenti_old = leggi_tabella_access(access_conn, 'Pagamenti')
    count_pagamenti = 0
    count_iscrizioni_corsi = 0
    errori = 0
    
    for record in pagamenti_old:
        try:
            id_orig = pulisci_numero(record.get('ID'))
            cliente_id = pulisci_numero(record.get('IdPersona'))
            abbonamento_id = pulisci_numero(record.get('idAbbonamento'))
            corso_id = pulisci_numero(record.get('idDisciplina'))
            
            # Verifica che il cliente esista
            mysql_cursor.execute("SELECT id FROM clienti WHERE id = %s", (cliente_id,))
            if not mysql_cursor.fetchone():
                continue
            
            # Recupera info sul pagamento
            data_pagamento = converti_data_access(record.get('DataPagamento'))
            data_inizio = converti_data_access(record.get('DataInizioVal'))
            data_fine = converti_data_access(record.get('DataFineVal'))
            
            if not data_pagamento:
                data_pagamento = '2020-01-01'
            
            importo = pulisci_numero(record.get('Importo'), 0)
            ingressi_pagati = pulisci_numero(record.get('AccessiPagati'))
            ingressi_residui = pulisci_numero(record.get('AccessiResidui'))
            ingressi_usufruiti = ingressi_pagati - ingressi_residui if ingressi_pagati else 0
            
            tipo_abb = pulisci_stringa(record.get('TipoAbbonamento'))
            note = pulisci_stringa(record.get('Note'))
            metodo = 'Contanti'
            
            # Determina il tipo di iscrizione dall'abbonamento
            tipo_iscrizione = None
            if abbonamento_id:
                mysql_cursor.execute(
                    "SELECT tipo_iscrizione FROM abbonamenti WHERE id = %s", 
                    (abbonamento_id,)
                )
                result = mysql_cursor.fetchone()
                if result:
                    tipo_iscrizione = result[0]
            
            # Se non troviamo il tipo, usiamo il campo TipoAbbonamento del database Access
            if not tipo_iscrizione:
                tipo_iscrizione = 'I' if tipo_abb == 'I' else 'A'
            
            # Determina l'ID dell'iscrizione da collegare
            iscrizione_id = None
            
            if tipo_iscrizione == 'I':
                # Pagamento per iscrizione GENERALE
                # Usa l'iscrizione generale del cliente (già creata)
                iscrizione_id = mappa_iscrizioni_generali.get(cliente_id)
                tipo = 'iscrizione'
                descrizione = "Pagamento iscrizione generale"
                
            else:
                # Pagamento per iscrizione ad ATTIVITÀ (corso)
                # CREA SEMPRE UNA NUOVA ISCRIZIONE PER OGNI PAGAMENTO (1:1)
                
                if corso_id and data_inizio and data_fine:
                    # Verifica che il corso esista
                    mysql_cursor.execute("SELECT id FROM corsi WHERE id = %s", (corso_id,))
                    if mysql_cursor.fetchone():
                        # Crea NUOVA iscrizione al corso per questo pagamento
                        query_isc = """
                            INSERT INTO iscrizioni 
                            (cliente_id, data_iscrizione, data_scadenza_iscrizione, 
                             certificato_medico, data_scadenza_certificato, corso_id)
                            VALUES (%s, %s, %s, %s, %s, %s)
                        """
                        
                        mysql_cursor.execute(query_isc, (
                            cliente_id, data_inizio, data_fine,
                            0, None, corso_id
                        ))
                        
                        # Recupera l'ID della nuova iscrizione
                        iscrizione_id = mysql_cursor.lastrowid
                        count_iscrizioni_corsi += 1
                
                tipo = 'abbonamento'
                descrizione = f"Pagamento abbonamento corso"
            
            # Crea il pagamento con collegamento all'iscrizione
            query = """
                INSERT INTO pagamenti 
                (id, cliente_id, abbonamento_id, corso_id, iscrizione_id, tipo, importo, 
                 data_pagamento, data_scadenza, ingressi_pagati, ingressi_usufruiti, 
                 ingressi_residui, utente_id, note, metodo, descrizione, data_creazione)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            
            mysql_cursor.execute(query, (
                id_orig, cliente_id, abbonamento_id, corso_id, iscrizione_id, tipo, importo,
                data_pagamento, data_fine, ingressi_pagati, ingressi_usufruiti,
                ingressi_residui, utente_id, note, metodo, descrizione, data_pagamento
            ))
            count_pagamenti += 1
            
        except mysql.connector.Error as e:
            errori += 1
            if errori <= 5:
                stampa_messaggio(f"Errore pagamento ID {record.get('ID')}: {e}", 'WARN')
            continue
    
    if errori > 5:
        stampa_messaggio(f"... e altri {errori - 5} errori", 'WARN')
    
    stampa_messaggio(f"{count_pagamenti} pagamenti migrati ({errori} errori)", 'INFO')
    stampa_messaggio(f"{count_iscrizioni_corsi} iscrizioni a corsi create (1:1)", 'INFO')
    
    return count_pagamenti + count_iscrizioni_corsi


def crea_utente_admin(mysql_conn, mysql_cursor):
    """Crea un utente admin di default con ID=1 e restituisce l'ID"""
    try:
        # Prima verifica se esiste già un utente admin
        mysql_cursor.execute("SELECT id FROM utenti WHERE username = 'admin' OR id = 1")
        result = mysql_cursor.fetchone()
        if result:
            utente_id = result[0]
            stampa_messaggio(f"Utente admin già esistente (ID={utente_id})", 'INFO')
            return utente_id
        
        # Disabilita temporaneamente auto_increment per forzare ID=1
        try:
            # Prova a inserire con ID=1 esplicito
            query = """
                INSERT INTO utenti (id, username, password, nome, ruolo, attivo)
                VALUES (1, 'admin', 'admin123', 'Amministratore', 'admin', 1)
            """
            mysql_cursor.execute(query)
            mysql_conn.commit()  # Commit immediato
            stampa_messaggio("Utente admin creato (ID=1)", 'INFO')
            return 1
        except mysql.connector.Error as e1:
            stampa_messaggio(f"Impossibile creare con ID=1: {e1}", 'WARN')
            # Se fallisce, prova senza specificare l'ID
            try:
                query = """
                    INSERT INTO utenti (username, password, nome, ruolo, attivo)
                    VALUES ('admin', 'admin123', 'Amministratore', 'admin', 1)
                """
                mysql_cursor.execute(query)
                mysql_conn.commit()  # Commit immediato
                utente_id = mysql_cursor.lastrowid
                stampa_messaggio(f"Utente admin creato (ID={utente_id})", 'INFO')
                return utente_id
            except mysql.connector.Error as e2:
                stampa_messaggio(f"Errore creazione admin: {e2}", 'ERROR')
                stampa_messaggio("Uso ID=1 di default (potrebbe causare errori)", 'WARN')
                return 1
                
    except Exception as e:
        stampa_messaggio(f"Errore generico creazione admin: {e}", 'ERROR')
        return 1


def stampa_statistiche_finali(mysql_cursor):
    """Stampa statistiche finali sulla migrazione"""
    print()
    print("=" * 60)
    stampa_messaggio("STATISTICHE FINALI", 'STEP')
    print("=" * 60)
    
    try:
        # Conta clienti
        mysql_cursor.execute("SELECT COUNT(*) FROM clienti")
        num_clienti = mysql_cursor.fetchone()[0]
        print(f"  Clienti totali: {num_clienti}")
        
        # Conta corsi
        mysql_cursor.execute("SELECT COUNT(*) FROM corsi")
        num_corsi = mysql_cursor.fetchone()[0]
        print(f"  Corsi totali: {num_corsi}")
        
        # Conta abbonamenti
        mysql_cursor.execute("SELECT COUNT(*) FROM abbonamenti")
        num_abbonamenti = mysql_cursor.fetchone()[0]
        print(f"  Tipi abbonamento: {num_abbonamenti}")
        
        # Conta abbonamenti per tipo iscrizione
        mysql_cursor.execute("SELECT COUNT(*) FROM abbonamenti WHERE tipo_iscrizione = 'I'")
        num_abb_generale = mysql_cursor.fetchone()[0]
        mysql_cursor.execute("SELECT COUNT(*) FROM abbonamenti WHERE tipo_iscrizione = 'A'")
        num_abb_attivita = mysql_cursor.fetchone()[0]
        print(f"    - Iscrizioni generali: {num_abb_generale}")
        print(f"    - Iscrizioni attività: {num_abb_attivita}")
        
        # Conta iscrizioni
        mysql_cursor.execute("SELECT COUNT(*) FROM iscrizioni")
        num_iscrizioni = mysql_cursor.fetchone()[0]
        print(f"  Iscrizioni totali: {num_iscrizioni}")
        
        # Conta iscrizioni generali vs corsi
        mysql_cursor.execute("SELECT COUNT(*) FROM iscrizioni WHERE corso_id IS NULL")
        num_isc_generali = mysql_cursor.fetchone()[0]
        mysql_cursor.execute("SELECT COUNT(*) FROM iscrizioni WHERE corso_id IS NOT NULL")
        num_isc_corsi = mysql_cursor.fetchone()[0]
        print(f"    - Iscrizioni generali: {num_isc_generali}")
        print(f"    - Iscrizioni a corsi: {num_isc_corsi}")
        
        # Conta pagamenti
        mysql_cursor.execute("SELECT COUNT(*) FROM pagamenti")
        num_pagamenti = mysql_cursor.fetchone()[0]
        print(f"  Pagamenti totali: {num_pagamenti}")
        
        # Conta pagamenti collegati a iscrizioni
        mysql_cursor.execute("SELECT COUNT(*) FROM pagamenti WHERE iscrizione_id IS NOT NULL")
        num_pag_collegati = mysql_cursor.fetchone()[0]
        mysql_cursor.execute("SELECT COUNT(*) FROM pagamenti WHERE iscrizione_id IS NULL")
        num_pag_non_collegati = mysql_cursor.fetchone()[0]
        print(f"    - Collegati a iscrizioni: {num_pag_collegati}")
        print(f"    - Non collegati: {num_pag_non_collegati}")
        
        print("=" * 60)
        
    except mysql.connector.Error as e:
        stampa_messaggio(f"Errore nel calcolo statistiche: {e}", 'WARN')


def main():
    """Funzione principale"""
    print("=" * 60)
    print("MIGRAZIONE DATI - GESTIONE PALESTRA")
    print("CON COLLEGAMENTO ISCRIZIONI-PAGAMENTI")
    print("=" * 60)
    print()
    
    # Verifica esistenza file Access
    if not os.path.exists(ACCESS_DB_PATH):
        stampa_messaggio(f"File Access non trovato: {ACCESS_DB_PATH}", 'ERROR')
        stampa_messaggio("Modifica la variabile ACCESS_DB_PATH nello script", 'INFO')
        input("\nPremi INVIO per uscire...")
        return 1
    
    # Connessione Access
    stampa_messaggio("Connessione al database Access...", 'STEP')
    access_conn = connetti_access(ACCESS_DB_PATH)
    if not access_conn:
        input("\nPremi INVIO per uscire...")
        return 1
    stampa_messaggio("Connesso al database Access", 'INFO')
    print()
    
    try:
        # Connessione MySQL
        stampa_messaggio("Connessione al database MySQL...", 'STEP')
        mysql_conn = mysql.connector.connect(
            host=DB_CONFIG['host'],
            user=DB_CONFIG['user'],
            password=DB_CONFIG['password'],
            database=DB_CONFIG['database']
        )
        mysql_cursor = mysql_conn.cursor()
        stampa_messaggio("Connesso al database MySQL", 'INFO')
        print()
        
        # Verifica schema
        if not verifica_schema_mysql(mysql_cursor):
            mysql_cursor.close()
            mysql_conn.close()
            access_conn.close()
            input("\nPremi INVIO per uscire...")
            return 1
        
        print()
        
        # Crea utente admin PRIMA DI TUTTO e recupera l'ID
        utente_id = crea_utente_admin(mysql_conn, mysql_cursor)
        
        # Verifica che l'utente esista effettivamente
        mysql_cursor.execute("SELECT id, username FROM utenti WHERE id = %s", (utente_id,))
        result = mysql_cursor.fetchone()
        if result:
            stampa_messaggio(f"Utente verificato: ID={result[0]}, Username={result[1]}", 'INFO')
        else:
            stampa_messaggio(f"ATTENZIONE: Utente ID={utente_id} non trovato!", 'WARN')
        
        print()
        
        # Migrazione dati
        totale = 0
        
        # 1. Clienti
        totale += migra_clienti(access_conn, mysql_cursor)
        mysql_conn.commit()
        print()
        
        # 2. Corsi
        totale += migra_corsi(access_conn, mysql_cursor)
        mysql_conn.commit()
        print()
        
        # 3. Abbonamenti (con tipo_iscrizione)
        totale += migra_abbonamenti(access_conn, mysql_cursor)
        mysql_conn.commit()
        print()
        
        # 4. Iscrizioni generali (dalla tabella Anagrafica)
        count_isc, mappa_iscrizioni_generali = migra_iscrizioni(access_conn, mysql_cursor)
        totale += count_isc
        mysql_conn.commit()
        print()
        
        # 5. Pagamenti e iscrizioni ai corsi (collegati tra loro)
        totale += migra_pagamenti_e_iscrizioni_corsi(access_conn, mysql_cursor, mappa_iscrizioni_generali, utente_id)
        mysql_conn.commit()
        print()
        
        # Statistiche finali
        stampa_statistiche_finali(mysql_cursor)
        
        print()
        stampa_messaggio(f"MIGRAZIONE COMPLETATA! Record totali migrati: {totale}", 'INFO')
        print()
        
        mysql_cursor.close()
        mysql_conn.close()
        access_conn.close()
        
        input("\nPremi INVIO per uscire...")
        return 0
        
    except mysql.connector.Error as e:
        stampa_messaggio(f"Errore MySQL: {e}", 'ERROR')
        input("\nPremi INVIO per uscire...")
        return 1
    except Exception as e:
        stampa_messaggio(f"Errore generale: {e}", 'ERROR')
        import traceback
        traceback.print_exc()
        input("\nPremi INVIO per uscire...")
        return 1


if __name__ == '__main__':
    sys.exit(main())
