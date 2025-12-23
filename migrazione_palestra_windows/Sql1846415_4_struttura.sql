-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Host: 31.11.39.203
-- Creato il: Dic 21, 2025 alle 09:47
-- Versione del server: 8.0.43-34
-- Versione PHP: 8.0.7

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
drop database gestione_palestra;
create database gestione_palestra;

use gestione_palestra;
--

-- --------------------------------------------------------

--
-- Struttura della tabella `abbonamenti`
--

CREATE TABLE `abbonamenti` (
  `id` int NOT NULL,
  `nome` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `tipo` enum('tempo','scalare','generale') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `durata_giorni` int DEFAULT NULL,
  `ingressi` int DEFAULT NULL,
  `tipo_iscrizione` enum('I','A') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'A'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `abilitazioni`
--

CREATE TABLE `abilitazioni` (
  `id` int NOT NULL,
  `cliente_id` int NOT NULL,
  `numero_tessera` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `data_ora_generazione` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `stringa_formattata` varchar(50) COLLATE utf8mb4_general_ci NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `clienti`
--

CREATE TABLE `clienti` (
  `id` int NOT NULL,
  `cognome` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `nome` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `indirizzo` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `telefono` varchar(20) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `codice_fiscale` varchar(16) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `numero_tessera` varchar(10) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `fototessera` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `data_creazione` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `data_nascita` date NOT NULL,
  `luogo_nascita` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `citta` varchar(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `cap` varchar(10) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `provincia` varchar(2) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `note` varchar(500) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `corsi`
--

CREATE TABLE `corsi` (
  `id` int NOT NULL,
  `nome` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `descrizione` text COLLATE utf8mb4_general_ci,
  `codice_tornello` varchar(3) COLLATE utf8mb4_general_ci NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `iscrizioni`
--

CREATE TABLE `iscrizioni` (
  `id` int NOT NULL,
  `cliente_id` int NOT NULL,
  `data_iscrizione` date NOT NULL,
  `data_scadenza_iscrizione` date NOT NULL,
  `certificato_medico` tinyint(1) NOT NULL DEFAULT '0',
  `data_scadenza_certificato` date DEFAULT NULL,
  `file_certificato` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `corso_id` int DEFAULT NULL,
  `limitazioni_accesso` text COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `licenze`
--

CREATE TABLE `licenze` (
  `id` int NOT NULL,
  `chiave_licenza` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `data_attivazione` date NOT NULL,
  `data_scadenza` date NOT NULL,
  `limite_clienti` int NOT NULL DEFAULT '0',
  `stato` enum('attiva','scaduta','prova') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'prova'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `log_accessi`
--

CREATE TABLE `log_accessi` (
  `id` int NOT NULL,
  `utente_id` int NOT NULL,
  `data_accesso` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ip_address` varchar(45) COLLATE utf8mb4_general_ci NOT NULL,
  `device_name` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `browser` varchar(255) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `log_pagamenti`
--

CREATE TABLE `log_pagamenti` (
  `id` int NOT NULL,
  `pagamento_id` int NOT NULL,
  `azione` enum('inserimento','modifica','cancellazione') COLLATE utf8mb4_general_ci NOT NULL,
  `utente_id` int NOT NULL,
  `data_azione` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `dettagli` text COLLATE utf8mb4_general_ci
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `pagamenti`
--

CREATE TABLE `pagamenti` (
  `id` int NOT NULL,
  `cliente_id` int NOT NULL,
  `iscrizione_id` int DEFAULT NULL,
  `abbonamento_id` int DEFAULT NULL,
  `corso_id` int DEFAULT NULL,
  `tipo` enum('iscrizione','abbonamento') COLLATE utf8mb4_general_ci NOT NULL,
  `importo` decimal(10,2) NOT NULL,
  `data_pagamento` date NOT NULL,
  `data_scadenza` date DEFAULT NULL,
  `ingressi_pagati` int DEFAULT NULL,
  `ingressi_usufruiti` int DEFAULT '0',
  `ingressi_residui` int DEFAULT NULL,
  `utente_id` int NOT NULL,
  `note` text COLLATE utf8mb4_general_ci,
  `metodo` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `descrizione` varchar(500) COLLATE utf8mb4_general_ci NOT NULL,
  `data_creazione` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `timbrature`
--

CREATE TABLE `timbrature` (
  `id` int NOT NULL,
  `cliente_id` int NOT NULL,
  `data_ora` datetime NOT NULL,
  `tipo` enum('entrata','uscita') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'entrata',
  `corso_id` int DEFAULT NULL,
  `ingressi_residui` int DEFAULT NULL,
  `data_importazione` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `data_timbratura` date NOT NULL,
  `ora_timbratura` time NOT NULL,
  `timbratura` varchar(50) COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Stringa grezza del tornello nel formato: numero_tessera 0000 data_scadenza 0000 codice_tornello'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Struttura della tabella `utenti`
--

CREATE TABLE `utenti` (
  `id` int NOT NULL,
  `username` varchar(50) COLLATE utf8mb4_general_ci NOT NULL,
  `password` varchar(255) COLLATE utf8mb4_general_ci NOT NULL,
  `nome` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `cognome` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_general_ci NOT NULL,
  `ruolo` enum('admin','standard') COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'standard',
  `data_creazione` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `otp_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `otp_secret` varchar(64) COLLATE utf8mb4_general_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indici per le tabelle scaricate
--

--
-- Indici per le tabelle `abbonamenti`
--
ALTER TABLE `abbonamenti`
  ADD PRIMARY KEY (`id`);

--
-- Indici per le tabelle `abilitazioni`
--
ALTER TABLE `abilitazioni`
  ADD PRIMARY KEY (`id`),
  ADD KEY `cliente_id` (`cliente_id`),
  ADD KEY `data_ora_generazione` (`data_ora_generazione`),
  ADD KEY `idx_abilitazioni_stringa_formattata` (`stringa_formattata`);

--
-- Indici per le tabelle `clienti`
--
ALTER TABLE `clienti`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `numero_tessera` (`numero_tessera`),
  ADD UNIQUE KEY `codice_fiscale` (`codice_fiscale`);

--
-- Indici per le tabelle `corsi`
--
ALTER TABLE `corsi`
  ADD PRIMARY KEY (`id`);

--
-- Indici per le tabelle `iscrizioni`
--
ALTER TABLE `iscrizioni`
  ADD PRIMARY KEY (`id`),
  ADD KEY `cliente_id` (`cliente_id`),
  ADD KEY `corso_id` (`corso_id`);

--
-- Indici per le tabelle `licenze`
--
ALTER TABLE `licenze`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `chiave_licenza` (`chiave_licenza`);

--
-- Indici per le tabelle `log_accessi`
--
ALTER TABLE `log_accessi`
  ADD PRIMARY KEY (`id`),
  ADD KEY `utente_id` (`utente_id`);

--
-- Indici per le tabelle `log_pagamenti`
--
ALTER TABLE `log_pagamenti`
  ADD PRIMARY KEY (`id`),
  ADD KEY `pagamento_id` (`pagamento_id`),
  ADD KEY `utente_id` (`utente_id`);

--
-- Indici per le tabelle `pagamenti`
--
ALTER TABLE `pagamenti`
  ADD PRIMARY KEY (`id`),
  ADD KEY `cliente_id` (`cliente_id`),
  ADD KEY `abbonamento_id` (`abbonamento_id`),
  ADD KEY `corso_id` (`corso_id`),
  ADD KEY `utente_id` (`utente_id`),
  ADD KEY `fk_pagamenti_iscrizioni` (`iscrizione_id`);

--
-- Indici per le tabelle `timbrature`
--
ALTER TABLE `timbrature`
  ADD PRIMARY KEY (`id`),
  ADD KEY `cliente_id` (`cliente_id`),
  ADD KEY `corso_id` (`corso_id`),
  ADD KEY `idx_timbratura` (`timbratura`);

--
-- Indici per le tabelle `utenti`
--
ALTER TABLE `utenti`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT per le tabelle scaricate
--

--
-- AUTO_INCREMENT per la tabella `abbonamenti`
--
ALTER TABLE `abbonamenti`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `abilitazioni`
--
ALTER TABLE `abilitazioni`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `clienti`
--
ALTER TABLE `clienti`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `corsi`
--
ALTER TABLE `corsi`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `iscrizioni`
--
ALTER TABLE `iscrizioni`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `licenze`
--
ALTER TABLE `licenze`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `log_accessi`
--
ALTER TABLE `log_accessi`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `log_pagamenti`
--
ALTER TABLE `log_pagamenti`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `pagamenti`
--
ALTER TABLE `pagamenti`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `timbrature`
--
ALTER TABLE `timbrature`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT per la tabella `utenti`
--
ALTER TABLE `utenti`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- Limiti per le tabelle scaricate
--

--
-- Limiti per la tabella `abilitazioni`
--
ALTER TABLE `abilitazioni`
  ADD CONSTRAINT `abilitazioni_ibfk_1` FOREIGN KEY (`cliente_id`) REFERENCES `clienti` (`id`) ON DELETE CASCADE;

--
-- Limiti per la tabella `iscrizioni`
--
ALTER TABLE `iscrizioni`
  ADD CONSTRAINT `iscrizioni_ibfk_1` FOREIGN KEY (`cliente_id`) REFERENCES `clienti` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `iscrizioni_ibfk_2` FOREIGN KEY (`corso_id`) REFERENCES `corsi` (`id`);

--
-- Limiti per la tabella `log_accessi`
--
ALTER TABLE `log_accessi`
  ADD CONSTRAINT `fk_log_accessi_utenti` FOREIGN KEY (`utente_id`) REFERENCES `utenti` (`id`) ON DELETE CASCADE;

--
-- Limiti per la tabella `log_pagamenti`
--
ALTER TABLE `log_pagamenti`
  ADD CONSTRAINT `log_pagamenti_ibfk_1` FOREIGN KEY (`utente_id`) REFERENCES `utenti` (`id`);

--
-- Limiti per la tabella `pagamenti`
--
ALTER TABLE `pagamenti`
  ADD CONSTRAINT `fk_pagamenti_iscrizioni` FOREIGN KEY (`iscrizione_id`) REFERENCES `iscrizioni` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `pagamenti_ibfk_1` FOREIGN KEY (`cliente_id`) REFERENCES `clienti` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `pagamenti_ibfk_2` FOREIGN KEY (`abbonamento_id`) REFERENCES `abbonamenti` (`id`),
  ADD CONSTRAINT `pagamenti_ibfk_3` FOREIGN KEY (`utente_id`) REFERENCES `utenti` (`id`),
  ADD CONSTRAINT `pagamenti_ibfk_4` FOREIGN KEY (`corso_id`) REFERENCES `corsi` (`id`);

--
-- Limiti per la tabella `timbrature`
--
ALTER TABLE `timbrature`
  ADD CONSTRAINT `timbrature_ibfk_1` FOREIGN KEY (`cliente_id`) REFERENCES `clienti` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `timbrature_ibfk_2` FOREIGN KEY (`corso_id`) REFERENCES `corsi` (`id`);
COMMIT;


INSERT INTO `utenti` (`id`, `username`, `password`, `nome`, `cognome`, `email`, `ruolo`, `data_creazione`, `otp_enabled`, `otp_secret`) VALUES
(1, 'admin', '$2y$12$bsk4WmFwYsEiNSZq.hLMv.SvjvkYc.NbrzUtlzxeFREhEidCetnhW', 'Amministratore', 'Sistema', 'admin@example.com', 'admin', '2025-10-18 06:56:27', 0, NULL),
(2, 'fedeli', '$2y$12$bsk4WmFwYsEiNSZq.hLMv.SvjvkYc.NbrzUtlzxeFREhEidCetnhW', 'Massimo', 'Fedeli', 'massimo.fedeli@gmail.com', 'admin', '2025-10-18 09:02:24', 1, '4Z5M3LRS6VDRDD3WDIZLKFXY'),
(3, 'sergio', '$2y$12$wj9VoObJb5X.wzVQaddAIufGqUAyi/LO.WhDuMVnpODsoUbimmEfu', 'Sergio', 'Torquati', 'sergiotorquati@gmail.com', 'admin', '2025-10-28 05:44:20', 0, NULL),
(4, 'm.serena', '$2y$10$XqNIRJhHfeW./HKn6xAuZ.SOIDTdShreloavzfsXeRJnEITVLLMFm', 'Serena', 'Mansi', 'Serena.mansi00@gmail.com', 'standard', '2025-12-19 08:09:09', 0, NULL),
(5, 't.erika', '$2y$10$Y/T0gdeWlpOTdPL2aP1phupzZlSqsbrqfwdn0N5.C9YHCXvXtLjIW', 'Erika', 'Torquati', 'erika.torquati@gmail.com', 'standard', '2025-12-20 14:38:08', 0, NULL);


