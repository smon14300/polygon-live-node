# Use Ubuntu 22.04 as base
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget curl ca-certificates jq tar gzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Download Erigon v2.56.0
RUN wget -q https://github.com/ledgerwatch/erigon/releases/download/v2.56.0/erigon_2.56.0_linux_amd64.tar.gz && \
    tar -xzf erigon_2.56.0_linux_amd64.tar.gz && \
    mv erigon /usr/local/bin/ && \
    chmod +x /usr/local/bin/erigon && \
    rm erigon_2.56.0_linux_amd64.tar.gz

RUN mkdir -p /data

# Create startup script with ONLY supported flags
RUN cat > /app/start.sh << 'EOF'
#!/bin/bash
set -e

echo "========================================"
echo "🚀 Starting Polygon Erigon Node"
echo "========================================"

# Clean up torrent/snapshot data
rm -rf /data/snapshots /data/downloader /data/torrent* /data/.torrent* 2>/dev/null || true

# Get external IP for NAT
EXTERNAL_IP=$(curl -s https://api.ipify.org || echo "0.0.0.0")
echo "External IP: $EXTERNAL_IP"

# Create static nodes with Polygon bootnodes
cat > /data/static-nodes.json << 'NODES'
[
  "enode://b8f1cc9c5d4403703fbf377116469667d2b1823c0daf16b7250aa576bacf399e42c3930ccfcb02c5df6879565a2b8931335565f0e8d3f8e72385ecf4a4bf160a@3.36.224.80:30303",
  "enode://8729e0c825f3d9cad382555f3e46dcff21af323e89025a0e6312df541f4a9e73abfa562d64906f5e59c51fe6f0501b3e61b07979606c56329c020ed739910759@54.194.245.5:30303",
  "enode://681ebac58d8dd2d8a6eef15329dfbad0ab960561524cf2dfde40ad646736fe5c244020f20b87e7c1520820bc625cfb487dd71d63a3a3bf0baea2dbb8ec7c79f1@34.240.245.39:30303",
  "enode://9e9224426c88db7fc89684d805e9a756e8b4a5c5e5b5c5e5b5c5e5b5c5e5b5c5@35.200.65.5:30303"
]
NODES

echo "✅ Static nodes created"
echo "✅ Starting Erigon..."

# Start Erigon with ONLY v2.56.0 supported flags
exec erigon \
  --chain=bor-mainnet \
  --datadir=/data \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=eth,net,web3,txpool,debug,trace \
  --http.vhosts=* \
  --http.corsdomain=* \
  --ws \
  --maxpeers=150 \
  --bor.withoutheimdall=true \
  --nat=extip:$EXTERNAL_IP \
  --port=30303 \
  --snapshots=false \
  --prune=htc \
  --prune.h.before=50000 \
  --prune.r.before=50000 \
  --prune.t.before=50000 \
  --prune.c.before=50000 \
  --private.api.addr=127.0.0.1:9090 \
  --log.console.verbosity=info
EOF

RUN chmod +x /app/start.sh

EXPOSE 8545 30303 30303/udp

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
  CMD curl -sf http://localhost:8545 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' || exit 1

CMD ["/app/start.sh"]
