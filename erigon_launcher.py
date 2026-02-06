import os
import subprocess
import threading
import time
import json
import requests as req

CONFIG = {
    'CHAIN': 'bor-mainnet',
    'HTTP_PORT': 8545,
    'DATA': "/app/erigon_data"
}

def setup():
    os.makedirs(CONFIG['DATA'], exist_ok=True)
    # Fast-discovery nodes for Polygon Bor
    nodes = [
        "enode://4cd540c2c3d43c5953e420ad9ab80e43a92cca78a3e79de378858ccad56b6d9f8f5b9a37fa7bed6ae4f6d2c56fd157e569c7d7f20b3d258c5ef7a47a74c22c4a@35.246.41.81:30303",
        "enode://aa36fdf33dd030378a0168c856d18b37f1e44caa13ed9315817a2b6f0fedc854c11c02af0a30a1a59e493adf52a90b0d40b6a8e52f6f4e9b1de3f7c6de7c1b8e@34.89.218.245:30303"
    ]
    with open(f"{CONFIG['DATA']}/static-nodes.json", 'w') as f:
        json.dump(nodes, f, indent=2)

def rpc(method, params=[]):
    try:
        r = req.post(f"http://localhost:{CONFIG['HTTP_PORT']}", 
                     json={"jsonrpc":"2.0","method":method,"params":params,"id":1}, timeout=1)
        return r.json().get('result')
    except: return None

setup()

# ERIGON 3 LIVE FLAGS
cmd = [
    "erigon",
    f'--chain={CONFIG["CHAIN"]}',
    f'--datadir={CONFIG["DATA"]}',
    '--http', '--http.addr=0.0.0.0', f'--http.port={CONFIG["HTTP_PORT"]}',
    '--ws', # Enable WebSockets
    '--http.api=eth,net,web3,txpool,debug',
    '--maxpeers=100',
    '--bor.withoutheimdall=true',
    '--prune.mode=minimal',     # NO HISTORY - LIVE DATA ONLY
    '--sync.mode=snap',         # Fastest way to reach the head
    '--txpool.globalslots=50000', # Large pool for pending tx monitoring
]

print("🚀 Starting Live Polygon Node (Erigon 3)...")
process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

def monitor():
    while True:
        time.sleep(2)
        stats = rpc("txpool_status")
        blk = rpc("eth_blockNumber")
        
        if stats:
            p = int(stats.get('pending', '0x0'), 16)
            b = int(blk, 16) if blk else "Syncing Headers..."
            print(f"🔥 [LIVE] Block: {b} | Pending Txs: {p}")
        
        if process.poll() is not None:
            print("❌ Erigon stopped unexpectedly.")
            break

threading.Thread(target=monitor, daemon=True).start()

try:
    for line in process.stdout:
        # Only print important sync/pool info to keep Render logs clean
        if any(x in line.lower() for x in ["stage=", "new block", "pool", "error"]):
            print(line.strip())
except KeyboardInterrupt:
    process.terminate()
