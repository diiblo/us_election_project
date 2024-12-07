# Création et configuration d'un Cluster

---

### Étape 1 : Créer un réseau Docker
Créez un réseau Docker pour permettre aux conteneurs de communiquer entre eux.

```bash
docker network create --driver=bridge pyspark-cluster
```
Si le Network déjà existant cf [PB_Network_Container.md](./PB_Network_Container.md)

---

### Étape 2 : Lancer le conteneur maître
Lancez un conteneur qui jouera le rôle de maître.

```bash
docker run -itd --net=pyspark-cluster -p 8888:8888 -p 8887:8080 -p 4040:4040 --name pyspark-master --hostname pyspark-master my-jupyter-pyspark
```

- **Port 8888** est pour accéder à Jupyter Notebook dans le navigateur.
- **Port 8887** est pour accéder à Spark dans le navigateur.
- **Port 4040** est pour accéder à Spark UI le navigateur.

 En cas de soucis de port veuillez changer le ou les ports exposés de Docker concernés : `'port-concerné':8080`
 
 Si le container existe déjà cf [PB_Network_Container.md](./PB_Network_Container.md) pour sa suppression ou bien redémarrez-le simplement avec :
   ```bash
   docker start nom-du-conteneur
   ```


---

### Étape 3 : Lancer les conteneurs esclaves
Lancez deux conteneurs esclaves, en les connectant au même réseau.

#### Esclave 1
```bash
docker run -itd --net=pyspark-cluster --name pyspark-worker1 --hostname pyspark-worker1 my-jupyter-pyspark
```

#### Esclave 2
```bash
docker run -itd --net=pyspark-cluster --name pyspark-worker2 --hostname pyspark-worker2 my-jupyter-pyspark
```

---

### Étape 5 : Configurer Spark pour le mode cluster
Dans chaque conteneur (maître et esclaves), configurez Spark pour qu'il puisse fonctionner en cluster.

1. **Accédez au conteneur maître** :
   ```bash
   docker exec -u root -it pyspark-master bash
   ```

   **Resultat attendu (à ne pas copier ) :**

    ```bash
    D:\>docker exec -u root -it pyspark-master bash
   (base) root@pyspark-master:~# 
    ```

2. **Configurer le fichier `spark-env.sh`** :  
   Ajoutez la configuration dans `/usr/local/spark/conf/spark-env.sh`. Si ce fichier n'existe pas, créez-le :
   ```bash
   echo "SPARK_MASTER_HOST='pyspark-master'" >> /usr/local/spark/conf/spark-env.sh
   echo "SPARK_WORKER_CORES=2" >> /usr/local/spark/conf/spark-env.sh
   echo "SPARK_WORKER_MEMORY=1g" >> /usr/local/spark/conf/spark-env.sh
   ```

3. **Démarrez Spark** :
   Lancez le processus maître dans le conteneur maître :
   ```bash
   /usr/local/spark/sbin/./start-master.sh
   ```
   **Résultat attendu (à ne pas copier):**
   ```bash
   (base) root@pyspark-master:/usr/local/spark/sbin# ./start-master.sh
   starting org.apache.spark.deploy.master.Master, logging to /usr/local/spark/logs/spark--org.apache.spark.deploy.master.Master-1-pyspark-master.out
   ```

   Puis dans chaque conteneur esclave, lancez le processus esclave en vous connectant d'abord :
   ```bash
   docker exec -u root -it pyspark-worker1 bash
   ```

   ```bash
   /usr/local/spark/sbin/./start-worker.sh pyspark-master:7077
   ```

   Répétez pour `pyspark-worker2`.

---

### Étape 6 : Vérification
- Accédez à l'interface web du maître pour vérifier les nœuds connectés :
  - [http://localhost:8887](http://localhost:8887)

- Accédez à l'interface **jupyter Notebook** le terminal, vous verrez un lien ressemblant à `http://127.0.0.1:8888/?token=...`

---

### Résultat attendu
Un cluster maître-esclave fonctionnel, avec le maître exécutant les tâches PySpark et deux esclaves participant au traitement distribué. PostgreSQL est également prêt à être utilisé pour stocker ou analyser des données.

### Commandes utililes

- Voir si Spark à démarré :
```
tail -f /usr/local/spark/logs/spark--org.apache.spark.deploy.master.Master-1-pyspark-master.out
```

- Vérification des conteneurs actifs :
```
docker ps
```