# Schéma d'architecture de l'affichage de la métrologie 

```pgsql
+---------------------+
|      Telegraf       | ← collecte métriques kafka
|     (telegraf)      |
+----------+----------+
           |
           | HTTP Write API (line protocol)
           v
+---------------------+
|     InfluxDB 2      | ← bucket `metrology`
|     (influxdb)      |
+----------+----------+
           |
           | HTTP Query (Flux) / Datasource InfluxDB 2
           v
+---------------------+
|       Grafana       | ← dashboards
|      (grafana)      |
+---------------------+
```
# Schéma d'architecture — architecture kafka

```pgsql
                    +----------------------------------------------+
                    |           Kafka KRaft cluster                |
                    |  brokers: kafka-1, kafka-2, kafka-3          |
                    |  listeners: PLAINTEXT:9092 / CONTROLLER:9093 |
                    |  JMX: 9991..9993  Jolokia: 8778..8780        |
                    +---------+-------------------------+----------+
                              ^                         ^
           Kafka Admin API    |                         |   Kafka protocol
                              |                         |
+-------------------+         |                         |         +------------------+
|    topic-init     |---------+                         +-------->|     Kafdrop      |
| (build ./topic-   |   crée le topic `weather`                   | (obsidiandynamics|
|        init)      |                                             |  /kafdrop, :9000)|
+-------------------+                                             +------------------+

+-------------------+                                      +--------------------+
|   init-producer   | ───────────── Kafka protocol ───────> |  topic `weather`  |
| (build ./init-    |                                      +--------------------+
|     producer)     |
+-------------------+                                           /     /     /     /
                                                            v     v     v     v
                                                     +-----------+-----------+-----------+-----------+
                                                     | consumer-1| consumer-2| consumer-3| consumer-4|
                                                     | (build    | (build    | (build    | (build    |
                                                     | ./init-   | ./init-   | ./init-   | ./init-   |
                                                     | consumer) | consumer) | consumer) | consumer) |
                                                     +-----------+-----------+-----------+-----------+

                    . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
                    .   Flux de métriques via Jolokia (HTTP 8778..8780, JMX)    .
                    ' . . . . . . . . . . . . . . . . . . . . . . . . . . . . . '
                              |
                              v
+-------------------+
|     telegraf      |  ← scrapes /jolokia des brokers
| (1.30, conf mappé)|  
+----+--------------+
     |
     | HTTP Write API (line protocol)
     v
+-------------------+
|     InfluxDB 2    |  (8086) bucket `kafka_metrics`
| (setup via env)   |
+---------+---------+
          |
          | HTTP Query (Flux) / Datasource InfluxDB 2
          v
+-------------------+
|      Grafana      |  UI dashboards (port :3000)
| (datasource:      |  InfluxDB 2 `kafka_metrics`)
+-------------------+

────────────────────────────────────────────────────────────────────────────────
Légende :
  ──────────────        Flux de messages Kafka
  . . . . . . .         Flux de métriques (Jolokia/JMX → Telegraf)
  HTTP Write / Query    Appels HTTP (InfluxDB / Grafana)
```