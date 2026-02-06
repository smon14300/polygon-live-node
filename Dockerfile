FROM alpine:3.18

# Install dependencies
RUN apk add --no-cache ca-certificates wget tar

WORKDIR /app

# Download pre-built Geth binary (guaranteed to work)
RUN wget -q -O geth.tar.gz https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.13.5-916d6a44.tar.gz && \
    tar -xzf geth.tar.gz && \
    mv geth-linux-amd64-*/geth /usr/local/bin/geth && \
    rm -rf geth-linux-amd64-* geth.tar.gz && \
    chmod +x /usr/local/bin/geth && \
    geth version

# Create Polygon genesis file
RUN cat > /app/genesis.json << 'EOF'
{
  "config": {
    "chainId": 137,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 3395000,
    "berlinBlock": 14750000,
    "londonBlock": 23850000
  },
  "difficulty": "0x1",
  "gasLimit": "0x989680",
  "alloc": {}
}
EOF

# Initialize the chain
RUN /usr/local/bin/geth init --datadir /app/data /app/genesis.json

# Create startup script
RUN cat > /app/start.sh << 'EOF'
#!/bin/sh
echo "================================"
echo "🚀 Starting Polygon Light Node"
echo "================================"
echo "Network: Polygon Mainnet (137)"
echo "Mode: Light Sync"
echo "================================"

# Remove lock files if they exist
rm -f /app/data/geth/LOCK 2>/dev/null

# Start Geth with Polygon settings
exec /usr/local/bin/geth \
  --datadir=/app/data \
  --networkid=137 \
  --syncmode=light \
  --maxpeers=50 \
  --cache=256 \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=eth,net,web3,txpool \
  --http.vhosts="*" \
  --http.corsdomain="*" \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.api=eth,net,web3,txpool \
  --ws.origins="*" \
  --port=30303 \
  --nat=any \
  --bootnodes="enode://0cb82b395094ee4a2915e9714894627de9ed8498fb881cec6db7c65e8b9a5bd7f2f25cc84e71e89d0947e51c76e85d0847de848c7782b13c0255247a6758178c@44.232.55.71:30303,enode://88116f4295f5a31538ae409e4d44ad40d22e44ee9342869e7d68bdec55b0f83c1530355ce8b41fbec0928a7d75a5745d528450d30aec92066ab6ba1ee351d710@159.203.9.164:30303" \
  --verbosity=3
EOF

RUN chmod +x /app/start.sh

EXPOSE 8545 8546 30303 30303/udp

CMD ["/app/start.sh"]
