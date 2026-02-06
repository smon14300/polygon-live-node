# Use Python base to ensure pip/python work perfectly
FROM python:3.10-slim

# Install system dependencies
RUN apt-get update && apt-get install -y curl wget procps && rm -rf /var/lib/apt/lists/*

# Download Erigon Binary (v3.0.0-alpha for best "Minimal" support)
RUN wget https://github.com/erigontech/erigon/releases/download/v3.0.0-alpha2/erigon_3.0.0-alpha2_linux_amd64.tar.gz \
    && tar -xvf erigon_3.0.0-alpha2_linux_amd64.tar.gz \
    && mv erigon /usr/local/bin/erigon \
    && rm erigon_3.0.0-alpha2_linux_amd64.tar.gz

WORKDIR /app
RUN mkdir -p /app/erigon_data

# Install Python requests for the monitor script
RUN pip install requests

COPY erigon_launcher.py /app/erigon_launcher.py

# Expose RPC and WSS
EXPOSE 8545 8546

ENTRYPOINT ["python3", "-u", "/app/erigon_launcher.py"]
