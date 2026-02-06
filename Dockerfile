FROM thorax/erigon:v2.53.4

USER root
RUN apk add --no-cache python3 py3-pip curl

WORKDIR /app
RUN mkdir -p /app/erigon_data

COPY erigon_launcher.py /app/erigon_launcher.py

# Standard RPC and Engine/P2P ports
EXPOSE 8545 30303 30303/udp

ENTRYPOINT ["python3", "-u", "/app/erigon_launcher.py"]
