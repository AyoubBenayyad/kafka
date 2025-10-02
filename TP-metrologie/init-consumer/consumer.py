import os
import time
import random
from confluent_kafka import Consumer, KafkaException

BROKER = os.getenv("BROKER", "kafka-1:9092")
TOPIC = os.getenv("TOPIC", "weather")
GROUP_ID = os.getenv("GROUP_ID", "weather-group")
CLIENT_ID = os.getenv("CLIENT_ID", f"consumer-{random.randint(1000,9999)}")

conf = {
    'bootstrap.servers': BROKER,
    'group.id': GROUP_ID,
    'client.id': CLIENT_ID,
    'auto.offset.reset': 'earliest',
    'enable.auto.commit': True
}

consumer = Consumer(conf)
consumer.subscribe([TOPIC])

print(f"[{CLIENT_ID}] Starting consumption on topic '{TOPIC}'...")

last_pause = time.time()

try:
    while True:
        msg = consumer.poll(1.0)
        if msg is None:
            continue
        if msg.error():
            print(f"[{CLIENT_ID}] Error: {msg.error()}")
            continue

        print(f"[{CLIENT_ID}] {msg.key().decode('utf-8')}: {msg.value().decode('utf-8')}")

        if time.time() - last_pause >= 60:
            pause = random.uniform(1, 5)
            print(f"[{CLIENT_ID}] Sleeping for {pause:.1f} seconds.")
            time.sleep(pause)
            last_pause = time.time()

except KeyboardInterrupt:
    print(f"[{CLIENT_ID}] Interrupted. Shutting down...")

finally:
    consumer.close()
