# SEMANTIQUES

## imports classiques

```python
from confluent_kafka import kafka
```

## producteur : At most once

```python
conf = {
    "bootstrap.servers": BOOTSTRAP,
    "acks": 0,
    "retries": 0,
    "linger.ms": 0,
    "enable.idempotence": False,
}
p = Producer(conf)
...
    une boucle
        p.produce(TOPIC, value=value, on_delivery=on_error)
...
p.flush(2.0)
...
```

- acks=0 : 

    ```le broker ne confirme jamais → le producteur considère le message “envoyé” dès qu’il part sur le réseau.```

- retries=0 : 

    ```s’il y a un souci (buffer plein, coupure réseau, broker down), aucun ré-essai n’est tenté → le message peut être perdu.```

- Pas d’idempotence ni de transactions.


## producteur : At least one

```python
conf = {
    "bootstrap.servers": "localhost:9092",
    "acks": "all",              # on attend l'accusé du leader + réplicas
    "retries": 5,               # on réessaye si une erreur survient
    "linger.ms": 5,             # petit délai de batch pour performance
    "enable.idempotence": False # pas d'idempotence → doublons possibles
}
p = Producer(conf)
...
    une boucle...
        p.produce(topic, value=value, callback=delivery_report)
...
p.flush(5)
```

- acks=all

    ```le producteur attend que tous les réplicas confirment l’écriture du message```

- retries>0

    ```permet de réessayer si un envoi échoue (ex. réseau instable)```
- enable.idempotence=False

    ```les réessais peuvent générer des doublons (mais aucune perte)```

- flush()

    ```garantit que tous les messages en mémoire sont envoyés avant de quitter```

•	Messages non perdus (sauf crash total prolongé de Kafka avant réplication).

•	Possibilité de doublons, donc il faut souvent une logique de déduplication côté consommateur ou application.

## producteur : Exactly one

Sera basé sur le cylce : 

	init_transactions() → begin_transaction() → do_some_stuff → commit_transaction() ou abort_transaction() 


```python
conf = {
    # retries très élevé + idempotence + acks=all = tolérance aux pannes sans doublons, jusqu’à expiration du timeout de livraison.

    "bootstrap.servers": BOOTSTRAP,
    "acks": "all",                  # confirmations complètes
    "enable.idempotence": True,     # requis pour EOS
    "retries": 1000000,             # ré-essais agressifs sans doublons
    "linger.ms": 5,                 # délai d’attente (côté producteur) avant d’envoyer un lot
    "transactional.id": TXN_ID      # active les transactions
}

p = Producer(conf)


    # 1) Initialiser les transactions (une fois par process)
    p.init_transactions(timeout=10.0)

    # 2) Démarrer une transaction (typiquement par batch)
    p.begin_transaction()
    
    boucle sur i
        p.produce(TOPIC, value=f"eos-msg-{i}".encode())
        p.poll(0)

    p.commit_transaction(timeout=10.0)

    p.flush(5)

```

- `transactional.id`

    ```identifiant unique et stable par producteur → permet l'atomicité et la reprise après crash sans doublons visibles```

- `enable.idempotence=True` + `acks=all`

    ```garantit l'absence de doublons lors des ré-essais et la durabilité côté cluster```

- `init_transactions()` / `begin_transaction()` / `commit_transaction()` / `abort_transaction()`

    ```rendent l'écriture **atomique** : tout le lot est rendu visible ou rien (les lots avortés sont invisibles)```

- Côté consommateur (lecture « exactly once »)

    ```configurer `isolation.level=read_committed` pour ignorer les lots non commités. Pour un pipeline consume→process→produce, envoyer aussi les offsets via `send_offsets_to_transaction` afin d'obtenir un *end‑to‑end exactly once*.```


## consommateur : At most once

on valide (commit) l’offset avant de traiter → en cas de crash après le commit, le message est perdu (donc “au plus une fois”)

```python
conf = {
    "bootstrap.servers": "localhost:9092",
    "group.id": "tp-at-most-once",
    "enable.auto.commit": False,     # on contrôle le commit nous-mêmes
    "auto.offset.reset": "earliest", # pour l'exemple
}

c = Consumer(conf)
c.subscribe([topic])
    on fait une boucle
        # --- AT MOST ONCE: COMMIT AVANT TRAITEMENT ---
        # Valide l'offset de ce message (=> le suivant sera délivré à la prochaine poll)
        c.commit(message=msg, asynchronous=False)

        # Puis seulement on traite (si ça plante ici, le msg est perdu)
        value = msg.value().decode("utf-8") if msg.value() else ""
        print(f"[{msg.topic()} p{msg.partition()}@{msg.offset()}] {value}")

c.close()
```

## consommateur : At least one

on traite d’abord, puis on commit l’offset. En cas de crash entre les deux, le message sera re-livré ⇒ possible doublon, mais pas de perte.

```python
conf = {
    "bootstrap.servers": "localhost:9092",
    "group.id": "tp-at-least-once",
    "enable.auto.commit": False,     # on gère le commit nous-mêmes
    "auto.offset.reset": "earliest", # pour l'exemple
}

c = Consumer(conf)
c.subscribe([topic])

    boucle 
    msg = c.poll(1.0)
    
    process(msg.value())                 # 1) traitement
    # on espère que ça n'a pas planté
    c.commit(message=msg, asynchronous=False)  # 2) commit

c.close()
```


## consommateur : Exactly one

Il faut "commit"  les offsets dans une transaction Kafka (via un producteur transactionnel) : si l’appli tombe, Kafka garantit que soit tes offsets ont été committés (message traité), soit rien ne l’a été (on reconsommera)

Attention dans l'exemple qui suit on considère qu'il n'y a jamais d'erreurs... c'est une vision purement pédagogique.

```python

BOOTSTRAP = "localhost:9092"
TOPIC = "input"
GROUP_ID = "g-exactly-once"
TXN_ID = "txn-consumer-g-exactly-once"  # unique et stable pour cette appli

# Consumer: pas d'auto-commit, lecture des messages commités (transactions)
consumer = Consumer({
    "bootstrap.servers": BOOTSTRAP,
    "group.id": GROUP_ID,
    "enable.auto.commit": False,
    "auto.offset.reset": "earliest",      # on recommence au début du topic si on a pas d'autre offset encours pour ce groupe de consommateur.
    "isolation.level": "read_committed",  # pour ignorer les transactions avortées
})

# Producteur transactionnel : on l'utilise uniquement pour "commit" les offsets
producer = Producer({
    "bootstrap.servers": BOOTSTRAP,
    "transactional.id": TXN_ID,
    # enable.idempotence est implicite quand transactional.id est défini
})


producer.init_transactions()  # obligatoire avant toute transaction
consumer.subscribe([TOPIC])

    boucle
        msg = consumer.poll(1.0).  # on s'abonne au topic pendant 1.0 seconde

        #si  msg valide on le traite par exemple
            print(f"process: {msg.topic()}[{msg.partition()}]@{msg.offset()} -> {msg.value()}")

            # puis
            # --- Validation exactly-once : offset dans une transaction Kafka ---
            producer.begin_transaction()
            positions = [TopicPartition(msg.topic(), msg.partition(), msg.offset() + 1)]
            group_meta = consumer.get_consumer_group_metadata()
            producer.send_offsets_to_transaction(positions, group_meta)
            producer.commit_transaction()  # atomicité : commit offsets ou rien

consumer.close()
```