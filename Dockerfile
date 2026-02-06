# Use the correct, updated repository
FROM erigontech/erigon:v3.3.7

USER root
RUN apk add --no-cache python3 py3-pip curl

WORKDIR /app
RUN mkdir -p /app/erigon_data

# Copy the launcher
COPY erigon_launcher.py /app/erigon_launcher.py

# Expose HTTP (8545) and WSS (8546)
EXPOSE 8545 8546 30303 30303/udp

ENTRYPOINT ["python3", "-u", "/app/erigon_launcher.py"]
