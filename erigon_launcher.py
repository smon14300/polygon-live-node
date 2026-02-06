import os
import subprocess
import threading
import time
import json
import requests as req

CONFIG = {
    'CHAIN': 'bor-mainnet',
    'HTTP_PORT': 8545,
    'LOCAL_DATA': "/app/erigon_data",
    'LOCAL_BIN': "erigon"
}

def setup_node():
    print("📡 Setting up Static Nodes for fast discovery...")
    os.makedirs(CONFIG['LOCAL_DATA'], exist_ok=True)
    nodes = [
        "enode://4cd540c2c3d43c5953e420ad9ab80e43a92cca78a3e79de378858ccad56b6d9f8f5b9a37fa7bed6ae4f6d2c56fd157e569c7d7f20b3d258c5ef7a47a74c22c4a@35.246.41.81:30303",
        "enode://aa36fdf33dd030378a0168c856d18b37f1e44caa13ed9315817a2b6f0fedc854c11c02af0a30a1a59e493adf52a90b0d40b6a8e52f6f4e9b1de3f7c6de7c1b8e@34.89.218.245:30303"
    ]
    with open(f"{CONFIG['LOCAL_DATA']}/static-nodes.json", 'w') as f:
        json.dump(nodes, f, indent=2)

def rpc_call(method, params=[]):
    try:
        payload = {"jsonrpc":"2.0","method":method,"params":params,"id":1}
        r = req.post(f"http://localhost:{CONFIG['HTTP_PORT']}", json=payload, timeout=2)
        return r.json().get('result')
    except:
        return None

setup_node()

# SPEED OPTIMIZED FLAGS
# --p2p.protocol=68: Forces newer protocol for faster swaps
# --prune=hrtc: Prunes History, Receipts, TxLookup, and Callers (keeps node light)
cmd = [
    CONFIG['LOCAL_BIN'],
    f'--chain={CONFIG["CHAIN"]}',
    f'--datadir={CONFIG["LOCAL_DATA"]}',
    '--http',
    '--http.addr=0.0.0.0',
    f'--http.port={CONFIG["HTTP_PORT"]}',
    '--http.api=eth,net,web3,txpool,debug',
    '--maxpeers=100',
    '--bor.withoutheimdall=true',
    '--private.api.addr=localhost:9090',
    '--prune=hrtc',             # Prune everything to stay light
    '--txpool.globalslots=10000', # Increase pool size for live data
    '--txpool.pending=true',
    '--nodiscover=false'
]

print(f"🚀 Starting Live Erigon...")
process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

def monitor_txpool():
    while True:
        time.sleep(2) # Fast updates
        stats = rpc_call("txpool_status")
        if stats:
            pending = int(stats.get('pending', '0x0'), 16)
            queued = int(stats.get('queued', '0x0'), 16)
            print(f"⚡ LIVE TX POOL | Pending: {pending} | Queued: {queued}")
        
        # Get latest block hash
        latest = rpc_call("eth_getBlockByNumber", ["latest", False])
        if latest:
            print(f"📦 Latest Block: {int(latest['number'], 16)} | Hash: {latest['hash'][:10]}...")

# Run monitor in background
threading.Thread(target=monitor_txpool, daemon=True).start()

# Keep main process alive and pipe logs
try:
    for line in process.stdout:
        if "pause" not in line.lower(): # Filter out boring logs
            print(line.strip())
except KeyboardInterrupt:
    process.terminate()
