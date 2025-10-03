# TP — Traitement de flux avec ksqlDB (pas à pas, pédagogique)

Ce TP fait pratiquer **les fondamentaux de ksqlDB** : création de streams/tables, clés et (re)partitionnement, fenêtres (tumbling/hopping), agrégations, **PUSH vs PULL queries**, **JOIN** stream‑table, introspection et nettoyage.  
Exemple fil rouge : un flux de températures par ville publié dans le topic Kafka (`temperatures`).

Le matériel pédagogique du TP est dans le répertoire 1-illustration

---

## Prérequis et introduction

- Concepts : 

**ksqlDB** — Base de données orientée flux au-dessus de Kafka : on écrit des requêtes SQL pour transformer des topics en streams et tables, faire des jointures, des fenêtres et exposer des résultats (push/pull). Pensé pour créer des applis de stream processing sans coder en Java. 

**Stream (ksqlDB)** — Collection partitionnée, immuable et append-only représentant une suite d’événements (les faits historiques d’un topic). On n’édite jamais un événement ; on en ajoute de nouveaux.

**Flow (Control Center)** — Vue graphique de ksqlDB dans Confluent Control Center qui montre le topologie de traitement : sources, streams/tables, requêtes persistantes et leurs liens, pour suivre le passage des messages et déboguer. 

**Table (ksqlDB, dans les streams)** — Collection mutable et matérialisée qui modèle l’état “courant” par clé (ex. dernière valeur par ville). Elle sert aux agrégations/jointures et peut être interrogée en PULL comme une vue matérialisée. 

- Outils

  - **Docker + Docker Compose** opérationnels.
  - Un **cluster Kafka** et **ksqlDB** démarrés par la stack (ports typiques : Kafka `9092`, ksqlDB REST `8088`).  

  Définis deux variables d’environnement (macOS/Linux) pour fluidifier les commandes :

```bash
export BROKER="<host:port Kafka>"

# Exemple si tu es dans un réseau Docker compose :
# export BROKER="votre_adresse_IP:9092"
export KSQLDB_URL="http://<host:port ksqldb>"
# Exemple :
# export KSQLDB_URL="http://votre_adresse_IP:8088"
```

  On vérifie que ksqlDB répond :

```bash
curl -s "$KSQLDB_URL/info" | jq .
# ou
curl -s "$KSQLDB_URL/healthcheck"
```

  Les éléments attendus sont de l'ordre de : 

```yaml
prompt : curl -s "$KSQLDB_URL/info" | jq .

{
  "KsqlServerInfo": {
    "version": "0.27.2",
    "kafkaClusterId": "une certaine valeur aléatoire",
    "ksqlServiceId": "ksql_kraft",
    "serverStatus": "RUNNING"
  }
}

prompt : curl -s "$KSQLDB_URL/healthcheck"

{"isHealthy":true,"details":{"metastore":{"isHealthy":true},"kafka":{"isHealthy":true},"commandRunner":{"isHealthy":true}}}%  
```

---

## 1) Création du topic source + envoi de données de test

Crée le topic `temperatures` (4 partitions par exemple) :

```bash
# Avec kafka-topics (dans un conteneur Kafka si nécessaire)
docker exec -i kafka-1 \
  kafka-topics --bootstrap-server "$BROKER" \
  --create --topic temperatures --partitions 4 --replication-factor 1 --if-not-exists
```

- Ecris la commande qui va bien pour vérifier le bon fonctionnement de la commande précédente.

- Le script bash/python suivant va servir à publier des messages sur le topic de travail. On va le réutiliser systématiquement dès qu'on va se proposer d'observer quelque chose. Il publie 100 messages. Il est simple de modifier cette limite afin de satisfaire le besoin d'un contexte particulier. Les messages publiés sont les éléments suivants (clé = ville, valeur = {ville, t, ts}) :

```python
# Option - kafka-console-producer (clé via parse.key)
bash -lc 'python3 - <<'"'"'PY'"'"' | docker exec -i kafka-1 \
  kafka-console-producer --bootstrap-server '"$BROKER"' \
  --topic temperatures --property parse.key=true --property key.separator=:
import json,random,time,sys
villes=["Clermont-Ferrand","Lyon","Paris","Bordeaux","Nantes"]
for _ in range(200):
    v=random.choice(villes)
    rec={"ville":v,"t":round(random.uniform(5,35),1),"ts":int(time.time()*1000)}
    print(f"{v}:{json.dumps(rec)}"); sys.stdout.flush(); time.sleep(0.2)
PY'
```

- Ouvrez un navigateur sur l'URL du control-center et montrez le remplissage du topic **temperatures**. Montrez la répartition des messages au travers des partitions. 

Contrôle rapide du topic :

```bash
docker exec -i kafka-1 \
  kafka-topics --bootstrap-server "$BROKER" --describe --topic temperatures
```

- Maintenant changez légèrement le code python précédent par 

```python
# Option - kafka-console-producer (clé via parse.key)
bash -lc 'python3 - <<'"'"'PY'"'"' | docker exec -i kafka-1 \
  kafka-console-producer --bootstrap-server '"$BROKER"' \
  --topic temperatures --property parse.key=true --property key.separator=:
import json,random,time,sys
villes=["Clermont-Ferrand","Lyon","Paris","Bordeaux","Montpellier"]
for _ in range(200):
    v=random.choice(villes)
    rec={"ville":v,"t":round(random.uniform(5,35),1),"ts":int(time.time()*1000)}
    print(f"{v}:{json.dumps(rec)}"); sys.stdout.flush(); time.sleep(0.2)
PY'
```

Qu'observez vous sur la répartition des messages ? 

Intéressez vous à la fonction de hachage Murmur2. Quel est son lien avec notre affaire ? 

---

## 2) Se connecter à ksqlDB

Trois options possibles :

- **CLI intégré** :
  ```bash
  docker run --rm -it \
  confluentinc/ksqldb-cli:0.27.2 \
  ksql "$KSQLDB_URL"
  ```
- **UI Web** (si exposée par ta stack) : ouvre `http(s)://<host>:<port>/` et passe en mode ksql.

```bash
curl -s -X POST "$KSQLDB_URL/ksql" \
  -H 'Content-Type: application/vnd.ksql.v1+json; charset=utf-8' \
  -d '{"ksql":"SHOW TOPICS;","streamsProperties":{}}' | jq .
```

```bash
curl -s -X POST "$KSQLDB_URL/ksql" \
  -H 'Content-Type: application/vnd.ksql.v1+json; charset=utf-8' \
  -d '{"ksql":"SHOW STREAMS;","streamsProperties":{}}' | jq .
```

- utiliser le control-center http://localhost:9021

Sans doute est-ce le plus simple. 

  - choisir KSQLDB Cluster
  - choisir ksqlDB
  - cliquer sur ksqldb

Voir les topics actuels : 

```sql
show topics;
```
puis "Run query" (bouton vert à droite)

```json
{
  "@type": "kafka_topics",
  "statementText": "show topics;",
  "topics": [
    {
      "name": "commandes",
      "replicaInfo": [
        3
      ]
    },
    {
      "name": "temperatures",
      "replicaInfo": [
        1,
        1,
        1,
        1
      ]
    }
  ],
  "warnings": [

  ]
}
```

---

## 3) Créer un stream

**Important** : en ksqlDB, la **clé logique** (KEY) gouverne les agrégations/joints.  
Même si la valeur contient `ville`, **il faut s’assurer que la clé Kafka = ville**.

- reprenez le script bash/python afin que l'insertion de messages dure l'intégralité du TP. Par exemple mettez le range à 100000 ou la valeur qui vous parait adéquate. Vous pouvez lancer le script tel quel au début de chaque besoin de visualisation plutôt que de mettre une très longue durée. A vous de voir.

- **Stream brut** mappé sur le topic :

```sql
CREATE STREAM S_TEMPS_RAW (
  ville STRING,
  t DOUBLE,
  ts BIGINT
) WITH (
  KAFKA_TOPIC = 'temperatures',
  VALUE_FORMAT = 'JSON',
  TIMESTAMP = 'ts'
);
```

- visualiser le stream S_TEMPS_RAW dans le control-center

```sql
select * from S_TEMPS_RAW;
```
  - Que voyez vous apparaitre ?
  
  - Recherchez la syntaxe pour sélectionner tous les enregistrements pour la ville de Paris et mettez là en oeuvre. 

  - Lancez la requête suivante : ```sql select * from S_TEMPS_RAW; ```. Comment la transformer pour avoir tous les enregistrements depuis le début ?  


- A partir du précédent STREAM on va créer un topic et un stream basés sur le stream précédent mais ayant pour clé "ville". 

```sql
CREATE STREAM S_TEMPS_BY_VILLE
  WITH (KAFKA_TOPIC='temperatures_by_ville', PARTITIONS=4) AS
SELECT ville, t, ts
FROM S_TEMPS_RAW
PARTITION BY ville
EMIT CHANGES;
```

  - assurez vous de la création du TOPIC et du STREAM

Au moyen des requêtes suivantes vérifie la clé utilisée :

```sql
SHOW STREAMS;
DESCRIBE  S_TEMPS_BY_VILLE;
```

  - dans l'onglet ksqlDB du Control Center à quoi correpond "Persistent queries" et expliquez pourquoi c'est une requête persistante.



---

## 4) Réalisation de Fenêtres et d'agrégations (TUMBLING)

Créons une table matérialisée des **maximas sur 5 minutes** par ville :

```sql
CREATE TABLE T_MAX_5M AS
SELECT
  ville,
  WINDOWSTART AS w_start,
  WINDOWEND   AS w_end,
  MAX(t)      AS t_max
FROM S_TEMPS_BY_VILLE
WINDOW TUMBLING (SIZE 5 MINUTES, GRACE PERIOD 30 SECONDS)
GROUP BY ville
EMIT CHANGES;
```

- alors qu'en arrière plan vous ajoutez des messages dans le topic **temperatures** que voyez vous dans l'onglet "persistent queries" de ksqldb ? Expliquez.


- Affichons les valeurs maximums de températures sur une fenêtre de 5 mn :

Dans l'onglet ksqldb lancez la requête suivante pendant que vous injectez de nouveaux messages dans le topic **temperatures** : 

```sql
-- Affiche en continu les fenêtres qui se remplissent
SELECT * FROM T_MAX_5M EMIT CHANGES;
```

Expliquez ce que vous voyez. Pensez à faire un tri sur la colonne ville pour que cela devienne plus clair.


---

## 5) Les dernières valeurs par ville 

Table non fenêtrée avec la dernière température observée par ville :

```sql
CREATE TABLE T_LAST AS
SELECT ville,
       LATEST_BY_OFFSET(t) AS t_last,
       LATEST_BY_OFFSET(ts) AS ts_last
FROM S_TEMPS_BY_VILLE
GROUP BY ville
EMIT CHANGES;
```

- Que faire pour controler que cela fonctionne ? 



- Quelle requête écrire pour obtenir en permanence la dernière valeur de température pour Lyon ? 


---

## 7) HOPPING windows (option)

Le **TUMBLING** est une fenêtre glissante au fur et à mesure du passage du temps. Le **HOPPING** est une fenêtre glissante sauts.

Fenêtre glissante de 10 min, **saut** de 2 min :

```sql
CREATE TABLE T_AVG_10M_HOP2 AS
SELECT
  ville,
  WINDOWSTART AS w_start,
  WINDOWEND   AS w_end,
  AVG(t)      AS t_avg
FROM S_TEMPS_BY_VILLE
WINDOW HOPPING (SIZE 10 MINUTES, ADVANCE BY 2 MINUTES)
GROUP BY ville
EMIT CHANGES;
```

Mettez en oeuvre le HOPPING tel que décrit ci-dessus. Montrez l'évolution de la table correspondante.

---

## 8) Petit projet pour aller plus loin

  Ecrivez un petit programme, le plus symple possible en python/ksqldb, qui interrogera le topic ```temperature```. Il sera alimenté par le script bash/python vu précédement. Il affichera la moyenne courante des températures pour la ville de Paris, l'écart-type courant s'il y a un changement pour l'une ou l'autre de ces valeurs. Si la dernière valeur de température pour Paris sort de l'écart-type alors il faudra l'indiquer une alerte et bien entendu continuer le processus précédent.

  Si vous le souhaitez vous pouvez vous inspirer des deux premiers TP pour enregistrer ces informations et alertes dans un influxdb et avoir un dashboard qui matérialise tout cela :) 
