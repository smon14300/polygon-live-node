FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y wget curl jq ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download Bor (Polygon official client)
RUN wget -q https://github.com/maticnetwork/bor/releases/download/v1.2.7/bor-v1.2.7-linux-amd64.tar.gz && \
    tar -xzf bor-v1.2.7-linux-amd64.tar.gz && \
    rm bor-v1.2.7-linux-amd64.tar.gz && \
    chmod +x bor

# Create data directory
RUN mkdir -p /app/data/bor

# Create static nodes file for P2P
RUN echo '[\
  "enode://0cb82b395094ee4a2915e9714894627de9ed8498fb881cec6db7c65e8b9a5bd7f2f25cc84e71e89d0947e51c76e85d0847de848c7782b13c0255247a6758178c@44.232.55.71:30303",\
  "enode://88116f4295f5a31538ae409e4d44ad40d22e44ee9342869e7d68bdec55b0f83c1530355ce8b41fbec0928a7d75a5745d528450d30aec92066ab6ba1ee351d710@159.203.9.164:30303",\
  "enode://4be7248c3a12c5f95d4ef5fff37f7c44ad1072fdb59701b2e5987c5f3846ef448ce7eabc941c5575b13db0fb016552c1fa5cca0dda1a8008cf6d63874c0f3eb7@3.93.224.197:30303",\
  "enode://32dd20eaf75513cf84ffc9940972ab17a62e88ea753b0780ea5eca9f40f9254064dacb99508337043d944c2a41b561a17deaad45c53ea0be02663e55e6a302b2@3.212.183.151:30303"\
]' > /app/data/bor/static-nodes.json

# Expose ports
EXPOSE 8545 8546 30303

# Start command
CMD /app/bor server \
    --chain=mainnet \
    --datadir=/app/data \
    --syncmode=snap \
    --gcmode=full \
    --snapshot=false \
    --http \
    --http.addr=0.0.0.0 \
    --http.port=${PORT:-8545} \
    --http.api=eth,net,web3,txpool,bor \
    --http.vhosts=* \
    --http.corsdomain=* \
    --ws \
    --ws.addr=0.0.0.0 \
    --ws.port=8546 \
    --ws.api=eth,net,web3,txpool,bor \
    --ws.origins=* \
    --port=30303 \
    --maxpeers=50 \
    --cache=256 \
    --nat=any \
    --verbosity=3 \
    --bor.heimdall=https://heimdall-api.polygon.technology
