#!/bin/bash

# Liste des noms des conteneurs Kafka
brokers=("kafka-1" "kafka-2" "kafka-3")

# Boucle infinie jusqu’à interruption manuelle (Ctrl+C)
while true; do
  # Tirage au sort d’un broker
  selected_broker=${brokers[$RANDOM % ${#brokers[@]}]}
  
  echo "🔁 Tirage au sort : $selected_broker"
  
  # Pause du conteneur
  docker pause "$selected_broker"
  echo "⏸️  $selected_broker est suspendu pour 60 secondes..."
  
  # Attente
  sleep 60
  
  # Reprise
  docker unpause "$selected_broker"
  echo "▶️  $selected_broker est relancé."
  
  # Pause entre deux itérations
  echo "⏳ Attente 60s avant prochaine suspension..."
  sleep 60
done
