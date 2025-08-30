# Fichier : load_data_to_db.py
# Ce script collecte les données et les charge dans la base de données PostgreSQL.

import psycopg2
from collecte_bj_data import get_all_bj_data # On réutilise notre collecteur de données

# --- VOS INFORMATIONS DE CONNEXION À LA BASE DE DONNÉES ---
# Remplacez ces valeurs par les informations de votre base de données Superset
DB_NAME = "votre_db_name"
DB_USER = "groupe5-bimhack"
DB_PASS = "passbimhack"
DB_HOST = "https://dataviz.internet.bj/" # ex: localhost ou une adresse IP
DB_PORT = "5432" # Port par défaut de PostgreSQL
# -------------------------------------------------------------

def insert_kpis(cursor, kpis_data):
    """Insère les indicateurs clés du jour dans la table bj_kpis."""
    sql = """
        INSERT INTO bj_kpis (
            snapshot_date, live_domain_count, live_data_status, 
            nameserver_count, ipv6_availability_percent, dnssec_status
        ) VALUES (CURRENT_DATE, %s, %s, %s, %s, %s);
    """
    try:
        cursor.execute(sql, (
            kpis_data['live_domain_count'],
            kpis_data['live_data_status'],
            kpis_data['nameserver_count'],
            kpis_data['ipv6_availability_percent'],
            kpis_data['dnssec_status']
        ))
        print("Données KPI insérées avec succès.")
    except Exception as e:
        print(f"Erreur lors de l'insertion des KPIs : {e}")

def insert_domain_history(cursor, history_data):
    """Insère ou met à jour l'historique des domaines dans la table bj_domain_history."""
    sql = """
        INSERT INTO bj_domain_history (annee, nombre_domaines, source) 
        VALUES (%s, %s, %s)
        ON CONFLICT (annee) DO UPDATE SET 
            nombre_domaines = EXCLUDED.nombre_domaines, 
            source = EXCLUDED.source;
    """
    try:
        for record in history_data:
            cursor.execute(sql, (record['annee'], record['nombre_domaines'], record['source']))
        print("Historique des domaines inséré/mis à jour avec succès.")
    except Exception as e:
        print(f"Erreur lors de l'insertion de l'historique : {e}")

def insert_nameservers(cursor, nameservers_data):
    """Insère ou met à jour les informations des serveurs de noms."""
    # On vide la table pour s'assurer qu'elle est toujours à jour
    cursor.execute("TRUNCATE TABLE bj_nameservers RESTART IDENTITY;")
    sql = """
        INSERT INTO bj_nameservers (
            hostname, ipv4_address, ipv6_address, country_code, asn_details
        ) VALUES (%s, %s, %s, %s, %s);
    """
    try:
        for record in nameservers_data:
            cursor.execute(sql, (
                record['hostname'],
                record['ipv4_address'],
                record['ipv6_address'],
                record['country_code'],
                record['asn_details']
            ))
        print("Données des serveurs de noms insérées avec succès.")
    except Exception as e:
        print(f"Erreur lors de l'insertion des serveurs de noms : {e}")


def main():
    """Fonction principale pour orchestrer la collecte et le chargement."""
    print("Démarrage de la collecte de données...")
    all_data = get_all_bj_data(for_db=True)
    
    conn = None
    try:
        # Connexion à la base de données
        conn = psycopg2.connect(
            dbname=DB_NAME, user=DB_USER, password=DB_PASS, host=DB_HOST, port=DB_PORT
        )
        cur = conn.cursor()
        
        # Insertion des données dans chaque table
        insert_kpis(cur, all_data['bj_kpis'])
        insert_domain_history(cur, all_data['bj_domain_history'])
        insert_nameservers(cur, all_data['bj_nameservers'])
        
        # Validation des transactions
        conn.commit()
        cur.close()
        
    except psycopg2.DatabaseError as e:
        print(f"Erreur de base de données : {e}")
    finally:
        if conn is not None:
            conn.close()
            print("Connexion à la base de données fermée.")

if __name__ == "__main__":
    main()