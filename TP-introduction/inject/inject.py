import os
import time
import random
from datetime import datetime
from influxdb_client import InfluxDBClient, Point, WritePrecision
from influxdb_client.client.write_api import SYNCHRONOUS

url = os.getenv("INFLUX_URL")
token = os.getenv("INFLUX_TOKEN")
org = os.getenv("INFLUX_ORG")
bucket = os.getenv("INFLUX_BUCKET")
interval = int(os.getenv("INTERVAL_SECONDS", "5"))

client = InfluxDBClient(url=url, token=token, org=org)
write_api = client.write_api(write_options=SYNCHRONOUS)

def simulate_temp():
    base = random.uniform(8, 18)
    return round(base + random.uniform(-2, 2), 1)

while True:
    temp = simulate_temp()
    point = (
        Point("temperature")
        .tag("ville", "Clermont-Ferrand")
        .field("value", temp)
        .time(datetime.utcnow(), WritePrecision.NS)
    )
    write_api.write(bucket=bucket, org=org, record=point)
    print(f"[Inject] Température Clermont-Ferrand : {temp}°C")
    time.sleep(interval)
