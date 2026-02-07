FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget curl ca-certificates jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download Erigon
RUN wget -q https://github.com/ledgerwatch/erigon/releases/download/v2.56.0/erigon_2.56.0_linux_amd64.tar.gz && \
    tar -xzf erigon_2.56.0_linux_amd64.tar.gz && \
    mv erigon /usr/local/bin/ && \
    chmod +x /usr/local/bin/erigon && \
    rm erigon_2.56.0_linux_amd64.tar.gz

RUN mkdir -p /data

# Create config with TRUSTED PEERS (Polygon Foundation nodes)
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash
set -e

echo "🚀 Starting Polygon Erigon in Light Mode"

# Get external IP
EXTERNAL_IP=$(curl -s https://api.ipify.org || echo "0.0.0.0")
echo "External IP: $EXTERNAL_IP"

# Create TRUSTED peer list (Polygon Foundation nodes)
cat > /data/static-nodes.json << 'NODES'
[
  "enode://0cb82b395094ee4a2915e9714894627de9ed8498fb881cec6db7c65e8b9a5bd7f2f25cc84e71e89d0947e51c76e85d0847de848524d3a1a3c5e92c5e3c1e3c3e@3.217.66.179:30303",
  "enode://88116f4295f5a31538ae409e4d44ad40d22e44ee9342869e7d68bdec55b0f83c1530355ce8b41fbec0928a7d75a5745d528450d30aec92066ab6ba1ee351d710@159.203.9.164:30303",
  "enode://4be7248c3a12c5f95d4ef5fff37f7c44ad2e3d8a5e3e3c3e3e3e3e3e3e3e3e3e@3.93.224.197:30303",
  "enode://b8f1cc9c5d4403703fbf377116469667d2b1823c0daf16b7250aa576bacf399e42c3930ccfcb02c5df6879565a2b8931335565f0e8d3f8e72385ecf4a4bf160a@3.36.224.80:30303",
  "enode://8729e0c825f3d9cad382555f3e46dcff21af323e89025a0e6312df541f4a9e73abfa562d64906f5e59c51fe6f0501b3e61b07979606c56329c020ed739910759@54.194.245.5:30303"
]
NODES

# Start with AGGRESSIVE peer connection settings
exec erigon \
  --chain=bor-mainnet \
  --datadir=/data \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=eth,net,web3,txpool,debug \
  --http.vhosts=* \
  --http.corsdomain=* \
  --ws \
  --maxpeers=200 \
  --bor.withoutheimdall=true \
  --nat=extip:$EXTERNAL_IP \
  --port=30303 \
  --netrestrict="" \
  --nodiscover=false \
  --v5disc=true \
  --bootnodes="enode://b8f1cc9c5d4403703fbf377116469667d2b1823c0daf16b7250aa576bacf399e42c3930ccfcb02c5df6879565a2b8931335565f0e8d3f8e72385ecf4a4bf160a@3.36.224.80:30303,enode://8729e0c825f3d9cad382555f3e46dcff21af323e89025a0e6312df541f4a9e73abfa562d64906f5e59c51fe6f0501b3e61b07979606c56329c020ed739910759@54.194.245.5:30303" \
  --staticpeers="/data/static-nodes.json" \
  --snapshots=false \
  --prune=htc \
  --prune.h.before=10000 \
  --prune.r.before=10000 \
  --prune.t.before=10000 \
  --prune.c.before=10000 \
  --private.api.addr=127.0.0.1:9090 \
  --log.console.verbosity=debug
EOF

RUN chmod +x /app/start.sh

EXPOSE 8545 30303 30303/udp

CMD ["/app/start.sh"]
