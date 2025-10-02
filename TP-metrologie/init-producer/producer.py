from confluent_kafka import Producer, KafkaException
from confluent_kafka.admin import AdminClient
import os, random, time

BROKER = os.getenv("BROKER", "kafka-1:9092")
TOPIC = os.getenv("TOPIC", "weather")
CITIES = [
    "Paris", "Marseille", "Lyon", "Toulouse", "Nice",
    "Nantes", "Montpellier", "Strasbourg", "Bordeaux", "Lille"
]
N_MESSAGES = 1_000_000_000

def wait_for_topic(broker, topic, timeout=60):
    admin = AdminClient({'bootstrap.servers': broker})
    for i in range(timeout):
        try:
            md = admin.list_topics(timeout=3)
            if topic in md.topics:
                print(f"Topic '{topic}' is ready!")
                return True
            print(f"Waiting for topic '{topic}' to be created... ({i+1}/{timeout})")
        except KafkaException as e:
            print(f"Kafka not reachable yet: {e}")
        time.sleep(2)
    raise TimeoutError(f"Topic '{topic}' not found after {timeout*2} seconds.")

def main():
    wait_for_topic(BROKER, TOPIC)
    conf = {
        'bootstrap.servers': BROKER,
        'queue.buffering.max.messages': 200000,    # optionnel, augmente le buffer
        'message.send.max.retries': 10,            # optionnel, plus de tentatives
        'retry.backoff.ms': 500,                   # optionnel
        'socket.timeout.ms': 10000
    }
    p = Producer(conf)
    delivered = 0
    for i in range(N_MESSAGES):
        city = random.choice(CITIES)
        temperature = round(random.uniform(-5, 40), 1)
        msg = f'{{"city":"{city}","temperature":{temperature},"ts":{int(time.time())}}}'
        sent = False
        while not sent:
            try:
                p.produce(TOPIC, key=city, value=msg)
                sent = True
            except BufferError:
                # Buffer plein, on attend un peu puis on flush
                print("Buffer full, flushing…")
                p.flush(2)  # attend jusqu’à 2s, libère de la place
                time.sleep(0.2)
        if i % 10000 == 0:
            print(f"{i} messages produced...")
        if i % 1000 == 0:
            p.poll(0)
            duree = random.uniform(1, 10)
            time.sleep(duree)
    p.flush()
    print("Finished producing 1M messages.")

if __name__ == "__main__":
    main()
