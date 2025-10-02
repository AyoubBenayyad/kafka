#!/bin/bash
set -e

# Variables (adapte si cluster compose, ex: kafka-1:9092)
KAFKA_BROKER="${KAFKA_BROKER:-kafka-1:9092}"
TOPIC_NAME="weather"
PARTITIONS=4
REPLICATION=3

echo "Waiting for Kafka broker at $KAFKA_BROKER to be available..."
for i in {1..30}; do
    if /opt/bitnami/kafka/bin/kafka-topics.sh --bootstrap-server "$KAFKA_BROKER" --list; then
        echo "Kafka broker is up!"
        break
    fi
    echo "Waiting ($i)..."
    sleep 2
done

echo "Creating topic $TOPIC_NAME (partitions: $PARTITIONS, RF: $REPLICATION)..."
# --if-not-exists avoids error if already created
/opt/bitnami/kafka/bin/kafka-topics.sh \
  --create \
  --if-not-exists \
  --topic "$TOPIC_NAME" \
  --bootstrap-server "$KAFKA_BROKER" \
  --partitions "$PARTITIONS" \
  --replication-factor "$REPLICATION"

echo "Topic $TOPIC_NAME created (or already exists)."
