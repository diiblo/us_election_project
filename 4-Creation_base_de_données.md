# Création de la base de donnée : Charger le fichier CSV dans PostgreSQL

---

#### Étape 1 : Télécharger l'image aa8y/postgres-dataset:dellstore
Exécutez la commande suivante pour télécharger et lancer la base de données PostgreSQL dellstore :

```bash
docker run -itd --net=pyspark-cluster -p 5432:5432 --name pg-ds-dellstore aa8y/postgres-dataset:dellstore
```

**NB :** si le port est déjà utilisé, cf : [PB_port_utilise.md](./PB_port_utilise.md)


#### Étape 2 : Télécharger le repo de dBangos
Ouvrir votre interpreteur de commande et entrez :
```bash
git clone https://github.com/dBangos/US-Election-Results-2024
```


#### Étape 3 : Copier le fichier dans le conteneur
Dans le repertoire télécharger (`US-Election-Results-2024`), ouvrez votre interpreteur de commande et entrez :
```bash
docker cp data.csv pg-ds-dellstore:/tmp/data.csv
```

#### Étape 4 : Importer dans PostgreSQL

Connectez-vous et créez la base et la table :

```bash
docker exec -it pg-ds-dellstore psql -d dellstore
```

Dans PostgreSQL (`psql`), exécutez les commandes suivantes :

```sql
-- Créer une nouvelle base de données
CREATE DATABASE us_election_db;
```

```sql
-- Passer à la base de données
\c us_election_db;
```

```sql
-- Créer une table
CREATE TABLE election_data (
    id INT,
    State VARCHAR(255),
    County VARCHAR(255),
    Trump REAL,
    Harris REAL
);
```

```sql
-- Importer le fichier CSV
\COPY election_data (State, County, Trump, Harris) FROM '/tmp/data.csv' WITH CSV HEADER;
```

```sql
-- Vérifier le contenu
SELECT * FROM election_data LIMIT 10;
```
