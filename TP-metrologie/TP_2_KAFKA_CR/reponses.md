# Analyse de l'environnement : 

## Question 1 : Organisation du fichier docker-compose.yml : 

Le fichier docker-compose.yml est organisé en **sections de services** :

### Structure générale :
- **3 brokers Kafka** (kafka-1, kafka-2, kafka-3) : cluster KRaft
- **InfluxDB** : base de données time-series pour stocker les métriques
- **Telegraf** : collecteur de métriques
- **Producteur** (init-producer) : génère des messages météo
- **4 Consommateurs** (consumer-1 à 4) : consomment les messages du topic
- **topic-init** : initialise le topic "weather"
- **Kafdrop** : interface web pour visualiser Kafka

### Organisation :
Chaque service définit :
- `image` ou `build` : l'image Docker à utiliser
- `ports` : mapping des ports (hôte:conteneur)
- `environment` : variables de configuration
- `depends_on` : dépendances entre services
- `volumes` : montage de fichiers (ex: jolokia.jar, telegraf.conf)

## Question 2 : Schéma de l'organisation de l'application
### Schéma simplifié (sépare les flux de données et de métriques)

Legend:
- Flèches solides = flux de données Kafka (producer -> brokers -> consumers)
- Flèches pointillées = flux de métriques (Jolokia HTTP -> Telegraf -> InfluxDB)

┌─────────────────────────────────────────────────────────────────────┐
│                        CLUSTER KAFKA (KRaft)                        │
│  ┌──────────┐      ┌──────────┐      ┌──────────┐   (Jolokia HTTP)   │
│  │ kafka-1  │      │ kafka-2  │      │ kafka-3  │ 8778/8779/8780     │
│  │ :9092    │      │ :9092    │      │ :9092    │                    │
│  │ (Jolokia)│      │ (Jolokia)│      │ (Jolokia)│                    │
│  └──────────┘      └──────────┘      └──────────┘                    │
│                                                                     │
│                Topic: weather (4 partitions, RF=3)                 │
└─────────────────────────────────────────────────────────────────────┘
        ▲                                   │
        │                                   │
        │ produce (data)                    │ consume (data)
        │                                   ▼
┌─────────────────┐             ┌──────────────────────────┐
│ init-producer   │             │  consumer-1,2,3,4        │
│ (weather data)  │             │  (group: weather-group)  │
└─────────────────┘             └──────────────────────────┘

        
        (metrics - dotted path: brokers expose JMX via Jolokia)
        kafka-1:8778  kafka-2:8779  kafka-3:8780
             \           |            /
              . . . . . .|. . . . . .
                       ┌──────────┐
                       │ Telegraf │  ← collecte JMX via les endpoints Jolokia des brokers
                       └──────────┘
                            |
                            │ HTTP Write (InfluxDB Line Protocol)
                            ▼
                       ┌──────────┐
                       │ InfluxDB │  ← stockage time-series (bucket: kafka_metrics)
                       │ :8086    │
                       └──────────┘

Services auxiliaires:
- `topic-init`: crée le topic au démarrage
- `kafdrop` (:9000): UI web pour monitorer Kafka
```

### Explication des flux :

Flux de données Kafka (messages):
1. `init-producer` génère des messages météo (JSON) et les envoie au topic `weather`.
2. Le cluster Kafka (3 brokers) réplique les données selon le facteur de réplication.
3. Les consommateurs (consumer-1..4) lisent les messages en parallèle en faisant partie du même consumer group.

Flux de métriques (monitoring):
1. Chaque broker Kafka expose ses métriques JMX via un agent Jolokia accessible en HTTP (ex.: `http://kafka-1:8778/jolokia`).
2. `Telegraf` scrape ces endpoints Jolokia (configuration: `[[inputs.jolokia2_agent]] urls = ["http://kafka-1:8778/jolokia", ...]`) et ajoute des tags par broker.
3. Telegraf envoie les métriques à `InfluxDB` (HTTP Write) pour stockage (bucket: `kafka_metrics`).
4. Les tableaux de bord et requêtes Flux lisent les séries temporelles depuis InfluxDB.

Remarque importante : Telegraf ne scrappe pas `init-producer`. Il interroge directement les brokers via Jolokia — le producteur sert uniquement à générer la charge qui provoque des métriques sur les brokers.

Preuves dans la configuration du projet :
- `telegraf.conf` contient bien les URLs Jolokia des brokers et collecte des MBeans Kafka (BrokerTopicMetrics, ReplicaManager, etc.).
- Dans `docker-compose.yml`, `telegraf` dépend de `kafka-1`, `kafka-2`, `kafka-3` et `influxdb`, et il n'y a pas de lien ou dépendance entre `telegraf` et `init-producer`.

Si souhaité, je peux aussi rendre le diagramme encore plus net (par exemple remplacer ASCII par un SVG ou image) — dites si vous préférez cela.

