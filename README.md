# Projet Big Data : Analyse des Élections Américaines 2024 avec Spark et PostgreSQL

Ce projet analyse les données des [élections américaines de 2024](https://github.com/dBangos/US-Election-Results-2024). en utilisant une architecture Big Data basée sur Spark, PostgreSQL, et Jupyter Notebook. Le traitement distribué s'appuie sur un cluster Spark configuré avec Docker, tandis que PostgreSQL sert au stockage structuré des résultats.

---

## Objectifs du projet

1. Configurer un environnement Docker avec Spark, PostgreSQL et Jupyter Notebook.
2. Analyser les performances électorales des candidats par État et par comté.
3. Automatiser le traitement et l'enrichissement des données avec PySpark.
4. Stocker les résultats enrichis dans PostgreSQL pour une exploitation BI.

---

## Étapes du projet

### 1. Création d'une image Docker personnalisée
L'image Docker utilisée inclut :
- Spark pour le traitement Big Data.
- PostgreSQL pour le stockage des résultats.
- Bibliothèques Python telles que `pyspark` et `psycopg2`.

```bash
docker pull jupyter/pyspark-notebook
docker build -t my-jupyter-pyspark .
```

### 2. Configuration du cluster Spark
Le cluster Spark utilise une topologie maître-esclaves (1 maître, 2 esclaves), connectés via un réseau Docker.

```bash
docker network create --driver=bridge pyspark-cluster
docker run -itd --net=pyspark-cluster --name pyspark-master my-jupyter-pyspark
docker run -itd --net=pyspark-cluster --name pyspark-worker1 my-jupyter-pyspark
docker run -itd --net=pyspark-cluster --name pyspark-worker2 my-jupyter-pyspark
```

### 3. Chargement des données électorales dans PostgreSQL
Les données des élections américaines 2024 sont chargées dans PostgreSQL depuis un fichier CSV. Une base `us_election_db` et une table `election_data` sont créées.

#### Exemple SQL :
```sql
CREATE TABLE election_data (
    id INT,
    State VARCHAR(255),
    County VARCHAR(255),
    Trump REAL,
    Harris REAL
);
\COPY election_data (State, County, Trump, Harris) FROM '/tmp/data.csv' WITH CSV HEADER;
```

### 4. Analyse des données avec PySpark
Les données sont analysées pour calculer les scores totaux et identifier le candidat majoritaire par État.

#### Exemple PySpark :
```python
df_with_diff = df_election.withColumn(
    "score_difference", F.abs(F.col("Trump") - F.col("Harris"))
)
df_state_aggregation = df_with_diff.groupBy("State").agg(
    F.sum("Trump").alias("total_trump"),
    F.sum("Harris").alias("total_harris")
)
df_final.write.format("jdbc").option("url", jdbc_url).save()
```

### 5. Visualisation des résultats dans Power BI
Les données enrichies sont visualisées dans Power BI en se connectant à PostgreSQL.

---

## Prérequis

1. **Docker** : Installer Docker pour gérer les conteneurs.
2. **PostgreSQL** : Configurer une instance PostgreSQL pour le stockage.
3. **Power BI** : Importer les résultats pour des visualisations interactives.

---

## Structure du projet

1. **Dockerfile** : Image Docker personnalisée avec Spark et PostgreSQL.
2. **Scripts PySpark** : Analyses distribuées des données électorales.
3. **Données CSV** : [Résultats des élections américaines 2024](https://github.com/dBangos/US-Election-Results-2024).
4. **README.md** : Documentation complète.

---

## Technologies utilisées

- **Jupyter Notebook** : Interface interactive pour exécuter les analyses.
- **PySpark** : Traitement Big Data et enrichissement des données.
- **PostgreSQL** : Stockage des données analysées.
- **Docker** : Conteneurisation pour une gestion simplifiée.

---

## Auteur

**Moctarr Basiru King Rahman**  
Étudiant en Mastère Data Engineering à l'ECE Paris  
[LinkedIn](https://www.linkedin.com/in/moctarr-basiru-king-rahman-7337a5214) | [Email](mailto:moctarrbasiru.kingrahman@edu.ece.fr)

---

## Licence

Ce projet est distribué sous la licence [MIT](./LICENSE).

---

## Remarque

Pour toute question ou problème, ouvrez une *issue* dans ce dépôt.