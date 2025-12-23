-- Script di verifica dopo la migrazione
-- Esegui con: mysql -u root -p gestione_palestra < verifica_migrazione.sql

USE gestione_palestra;

-- Intestazione
SELECT '============================================================' as '';
SELECT '          VERIFICA MIGRAZIONE DATABASE' as '';
SELECT '============================================================' as '';
SELECT '' as '';

-- Conteggio record per tabella
SELECT '--- CONTEGGIO RECORD PER TABELLA ---' as '';
SELECT '' as '';

SELECT 'clienti' as Tabella, COUNT(*) as 'Numero Record' FROM clienti
UNION ALL
SELECT 'pagamenti', COUNT(*) FROM pagamenti
UNION ALL
SELECT 'corsi', COUNT(*) FROM corsi
UNION ALL
SELECT 'abbonamenti', COUNT(*) FROM abbonamenti
UNION ALL
SELECT 'iscrizioni', COUNT(*) FROM iscrizioni
UNION ALL
SELECT 'utenti', COUNT(*) FROM utenti;

SELECT '' as '';

-- Verifica clienti senza numero tessera
SELECT '--- VERIFICA INTEGRITÀ ---' as '';
SELECT '' as '';

SELECT 'Clienti senza numero tessera:' as Controllo, COUNT(*) as Totale
FROM clienti 
WHERE numero_tessera IS NULL OR numero_tessera = '' OR numero_tessera = '0';

-- Verifica pagamenti senza cliente
SELECT 'Pagamenti con cliente invalido:' as Controllo, COUNT(*) as Totale
FROM pagamenti p
LEFT JOIN clienti c ON p.cliente_id = c.id
WHERE c.id IS NULL;

-- Verifica iscrizioni senza cliente
SELECT 'Iscrizioni con cliente invalido:' as Controllo, COUNT(*) as Totale
FROM iscrizioni i
LEFT JOIN clienti c ON i.cliente_id = c.id
WHERE c.id IS NULL;

SELECT '' as '';

-- Statistiche clienti
SELECT '--- STATISTICHE CLIENTI ---' as '';
SELECT '' as '';

SELECT 'Totale clienti:' as Statistica, COUNT(*) as Valore FROM clienti
UNION ALL
SELECT 'Clienti con email:', COUNT(*) FROM clienti WHERE email IS NOT NULL AND email != ''
UNION ALL
SELECT 'Clienti con telefono:', COUNT(*) FROM clienti WHERE telefono IS NOT NULL AND telefono != ''
UNION ALL
SELECT 'Clienti con indirizzo:', COUNT(*) FROM clienti WHERE indirizzo IS NOT NULL AND indirizzo != '';

SELECT '' as '';

-- Statistiche pagamenti
SELECT '--- STATISTICHE PAGAMENTI ---' as '';
SELECT '' as '';

SELECT 'Totale pagamenti:' as Statistica, COUNT(*) as Valore FROM pagamenti
UNION ALL
SELECT 'Pagamenti di tipo abbonamento:', COUNT(*) FROM pagamenti WHERE tipo = 'abbonamento'
UNION ALL
SELECT 'Pagamenti di tipo iscrizione:', COUNT(*) FROM pagamenti WHERE tipo = 'iscrizione';

SELECT '' as '';

SELECT 'Importo totale pagamenti:' as Statistica, 
       CONCAT('€ ', FORMAT(SUM(importo), 2)) as Valore 
FROM pagamenti;

SELECT '' as '';

-- Ultimi 5 clienti inseriti
SELECT '--- ULTIMI 5 CLIENTI ---' as '';
SELECT '' as '';

SELECT 
    id,
    CONCAT(cognome, ' ', nome) as 'Nome Completo',
    numero_tessera as 'Tessera',
    telefono as 'Telefono'
FROM clienti
ORDER BY id DESC
LIMIT 5;

SELECT '' as '';

-- Corsi disponibili
SELECT '--- CORSI DISPONIBILI ---' as '';
SELECT '' as '';

SELECT 
    id,
    nome as 'Nome Corso',
    codice_tornello as 'Codice'
FROM corsi
ORDER BY nome;

SELECT '' as '';

-- Tipi abbonamenti
SELECT '--- TIPI ABBONAMENTO ---' as '';
SELECT '' as '';

SELECT 
    id,
    nome as 'Nome Abbonamento',
    tipo as 'Tipo',
    COALESCE(durata_giorni, 0) as 'Durata (gg)',
    COALESCE(ingressi, 0) as 'Ingressi'
FROM abbonamenti
ORDER BY tipo, nome;

SELECT '' as '';
SELECT '============================================================' as '';
SELECT '          VERIFICA COMPLETATA' as '';
SELECT '============================================================' as '';
