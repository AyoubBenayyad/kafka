# Points clés

Dans ce projet, Kafka n’est pas juste lancé dans un conteneur : on exploite un certain nombre de concepts-clés pour en faire une vraie plate-forme de messaging robuste et évolutive :


##	Cluster KRaft (sans ZooKeeper)

    • On passe en mode « KRaft », où chaque nœud est à la fois broker et controller (KAFKA_CFG_PROCESS_ROLES=broker,controller) et participe à un quorum de contrôleurs (KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@kafka1:9093,2@kafka2:9093,3@kafka3:9093).
    
    • Avantage : plus besoin de ZooKeeper, et on a un mécanisme de haute disponibilité et d’élection de controller intégré.

##	Multi-nœuds pour la tolérance de panne

    • Trois brokers (kafka1, kafka2, kafka3) : en cas de défaillance de l’un, les deux autres continuent de servir les clients.
    • Replication factor 3 sur les topics critique (on le définit explicitement à la création).

##	Partitionnement pour la mise à l’échelle

    • Chaque topic (ici weather et weather-telegraf) est créé avec 4 partitions (--partitions 4), ce qui permet :
    • D’augmenter le débit en traitant plusieurs partitions en parallèle.
    • D’assigner plusieurs consommateurs (dans un même groupe) pour lire en parallèle.

##	Gestion de topics par scripts

    • On désactive l’auto-création (KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE=false) pour éviter des topics impromptus.
    • Deux containers init-topic et init-topic-telegraf attendent que le broker soit prêt puis lancent kafka-topics.sh pour créer manuellement les topics avec leurs paramètres souhaités (partitions, réplication).

##	Producteurs et consommateurs

    • Producer : un microservice (conteneur producer) produit régulièrement des messages météo sur le topic weather.
    • Telegraf : configuré en consumer via le plugin Kafka, il lit le topic weather-telegraf et écrit dans InfluxDB.
    • Inject : un autre producer qui écrit dans InfluxDB via Kafka et Influx (on voit la logique d’intégration).

##	Dissuasion des erreurs de topologie

    • Listeners séparés pour les contrôleurs et pour les clients (PLAINTEXT://…, CONTROLLER://…), avec expose/advertise adaptés pour éviter que les clients se connectent sur le mauvais port.

##	Observabilité

    • Kafdrop est déployé pour visualiser les topics, partitions, offsets et consommateurs en temps réel, ce qui facilite le debugging et le monitoring du cluster.

