# Bitcoin Circle STARK demo on Liquid

This repository contains everything needed to run the demo of a STARK proof verification on Liquid.

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

## Resources

- [Bitcoin Circle STARK repository](https://github.com/Bitcoin-Wildlife-Sanctuary/bitcoin-circle-stark) - [Signet Demo Transactions](https://github.com/Bitcoin-Wildlife-Sanctuary/bitcoin-circle-stark/pull/91)
- Liquid: [Website](https://blockstream.com/liquid/) - [Docs](https://docs.liquid.net/docs/welcome-to-liquid-developer-documentation-portal) - [Explorer](https://blockstream.info/liquid/)
- Catnet: [Repo](https://github.com/Bitcoin-Wildlife-Sanctuary/catnet) -[Explorer](https://catnet-mempool.btcwild.life/) - [Faucet](https://catnet-faucet.btcwild.life/)
- [How to verify ZK proofs on Bitcoin by Polyhedra](https://hackmd.io/@polyhedra/bitcoin)
