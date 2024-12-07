# Créer une image docker...

---

### Étape 1 : Télécharger l'image Jupyter avec Spark
Les images **Jupyter Docker Stacks** incluent différentes configurations. L'image `jupyter/pyspark-notebook` est celle qui contient Jupyter et Spark.

1. **Télécharger l’image Docker :**
   Ouvrez un terminal et exécutez la commande suivante pour télécharger l’image `jupyter/pyspark-notebook` :
   ```bash
   docker pull jupyter/pyspark-notebook
   ```


2. **Vérifiez que l’image est bien téléchargée :**
   Vous pouvez vérifier avec :
   ```bash
   docker images
   ```
   Vous devriez voir `jupyter/pyspark-notebook` dans la liste.

### Étape 2 : Ajouter PostgreSQL à l'image
Puisque `jupyter/pyspark-notebook` ne contient pas tout nos outils, nous allons les ajouters, par un `Dockerfile`.

**NB :** Certains, ne sont pas importants, mais peuvent servir pour d'autres projets

1. **Créer un Dockerfile personnalisé :**
   Dans répertoire de votre choix, créez un fichier appelé `Dockerfile` (sans extension) et ajoutez les lignes suivantes :
   ```dockerfile
   # Utiliser l'image de base Jupyter avec Spark
   FROM jupyter/pyspark-notebook

   USER root

   # Installer les outils
   RUN apt-get update && apt-get install -y openjdk-11-jdk net-tools curl

   # Créer le répertoire de données PostgreSQL
   # RUN mkdir -p /var/lib/postgresql/data && chown -R postgres:postgres /var/lib/postgresql

   # Télécharger le fichier JDBC PostgreSQL
   RUN curl -o /usr/local/spark/jars/postgresql-42.6.0.jar https://jdbc.postgresql.org/download/postgresql-42.6.0.jar

   # Configurer PostgreSQL pour qu'il démarre sans mot de passe
   #USER postgres
   #RUN /usr/lib/postgresql/14/bin/initdb -D /var/lib/postgresql/data

   # Changer l’utilisateur par défaut pour Jupyter Notebook et démarrer PostgreSQL
   USER $NB_USER
   CMD ["start-notebook.sh"]
   ```

2. **Construire votre nouvelle image Docker :**
   Dans le terminal, exécutez cette commande pour construire l’image Docker personnalisée (assurez-vous d’être dans le même dossier que le `Dockerfile`) :
   ```bash
   docker build -t my-jupyter-pyspark .
   ```
   Cette commande crée une nouvelle image Docker appelée `my-jupyter-pyspark`

