FROM python:3.12-slim
WORKDIR /app
COPY consumer.py .
RUN apt-get update && apt-get install -y gcc librdkafka-dev && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir 'confluent-kafka>=2.0.0'
RUN python -c "import confluent_kafka; print(confluent_kafka.__version__)"
CMD ["python", "consumer.py"]