# TP étudiants 2025

## Présentation
Dans ce TP, vous déployez via Docker Compose un mini‑environnement d’observabilité autour d’un cluster Kafka. L’objectif est de comprendre l’architecture des services, d’exposer les métriques Kafka avec Jolokia2/Telegraf et de les stocker dans InfluxDB. Vous apprendrez à interroger ces données en Flux et à construire un tableau de bord pour suivre l’activité normale, puis analyser l’impact d’une panne/récupération d’un broker. Enfin, vous proposerez un ou deux cas d’usage supplémentaires à partir d’autres métriques.


## Prérequis
- Docker + Docker Compose.
- Prendre un moment pour comprendre le docker-compose.yml

## Démarrage rapide
```bash
docker compose up -d
docker compose logs telegraf -f
```

## Questions de TP

**Analyse de l'environnement** : 

1. Comment est organisé le fichier docker_compose.yml
2. A la lecture du fichier docker_compose.yml expliquez l'organisation de l'application. Faites un schéma simple des relations des différents services.
3. Prenez le paragraphe "environment" d'un des services kafka et décrivez les fonctions de chacune des lignes? 

**Observabilité** : 

4. Cherchez ce qu'est jolokia2 ?
5. Quel service va t il offrir et à qui ? 
6. Expliquez la fonction du service Telegraf et les élements principaux de sa configuration dans notre exemple.

**Métrologie** : 

7. Quel topic est utilisé dans cette application.
8. Quel bucket est utilisé dans cette application.
9. Quels sont les grandes familles de métriques dont on a la métrologie ? Concentrez vous sur "broker/replication, network, topic metrics, consumer lag".
10. Sachant que la plupart des courbes disponibles pour ces measurements vont être des courbes globalement continuellement ascendantes, quel proposez vous comme fonction d'agrégation pour construite des graphiques mettant en valeur les variations.
11. Au moyen du script "suspend_random_broker_loop.sh" montrez ce qu'ils se passe lors de la perte d'un broker puis après quelques temps sont retour.  Mettez en évidence les measurements affectés au moyen d'un dashboard. Vous mettrez la requête correspondante en "Flux" d'influxDB.

"**To infinity and beyond!**" :

12. Explorez d'autres métriques et imaginez des cas d'usages. Illustrez vos propositions par la capture d'écran du dashboard correspondant ainsi que sa requête "Flux".


## Notes

- les questions mettant en oeuvres le langage Flux sont à réaliser au travers de l'interface graphique d'InfluxDB. En cliquant sur la case "Script Editor" vous pourrez vous s'afficher la requête. En cliquant sur Query Builder vous revenez à l'affichage initial.
