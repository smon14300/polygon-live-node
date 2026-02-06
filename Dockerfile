FROM ethereum/client-go:v1.13.5

WORKDIR /app

# Polygon genesis
RUN echo '{"config":{"chainId":137},"difficulty":"0x1","gasLimit":"0x989680"}' > genesis.json

# Initialize
RUN geth init --datadir /data genesis.json

# Start script
RUN echo '#!/bin/sh\n\
geth --datadir=/data \
  --networkid=137 \
  --syncmode=light \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.api=eth,net,web3 \
  --http.vhosts="*" \
  --http.corsdomain="*" \
  --port=30303 \
  --maxpeers=50 \
  --cache=256 \
  --nat=any' > /start.sh && chmod +x /start.sh

EXPOSE 8545 30303

CMD ["/start.sh"]
