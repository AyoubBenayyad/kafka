

# Schéma d'architecture — TP ksqlDB (docker-compose)

```pgsql
                    +----------------------------------------------+
                    |        Kafka KRaft cluster (Confluent 7.6.1) |
                    |  brokers: kafka-1, kafka-2, kafka-3          |
                    |  PLAINTEXT:9092 / CONTROLLER:9093            |
                    +---------+-------------------------+----------+
                              ^                         ^
                  Kafka proto |                         | Kafka proto
                              |                         |
+-------------------+         |                         |         +-----------------------------+
|     producer      |---------+                         +-------->|   Redpanda Console (UI)     |
| (build ./producer)|  produit vers le cluster                    |   :8082 → container :8080   |
+-------------------+                                            +------------------------------+

                              |                         |
                              |                         | HTTP (UI)
                              |                         v
                              |                    +-----------------------------+
                              |                    |  Control Center (UI)        |
                              |                    |  :9021                      |
                              |                    +-----------------------------+
                              |                         ^            ^
                              |                         |            |
                              |          HTTP (REST)    |            |  HTTP (REST)
                              |                         |            |
                              v                         |            |
+-------------------+   Kafka proto               Kafka proto        |
| Schema Registry   |<--------------------------->|                  |
| (cp-schema-reg.)  |   :8081                     |                  |
+-------------------+                              |                  |
                                                   |                  |
                                                   |                  |
                                                   v                  |
                                             +----------------+       |
                                             |  ksqlDB        |<------+
                                             |  server :8088  |
                                             +----------------+

────────────────────────────────────────────────────────────────────────────────
Légende :
  Kafka proto          Connexion au cluster Kafka (bootstrap PLAINTEXT)
  HTTP (UI)            Accès navigateur aux interfaces web (Control Center, Redpanda Console)
  HTTP (REST)          Appels REST (Control Center → Schema Registry / ksqlDB)
```