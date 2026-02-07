# Use Ubuntu 22.04 as base
FROM ubuntu:22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    jq \
    tar \
    gzip \
    && rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Download and install Erigon (latest stable version)
RUN wget https://github.com/ledgerwatch/erigon/releases/download/v2.58.1/erigon_2.58.1_linux_amd64.tar.gz && \
    tar -xzf erigon_2.58.1_linux_amd64.tar.gz && \
    mv erigon /usr/local/bin/ && \
    chmod +x /usr/local/bin/erigon && \
    rm erigon_2.58.1_linux_amd64.tar.gz

# Create data directory
RUN mkdir -p /data

# Create static-nodes.json with Polygon Bor bootnodes
RUN echo '[\n\
  "enode://b8f1cc9c5d4403703fbf377116469667d2b1823c0daf16b7250aa576bacf399e42c3930ccfcb02c5df6879565a2b8931335565f0e8d3f8e72385ecf4a4bf160a@3.36.224.80:30303",\n\
  "enode://8729e0c825f3d9cad382555f3e46dcff21af323e89025a0e6312df541f4a9e73abfa562d64906f5e59c51fe6f0501b3e61b07979606c56329c020ed739910759@54.194.245.5:30303",\n\
  "enode://681ebac58d8dd2d8a6eef15329dfbad0ab960561524cf2dfde40ad646736fe5c244020f20b87e7c1520820bc625cfb487dd71d63a3a3bf0baea2dbb8ec7c79f1@34.240.245.39:30303"\n\
]' > /data/static-nodes.json

# Expose ports
# 8545 = HTTP RPC
# 8546 = WebSocket
# 30303 = P2P (TCP and UDP)
EXPOSE 8545 8546 30303 30303/udp

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:8545 -X POST -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' || exit 1

# Start Erigon with optimized flags for live data only
CMD ["erigon", \
     "--chain=bor-mainnet", \
     "--datadir=/data", \
     "--http", \
     "--http.addr=0.0.0.0", \
     "--http.port=8545", \
     "--http.api=eth,net,web3,txpool,debug,trace", \
     "--http.vhosts=*", \
     "--http.corsdomain=*", \
     "--ws", \
     "--ws.addr=0.0.0.0", \
     "--ws.port=8546", \
     "--ws.api=eth,net,web3,txpool,debug,trace", \
     "--ws.origins=*", \
     "--maxpeers=100", \
     "--bor.withoutheimdall=true", \
     "--nat=extip:0.0.0.0", \
     "--port=30303", \
     "--authrpc.port=8551", \
     "--snap.stop", \
     "--torrent.download.rate=0", \
     "--torrent.upload.rate=0", \
     "--prune=htc", \
     "--prune.h.before=100000", \
     "--prune.r.before=100000", \
     "--prune.t.before=100000", \
     "--prune.c.before=100000", \
     "--log.console.verbosity=info"]
