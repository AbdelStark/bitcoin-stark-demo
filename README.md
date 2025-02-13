# Bitcoin Circle STARK demo

This repository contains everything needed to run the demo of a STARK proof verification on various Bitcoin OP_CAT enabled networks.

## Demo

### Catnet

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
- [How to verify ZK proofs on Bitcoin by Polyhedra](https://hackmd.io/@polyhedra/bitcoin)
