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