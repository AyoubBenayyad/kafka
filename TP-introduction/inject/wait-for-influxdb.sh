#!/bin/sh

echo "⏳ Attente que InfluxDB soit prêt sur $INFLUX_URL..."

until curl -s --fail "$INFLUX_URL/health" > /dev/null; do
  sleep 2
done

echo "✅ InfluxDB est prêt. Démarrage du script inject.py"
exec python inject.py
