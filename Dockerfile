# Utiliser l'image de base Jupyter avec Spark
FROM jupyter/pyspark-notebook

USER root

# Installer des outils système
RUN apt-get update && apt-get install -y net-tools curl git postgresql postgresql-contrib

# Ajouter des connecteurs JDBC
RUN curl -o /usr/local/spark/jars/postgresql-42.6.0.jar https://jdbc.postgresql.org/download/postgresql-42.6.0.jar && \
    curl -o /usr/local/spark/jars/mysql-connector-java-8.0.34.jar https://repo1.maven.org/maven2/mysql/mysql-connector-java/8.0.34/mysql-connector-java-8.0.34.jar && \
    curl -o /usr/local/spark/jars/spark-sql-kafka-0-10_2.12-3.4.0.jar https://repo1.maven.org/maven2/org/apache/spark/spark-sql-kafka-0-10_2.12/3.4.0/spark-sql-kafka-0-10_2.12-3.4.0.jar && \
    curl -o /usr/local/spark/jars/mongo-spark-connector_2.12-10.2.0.jar https://repo1.maven.org/maven2/org/mongodb/spark/mongo-spark-connector_2.12/10.2.0/mongo-spark-connector_2.12-10.2.0.jar && \
	curl -o /usr/local/spark/jars/hadoop-aws-3.3.6.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.6/hadoop-aws-3.3.6.jar


# Installer des bibliothèques Python
RUN pip install --no-cache-dir \
    psycopg2-binary kafka-python redis \
    tensorflow torch transformers \
    plotly dash ipython ipdb

# Configurer PostgreSQL pour démarrer sans mot de passe
RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf && \
    echo "host all all all trust" >> /etc/postgresql/*/main/pg_hba.conf

# Créer le répertoire de données PostgreSQL
RUN mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql

# Changer l’utilisateur par défaut pour Jupyter Notebook
USER $NB_USER

# Commande par défaut
CMD ["start-notebook.sh"]
