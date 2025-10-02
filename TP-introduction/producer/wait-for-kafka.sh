#!/bin/sh

echo "⏳ Attente que Kafka soit prêt sur $KAFKA_BOOTSTRAP..."

HOST=$(echo "$KAFKA_BOOTSTRAP" | cut -d',' -f1)

until nc -z $(echo "$HOST" | cut -d':' -f1) $(echo "$HOST" | cut -d':' -f2); do
  sleep 2
done

echo "✅ Kafka est prêt. Lancement du producer.py"
exec python producer.py
