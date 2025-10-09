# TP Sémantiques d'écritures et de lectures

Le présent TP est conçu pour être un mini projet. Son objet est de pouvoir affiner votre compréhension des sémantiques de production/consommation. Il vous permettra de mettre en oeuvre l'écriture de producteurs et de consommateurs.

Vous allez choisir un thème de production d'information/messages. Dans les précédents TP le thème était la mesure de la température de l'air pour des villes. Vous pouvez reprendre ce thème, le compléter ou bien en choisir un autre. 

Vous devez réaliser par vous même les tâches suivantes. Vous utiliserez le langage python dans l'écriture des programmes à réaliser. Pensez à encapsuler tout cela dans des "venv" avec un requierement.txt afin qu'on puisse reproduire vos développements. 

Bien entendu vous devrez utiliser ou concevoir un docker-compose.yml mettant en oeuvre au minimum 3 brokers, un outil de visualisation simple des topics/brokers.

## 1) Création de topic : 

    - Créer un topic (RF 3, Partions 5) par le moyen de votre choix. 
    - Expliquez votre docker-compose.
    - Montrez et expliquez votre choix de méthode de création du topic. 
    - Citez d'autres méthodes pour faire la même chose.
    - Que vont vous permettre ces choix : "RF=3, nombre de partitions=5" ?
    - Qu'est-ce que l'ISR ? 
    - Qu'est-ce que le min.insync.replicas ? 
        - Quelle est sa valeur par défaut ? 
        - Quelles sont les bonnes pratiques pour le définir ?
        - Où peut-on le définir ? (niveau broker, niveau topic, niveau producteur) ?


## 2) Réaliser un producteur avec les différents types d'écriture :

    - Définissez ce que sont les différents types d'écriture.
    - Quels sont les avantages et inconvénients de chaque type d'écriture.
    - Ecrivez un producteur réalisant "At most one" et expliquez les risques de pertes de messages.
    - Ecrivez un producteur réalisant "At least one" et expliquez les risques de doublons.
    - Ecrivez un producteur réalisant "Exactly one" et expliquez comment vous vous y êtes pris pour garantir cette sémantique.

## 3) Réaliser un consommateur

    - At most once. 
    - At least once.
    - Exactly once. Aidez vous de "enable.idempotence=true, acks=all"
    - Faites en sorte que vos consommateurs puissent faire varier facilement leurs vitesses de consommation (par exemple en ajoutant un Thread.sleep dans la boucle de consommation). 

## 4) Réaliser un groupe de consommateurs

    - Créez un groupe de consommateurs avec 3 consommateurs.
        - consommateur1 :  vitesse de lecture 1 message par 3 secondes
        - consommateur2 : vitesse 1 pour 5 secondes
        - consommateur3 : vitesse 1 pour 9 secondes
    - Observez et expliquez les lags de consommation.


## 5) Scénario de panne

    - faites un script bash qui arrête aléatoirement un des brokers toutes les 60 secondes.
    - Observez et expliquez le comportement de vos producteurs et consommateurs.
  
## 6) Optionnel si vous avez envie

    - Faites en sorte que votre producteur puisse écrire dans un topic avec un schéma Avro.
    - Faites en sorte que votre consommateur puisse lire dans un topic avec un schéma Avro.
    - Faites en sorte que votre producteur puisse écrire dans un topic avec un schéma JSON Schema.
    - Faites en sorte que votre consommateur puisse lire dans un topic avec un schéma JSON Schema.
    - Faites en sorte que votre producteur puisse écrire dans un topic avec un schéma Protobuf.
    - Faites en sorte que votre consommateur puisse lire dans un topic avec un schéma Protobuf.
    - Faites en sorte que votre producteur puisse écrire dans un topic avec un schéma Avro, JSON Schema et Protobuf.
    - Faites en sorte que votre consommateur puisse lire dans un topic avec un schéma Avro, JSON Schema et Protobuf.    
   

