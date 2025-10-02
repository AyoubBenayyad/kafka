#!/bin/bash

set -e

# Liste des hôtes Kafka à tester
HOSTS=(kafka1 kafka2 kafka3)
PORT=9092

for host in "${HOSTS[@]}"; do
  echo "⌛ Attente de $host:$PORT..."
  while ! nc -z "$host" "$PORT"; do
    sleep 2
  done
  echo "✅ $host:$PORT est disponible"
done

echo "🚀 Lancement de Telegraf..."
exec telegraf
