import os
import time
import json
from datetime import datetime, timedelta, timezone
from influxdb_client import InfluxDBClient
from kafka import KafkaProducer


INFLUX_URL = os.getenv("INFLUX_URL")
INFLUX_TOKEN = os.getenv("INFLUX_TOKEN")
INFLUX_ORG = os.getenv("INFLUX_ORG")
INFLUX_BUCKET = os.getenv("INFLUX_BUCKET")
INTERVAL = int(os.getenv("INTERVAL_SECONDS", "5"))
KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP").split(",")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC")

client = InfluxDBClient(url=INFLUX_URL, token=INFLUX_TOKEN, org=INFLUX_ORG)
query_api = client.query_api()
producer = KafkaProducer(
    bootstrap_servers=KAFKA_BOOTSTRAP,
    value_serializer=lambda v: json.dumps(v).encode("utf-8"),
    key_serializer=lambda k: k.encode("utf-8")
)


last_ts = datetime.now(timezone.utc) - timedelta(minutes=1)

def fetch_new_points():
    global last_ts
    flux_query = f'''
    from(bucket: "{INFLUX_BUCKET}")
      |> range(start: {last_ts.isoformat()})
      |> filter(fn: (r) => r._measurement == "temperature")
    '''
    result = query_api.query(flux_query)
    for table in result:
        for record in table.records:
            ville = record.values.get("ville", "Unknown")
            payload = {
                "ville": ville,
                "temperature": record.get_value(),
                "timestamp": record.get_time().isoformat()
            }
            producer.send(KAFKA_TOPIC, key=ville, value=payload)
            print(f"Envoyé à Kafka : {payload}")
            last_ts = max(last_ts, record.get_time())

while True:
    fetch_new_points()
    time.sleep(INTERVAL)
