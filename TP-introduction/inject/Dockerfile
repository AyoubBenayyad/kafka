FROM python:3.11-slim

WORKDIR /app

# Ajout de curl
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY inject.py .
COPY wait-for-influxdb.sh .
RUN chmod +x wait-for-influxdb.sh

CMD ["./wait-for-influxdb.sh"]
