# Configuration de Jupyter et traitement

---

### A. Configuration de la SparkSession dans Jupyter
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

 
#### B. Lire les données depuis PostgreSQL dans PySpark :
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

### C. Effectuer le traitement dans Spark
Effectuez votre traitement (Regroupez les résultats par État pour obtenir les scores moyens de Trump et Harris.).

#### Code :
```python

# Afficher les données pour vérifier le chargement
df_election.show()

# 1. Ajouter une colonne "score_difference" au niveau des comtés
df_with_diff = df_election.withColumn(
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
df_final.select(
    "State", "County", "Trump", "Harris", 
    "score_difference", "total_trump", 
    "total_harris", "leading_candidate"
).show()

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


### D. Connexion de Power BI à PostgreSQL

1. Lancez Power BI Desktop
2. Cliquez sur "Obtenir des données" et sélectionnez "Base de données PostgreSQL"
3. Configurez la connexion :
   - Serveur : localhost
   - Base de données : us_election_db
   - Mode de connectivité : Importer
4. Sélectionnez la table `public.election_data_enriched"`