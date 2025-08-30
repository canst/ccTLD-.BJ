-- Ce script crée les tables et insère toutes les données actuelles du projet .BJ

-- Supprime les tables si elles existent déjà pour garantir un départ à neuf.
-- ATTENTION : Ceci effacera les données existantes dans ces tables.

--CREATE DATABASE bimhackdb_groupe5;
--\connect bimhackdb_groupe5;
--\c bimhackdb_groupe5;

DROP TABLE IF EXISTS bj_kpis, bj_domain_history, bj_nameservers;

-------------------------------------------
-- SECTION 1 : CRÉATION DES TABLES
-------------------------------------------

-- Table pour stocker les indicateurs clés quotidiens ou périodiques
CREATE TABLE IF NOT EXISTS bj_kpis (
    id SERIAL PRIMARY KEY,
    snapshot_date DATE NOT NULL DEFAULT CURRENT_DATE,
    live_domain_count INTEGER,
    live_data_status VARCHAR(50),
    nameserver_count INTEGER,
    ipv6_availability_percent REAL,
    dnssec_status VARCHAR(50)
);

COMMENT ON TABLE bj_kpis IS 'Instantanés des indicateurs clés pour le ccTLD .BJ.';

-- Table pour stocker l'historique officiel du nombre de domaines
CREATE TABLE IF NOT EXISTS bj_domain_history (
    annee INTEGER PRIMARY KEY,
    nombre_domaines INTEGER NOT NULL,
    source VARCHAR(255)
);

COMMENT ON TABLE bj_domain_history IS 'Données officielles et sourcées de l''évolution du nombre de domaines .BJ.';

-- Table pour stocker les informations sur les serveurs de noms (NS)
CREATE TABLE IF NOT EXISTS bj_nameservers (
    id SERIAL PRIMARY KEY,
    last_updated_date DATE NOT NULL DEFAULT CURRENT_DATE,
    hostname VARCHAR(255) UNIQUE NOT NULL,
    ipv4_address VARCHAR(45),
    ipv6_address VARCHAR(45),
    country_code VARCHAR(10),
    asn_details TEXT
);

COMMENT ON TABLE bj_nameservers IS 'Informations techniques et de localisation des serveurs de noms du .BJ.';

-------------------------------------------
-- SECTION 2 : INSERTION DES DONNÉES
-------------------------------------------

-- Insertion des indicateurs clés actuels
INSERT INTO bj_kpis (snapshot_date, live_domain_count, live_data_status, nameserver_count, ipv6_availability_percent, dnssec_status)
VALUES
(CURRENT_DATE, 5902, 'estimation', 5, 60.0, 'Activé');

-- Insertion de l'historique officiel des domaines
-- Utilise ON CONFLICT pour éviter les erreurs si une année existe déjà (met à jour les données)
INSERT INTO bj_domain_history (annee, nombre_domaines, source)
VALUES
(2019, 1624, 'Rapport Annuel ARCEP 2019'),
(2020, 1766, 'Rapport Annuel ARCEP 2020'),
(2021, 2690, 'Rapport Annuel ARCEP 2021'),
(2022, 3005, 'Rapport Annuel ARCEP 2022'),
(2023, 3447, 'Rapport Annuel ARCEP 2023'),
(2024, 3382, 'Rapport Annuel ARCEP 2024')
ON CONFLICT (annee) DO UPDATE SET
    nombre_domaines = EXCLUDED.nombre_domaines,
    source = EXCLUDED.source;

-- Insertion des informations sur les serveurs de noms
-- Utilise ON CONFLICT pour mettre à jour les entrées si un hostname existe déjà
INSERT INTO bj_nameservers (hostname, ipv4_address, ipv6_address, country_code, asn_details)
VALUES
('ns-bj.afrinic.net', '196.216.168.33', '2001:43f8:120::33', 'ZA', 'AS37177 (African Network Information Center - (AfriNIC) Ltd)'),
('ns-bj.nic.fr', '194.0.9.1', '2001:678:c::1', 'FR', 'AS197 (RIPE Network Coordination Centre)'),
('ns1.nic.bj', '154.65.28.218', 'N/A', 'BJ', 'AS327976 (JENY SAS)'),
('ns2.nic.bj', '41.85.191.2', 'N/A', 'BJ', 'AS327976 (JENY SAS)'),
('pch.nic.bj', '204.61.216.125', '2001:500:14:6125:ad::1', 'US', 'AS42 (WoodyNet, Inc.)')
ON CONFLICT (hostname) DO UPDATE SET
    ipv4_address = EXCLUDED.ipv4_address,
    ipv6_address = EXCLUDED.ipv6_address,
    country_code = EXCLUDED.country_code,
    asn_details = EXCLUDED.asn_details,
    last_updated_date = CURRENT_DATE;

-- Fin du script
SELECT 'Base de données créée et remplie avec succès !' AS status;