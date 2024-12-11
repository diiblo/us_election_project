# Configuration de Jupyter et traitement

---

### Étape 1. Configuration de la SparkSession dans Jupyter
C'est la première étape pour connecter Jupyter à votre cluster Spark. Cette configuration permet à Spark de gérer le traitement distribué.

#### Code :
```python
from pyspark.sql import SparkSession
from pyspark.sql import functions as F

# Configuration de la SparkSession pour se connecter au cluster
spark = SparkSession.builder \
    .master("spark://pyspark-master:7077") \
    .appName("MySparkApp") \
    .config("spark.executor.memory", "1g") \
    .config("spark.jars", "/usr/local/spark/jars/postgresql-42.6.0.jar") \
    .getOrCreate()
```

---

 
#### Étape 2. Lire les données depuis PostgreSQL dans PySpark :
Connectez Spark à PostgreSQL pour lire les données dans un DataFrame Spark.

#### Code :
```python
# Charger la table PostgreSQL dans PySpark
df_election = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://pg-ds-dellstore:5432/us_election_db") \
    .option("dbtable", "election_data") \
    .option("user", "postgres") \
    .option("password", "postgres") \
    .load()

df_electionf.show()  # Vérifier que les données sont bien chargées
```
---

### Étape 3. Effectuer le traitement dans Spark
Effectuez votre traitement (Regroupez les résultats par État pour obtenir les scores moyens de Trump et Harris.).

**NB :** Installer ces dépendences pour éviter des erreur dans le terminal de Jupiter:
 ```bash
    pip install psycopg2-binary
    pip install kafka-python
```

#### Code :
```python

import pandas as pd
from sqlalchemy import create_engine
# Charger la table PostgreSQL dans PySpark
df_election = spark.read \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://pg-ds-dellstore:5432/us_election_db") \
    .option("dbtable", "election_data") \
    .option("user", "postgres") \
    .option("password", "postgres") \
    .load()

# Filtrer les IDs pairs pour le traitement batch
df_batch = df_election.filter(F.col("id") % 2 == 0)

# Paramètres de connexion PostgreSQL
user = "postgres"
password = "postgres"
host = "pg-ds-dellstore"
port = "5432"
database = "us_election_db"

# Créer un moteur SQLAlchemy pour PostgreSQL
engine = create_engine(f'postgresql+psycopg2://{user}:{password}@{host}:{port}/{database}')

# 1. Charger les données PostgreSQL dans un DataFrame
query = "SELECT * FROM election_data WHERE MOD(id, 2) != 0;"  # Filtrer les IDs impairs directement dans la requête
df = pd.read_sql_query(query, engine)

# 2. Sauvegarder les données en CSV
csv_file = "/tmp/election_stream.csv"
df.to_csv(csv_file, index=False)
print(f"Fichier CSV généré : {csv_file}")
# Affichage des résultats pour vérifier
#df_batch.show()

#df_election.show()  # Vérifier que les données sont bien chargées

```
---

```python
# Afficher les données pour vérifier le chargement
#df_election.show()

# 1. Ajouter une colonne "score_difference" au niveau des comtés
df_with_diff = df_batch.withColumn(
    "score_difference",
    F.abs(F.col("Trump") - F.col("Harris"))
)

# 2. Agréger les scores par État
df_state_aggregation = df_with_diff.groupBy("State").agg(
    F.sum("Trump").alias("total_trump"),
    F.sum("Harris").alias("total_harris")
)

# 3. Déterminer le candidat gagnant par État
df_state_with_leader = df_state_aggregation.withColumn(
    "leading_candidate",
    F.when(F.col("total_trump") > F.col("total_harris"), "Trump").otherwise("Harris")
)

# 4. Joindre les données agrégées par État au DataFrame initial
df_final = df_with_diff.join(
    df_state_with_leader,
    on="State",
    how="left"
)

# Vérification des données finales
#df_final.select(
#    "State", "County", "Trump", "Harris", 
#    "score_difference", "total_trump", 
#    "total_harris", "leading_candidate"
#).show()

#df_final.select(
#    "id", "County"
#).show()

# 5. Sauvegarder les données enrichies dans PostgreSQL
df_final.write \
    .format("jdbc") \
    .option("url", "jdbc:postgresql://pg-ds-dellstore:5432/us_election_db") \
    .option("dbtable", "public.election_data_enriched") \
    .option("user", "postgres") \
    .option("password", "postgres") \
    .option("driver", "org.postgresql.Driver") \
    .mode("overwrite") \
    .save()
```
---

```python
#Gestion du producer
from kafka import KafkaProducer
import time
import csv
import json

producer = KafkaProducer(
    bootstrap_servers=['kafka:29092'],
    value_serializer=lambda v: json.dumps(v).encode('utf-8')
)

# Lecture du fichier CSV
with open('/tmp/election_stream.csv', 'r') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
        # Envoi de chaque ligne à Kafka
        producer.send('election_stream', row)  # Envoi au topic Kafka
        print(f"Envoyé : {row}")
        time.sleep(2)  # Pause pour simuler un flux continu
```
---

```python
#Gestion du Consumer
from kafka import KafkaConsumer
import psycopg2
import json

# Configurer le consommateur Kafka
consumer = KafkaConsumer(
    'election_stream',
    bootstrap_servers=['kafka:29092'],
    auto_offset_reset='earliest',
    enable_auto_commit=True,
    value_deserializer=lambda x: json.loads(x.decode('utf-8'))
)

# Connexion à la base PostgreSQL
conn = psycopg2.connect(
    database="us_election_db",
    user="postgres",
    password="postgres",
    host="pg-ds-dellstore",
    port="5432"
)
cursor = conn.cursor()

# Stocker les données agrégées en mémoire pour mise à jour
state_aggregation = {}

# Traitement des messages reçus
for message in consumer:
    data = message.value
    print(f"Reçu : {data}")
    
    # Calculer la différence de score
    score_difference = abs(float(data['trump']) - float(data['harris']))
    
    # Mettre à jour l'agrégation des scores par État
    state = data['state']
    if state not in state_aggregation:
        state_aggregation[state] = {"total_trump": 0, "total_harris": 0}
    
    state_aggregation[state]["total_trump"] += float(data['trump'])
    state_aggregation[state]["total_harris"] += float(data['harris'])
    
    # Déterminer le candidat en tête pour l'État
    leading_candidate = (
        "trump" 
        if state_aggregation[state]["total_trump"] > state_aggregation[state]["total_harris"] 
        else "harris"
    )
    
    # Données transformées à insérer
    transformed_data = {
        'id': data['id'],
        'state': state,
        'county': data['county'],
        'trump': float(data['trump']),
        'harris': float(data['harris']),
        'score_difference': score_difference,
        'total_trump': state_aggregation[state]["total_trump"],
        'total_harris': state_aggregation[state]["total_harris"],
        'leading_candidate': leading_candidate
    }
    
    # Afficher les données transformées avant insertion
    print(f"Données transformées : {transformed_data}")
    
    # Préparer la requête d'insertion pour les données enrichies
    insert_query = """
        INSERT INTO election_data_enriched (
            id, state, county, trump, harris, score_difference, 
            total_trump, total_harris, leading_candidate
        )
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
    """
    
    # Exécution de la requête d'insertion
    cursor.execute(insert_query, (
        transformed_data['id'],  # ID unique du comté
        transformed_data['state'],  # État
        transformed_data['county'],  # Comté
        transformed_data['trump'],  # Score Trump
        transformed_data['harris'],  # Score Harris
        transformed_data['score_difference'],  # Différence de score
        transformed_data['total_trump'],  # Total Trump dans l'État
        transformed_data['total_harris'],  # Total Harris dans l'État
        transformed_data['leading_candidate']  # Candidat en tête dans l'État
    ))
    
    # Sauvegarder les modifications dans la base
    conn.commit()  # Sauvegarder les modifications dans la base

# Fermer la connexion à la base
cursor.close()
conn.close()
```
---


### D. Connexion de Power BI à PostgreSQL

1. Lancez Power BI Desktop
2. Cliquez sur "Obtenir des données" et sélectionnez "Base de données PostgreSQL"
3. Configurez la connexion :
   - Serveur : localhost
   - Base de données : us_election_db
   - Mode de connectivité : DirectQuery
   - Mot de passe : postgres
   - Nom d'utilisateur : postgres
4. Sélectionnez la table `public.election_data_enriched"`