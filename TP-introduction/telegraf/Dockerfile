FROM telegraf:1.30

# Ajout de netcat pour wait-for-kafka.sh
RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

COPY telegraf.conf /etc/telegraf/telegraf.conf
COPY wait-for-kafka.sh /wait-for-kafka.sh

RUN chmod +x /wait-for-kafka.sh

ENTRYPOINT ["/wait-for-kafka.sh"]
