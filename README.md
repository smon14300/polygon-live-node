# polygon-live-node
Polygon lightweight node for live data

# 🟣 Polygon Live Node

Ultra-lightweight Polygon node - NO 4TB download!

## Features
- ✅ Live data only (last ~100 blocks)
- ✅ Less than 1GB disk usage
- ✅ P2P peer connections
- ✅ WebSocket support
- ✅ Free tier compatible

## Deploy to Render

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy)

## After Deployment

Your RPC URL: `https://YOUR-APP-NAME.onrender.com`

## Test Commands

```bash
# Get block number
curl -X POST https://YOUR-APP-NAME.onrender.com \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Get peer count  
curl -X POST https://YOUR-APP-NAME.onrender.com \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}'
