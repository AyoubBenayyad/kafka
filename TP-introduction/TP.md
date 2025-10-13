# TP — InfluxDB ↔ Telegraf ↔ Kafka

## Objectifs

- Montrer un pipeline E2E (End 2 End) : **Telegraf / InfluxDB / Kafka / code python**.
- Comprendre l'articulation de la config telegraf.
- Observer le flux côté Kafka (consumer CLI / **Kafdrop**).

## Prérequis

Avoir installé : 
- Docker + Docker Compose

- Savoir manipuler un minimum Docker. Vous pouvez préparer le TP en vous aidant de : 
  - https://docs.docker.com/get-started
  - https://docs.docker.com/compose/gettingstarted

Les versions des images suivantes sont requises : 

```bash
docker pull bitnami/kafka:4.0.0
docker pull obsidiandynamics/kafdrop:4.2.0
docker pull influxdb:2.7
docker pull alpine:3.19
docker pull python:3.11-slim
```



## Démarrage rapide
```bash
docker compose down -v
docker compose up
```
Le ```-v``` permet de vider les données (volume).

## Arrêt rapide

```bash
docker compose down -v
```



## TP pas à pas

Merci de lire le README.md

Partie 1 : prise en main

	1. Démarrer les services du docker-compose.yml
	2. Décrivez ce qu'il se passe dans les logs des services lancés.
	3. Quels sont les containers qui s'éxécutent durablement et leurs fonctions dans cette application ? 
	4. Quels sont les containers qui s'interromptent assez rapidement et leurs fonctions ? 

Partie 2 : compréhension des fonctions des différents containers

	5. A quoi sert le service telegraf dans cette application de démonstration ? 
	6. A quoi sert le container init-alert ?
	7. A quoi sert le container init-topic-1 ? 

Partie 3 : compréhension des ports des différentes applications

	8. Quels sont les ports "mappés" des services ? Quels sont leurs fonctions ?
	9. Quels sont les ports utilisés par kafdrop et leurs fonctions ? 
	10. Quels sont les ports utilisés par le broker kafka3 et leurs fonctions ?
	11. Quels sont les ports utilisés par influxdb et leurs fonctions ? 

Partie 4 : on entre dans le détail

	12. Quel est le bucket influxdb créé pour ce TP ? Qui le créé ? Comment ? 
	13. Critiquez la sécurité du déploiement de l'application autour d'influxdb.
	14. Allez sur kafdrop et montrez les caractéristiques du topic créé.
	15. Retrouvez ces caractéristiques dans le déploiement des services docker.

Partie 5 : résilience de Kafka

	16. Arrêtez un broker kafka. Montrez cet arrêt et les conséquences pour le topic. Comment résoudre les problèmes engendrés par l'arrêt ?
	17. Redémarrez le broker arrêté et montrez l'intéraction avec les autres brokers.
	18. Quelle est la différence fondamentale entre le service "inject" et le service "producer" ? 

Partie  : Aller plus loin

	Lire le fichier KEYWORDS.md

	19. Proposez des voies d'amélioration de cette application de démonstration. 
	20. Pourquoi le code python est encapsulé dans un container ? 
	21. Corrigez l'organigramme du fichier schema.md si vous le jugez nécessaire.
  


