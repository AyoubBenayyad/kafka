FROM bitnamilegacy/kafka

# Copie du script de création du topic
COPY --chmod=755 create-topic.sh /create-topic.sh

# Par défaut, lance le script au démarrage
CMD ["/create-topic.sh"]
