#!/bin/sh

INFLUX_URL="http://influxdb:8086"
INFLUX_TOKEN="mytoken"
ORG_NAME="myorg"
BUCKET="weather"

echo "⏳ Attente qu'InfluxDB soit prêt..."
until curl -sf "$INFLUX_URL/health" | grep -q '"status":"pass"'; do
  sleep 1
done
echo "✅ InfluxDB est prêt"

echo "🔍 Récupération de l'orgID pour '$ORG_NAME'..."
org_id=$(curl -s -H "Authorization: Token $INFLUX_TOKEN" "$INFLUX_URL/api/v2/orgs" | grep id | cut -d'"' -f4)

if [ -z "$org_id" ]; then
  echo "❌ orgID introuvable pour l'organisation '$ORG_NAME'"
  exit 1
fi
echo "✅ orgID trouvé : $org_id"

echo "🔍 Vérification de l'existence du check..."
existing_check_id=$(curl -sS -H "Authorization: Token $INFLUX_TOKEN" \
  "$INFLUX_URL/api/v2/checks?org=$ORG_NAME" | grep -B 10 '"name": "push_to_kafka"' | grep '"id":' | head -n1 | awk -F'"' '{print $4}')

if [ -n "$existing_check_id" ]; then
  echo "🧹 Suppression de l'ancien check (ID=$existing_check_id)..."
  curl -sS -X DELETE "$INFLUX_URL/api/v2/checks/$existing_check_id" \
    -H "Authorization: Token $INFLUX_TOKEN"
fi

echo "🚀 Création du nouveau check push_to_kafka..."
check_response=$(curl -sS -X POST "$INFLUX_URL/api/v2/checks" \
  -H "Authorization: Token $INFLUX_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "threshold",
    "name": "push_to_kafka",
    "orgID": "'"$org_id"'",
    "status": "active",
    "every": "1s",
    "query": {
      "text": "from(bucket: \"'"$BUCKET"'\") |> range(start: -2s) |> filter(fn: (r) => r._field == \"temperature\")"
    },
    "thresholds": [{
      "level": "INFO",
      "allValues": true,
      "type": "greater",
      "value": 0
    }],
    "statusMessageTemplate": "New data for kafka",
    "labels": [],
    "tags": []
  }')

check_id=$(echo "$check_response" | grep '"id":' | head -n1 | awk -F'"' '{print $4}')

echo "✅ Check 'push_to_kafka' créé avec succès"

echo "🔌 Création du endpoint 'telegraf_listener'..."
endpoint_response=$(curl -sS -X POST "$INFLUX_URL/api/v2/notificationEndpoints" \
  -H "Authorization: Token $INFLUX_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "telegraf_listener",
    "type": "http",
    "description": "Send alert to Telegraf HTTP listener",
    "url": "http://telegraf:8186/api/v2/write",
    "method": "POST",
    "authMethod": "none",
    "contentTemplate": "weather,ville=Alert temperature=42",
    "orgID": "'"$org_id"'",
    "status": "active"
  }')

endpoint_id=$(echo "$endpoint_response" | grep '"id":' | head -n1 | awk -F'"' '{print $4}')

echo "✅ Endpoint créé avec ID : $endpoint_id"

echo "📬 Création de la notification rule 'notify_telegraf'..."
curl -sS -X POST "$INFLUX_URL/api/v2/notificationRules" \
  -H "Authorization: Token $INFLUX_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "notify_telegraf",
    "orgID": "'"$org_id"'",
    "endpointID": "'"$endpoint_id"'",
    "every": "1s",
    "status": "active",
    "statusRules": [{ "currentLevel": "INFO" }],
    "tagRules": [],
    "description": "Trigger Telegraf when check passes",
    "labels": [],
    "limit": 100,
    "offset": 0
  }'

echo "✅ Notification rule créée avec succès"
