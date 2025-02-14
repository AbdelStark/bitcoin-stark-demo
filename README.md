# Bitcoin Circle STARK demo

This repository contains everything needed to run the demo of a STARK proof verification on various Bitcoin OP_CAT enabled networks.

## Demo

### Catnet

```text
signet=1
deprecatedrpc=create_bdb
txindex=1
prune=0
server=1
fallbackfee=0.0002
maxmempool=10000
limitancestorsize=200000
limitdescendantsize=200000

[signet]
daemon=1
signetchallenge=5121027be9dab7dfc2d1b9aac03f883b9a229fc9c298770dec626b2acbf39e9b6e0e0c51ae
rpcallowip=0.0.0.0/0  # Caution: This allows all IPs; consider narrowing this range for production use
rpcbind=0.0.0.0       # This binds the RPC server to all network interfaces
rpcbind=::   
rpcport=38332
rpcuser=catnet
rpcpassword=stark
limitancestorcount=250
limitdescendantcount=250
```

#### Full demo

```bash
# Run without breakpoints
./scripts/full_demo.sh

# Run with breakpoints
./scripts/full_demo.sh -b

# Specify custom transcript and params files
./scripts/full_demo.sh -t custom_transcript.log -p custom_params.env
```

#### Individual steps

```bash
# Normal mode - actually sends transactions
./scripts/send_demo_txs.sh ./catnet-txs

# Dry run mode - simulates sending transactions
./scripts/send_demo_txs.sh --dry-run ./catnet-txs
# or
./scripts/send_demo_txs.sh -d ./catnet-txs
```

Transaction flow strategy:

```bash
# Default strategy (sequential)
./scripts/send_demo_txs.sh ./catnet-txs

# Timed strategy with 5 second pause
./scripts/send_demo_txs.sh -s timed -p 5 ./catnet-txs
# or
TX_FLOW_STRATEGY=timed TX_PAUSE_SECONDS=5 ./scripts/send_demo_txs.sh ./catnet-txs

# Per-block strategy with 5 transactions per block
./scripts/send_demo_txs.sh -s per-block -n 5 ./catnet-txs
# or
TX_FLOW_STRATEGY=per-block TX_PER_BLOCK=5 ./scripts/send_demo_txs.sh ./catnet-txs
```

## Resources

- [Bitcoin Circle STARK repository](https://github.com/Bitcoin-Wildlife-Sanctuary/bitcoin-circle-stark) - [Signet Demo Transactions](https://github.com/Bitcoin-Wildlife-Sanctuary/bitcoin-circle-stark/pull/91)
- Liquid: [Website](https://blockstream.com/liquid/) - [Docs](https://docs.liquid.net/docs/welcome-to-liquid-developer-documentation-portal) - [Explorer](https://blockstream.info/liquid/)
- Catnet: [Repo](https://github.com/Bitcoin-Wildlife-Sanctuary/catnet) -[Explorer](https://catnet-mempool.btcwild.life/) - [Faucet](https://catnet-faucet.btcwild.life/)
- [How to do Circle STARK math in Bitcoin?](https://hackmd.io/@l2iterative/SyOrddd9C)
- [How to verify ZK proofs on Bitcoin by Polyhedra](https://hackmd.io/@polyhedra/bitcoin)

