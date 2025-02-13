# Catnet demo

[Catnet Explorer](https://catnet-mempool.btcwild.life/) - [Catnet Faucet](https://catnet-faucet.btcwild.life/) - [Catnet Repo](https://github.com/Bitcoin-Wildlife-Sanctuary/catnet)

## Demo flow

Create initial funding transaction.

```bash
catnet-bitcoin-cli sendtoaddress $(catnet-bitcoin-cli getnewaddress) 13.4356

# Output
f1c9d553e82e0d3839f42120ec0ff31c2b0a2b7902c4dc5234e8e4941b2f77ee
```

[tx](https://catnet-mempool.btcwild.life/tx/f1c9d553e82e0d3839f42120ec0ff31c2b0a2b7902c4dc5234e8e4941b2f77ee)

Get transaction details.

```bash
catnet-bitcoin-cli gettransaction f1c9d553e82e0d3839f42120ec0ff31c2b0a2b7902c4dc5234e8e4941b2f77ee
```

FUNDING_TXID: `f1c9d553e82e0d3839f42120ec0ff31c2b0a2b7902c4dc5234e8e4941b2f77ee`

Output:

```json
{
  "amount": 0.00000000,
  "fee": -0.00002820,
  "confirmations": 0,
  "trusted": true,
  "txid": "f1c9d553e82e0d3839f42120ec0ff31c2b0a2b7902c4dc5234e8e4941b2f77ee",
  "wtxid": "62320a380dfac4259ef447a0b17ab9af927d12e9e6c21ea13d18ea8a93b8310d",
  "walletconflicts": [
  ],
  "time": 1739450446,
  "timereceived": 1739450446,
  "bip125-replaceable": "yes",
  "details": [
    {
      "address": "tb1q2gvr0ks60fluagetq2f5e9un9jp6x4lekzv849",
      "category": "send",
      "amount": -13.43560000,
      "label": "",
      "vout": 0,
      "fee": -0.00002820,
      "abandoned": false
    },
    {
      "address": "tb1q2gvr0ks60fluagetq2f5e9un9jp6x4lekzv849",
      "parent_descs": [
      ],
      "category": "receive",
      "amount": 13.43560000,
      "label": "",
      "vout": 0,
      "abandoned": false
    }
  ],
  "hex": "02000000000101cbc6c780c1390897127b59000de99d3a7633b482272b906eeaccb5fbe3abf4bb0000000000fdffffff024019155000000000160014521837da1a7a7fcea32b02934c97932c83a357f93afe559e0000000016001420d18842baa78443a5b50acdca035549a1386dfd0247304402201a3b58b6947a1df0f069023b811ba3dffa4734b6a09b9d019c1cc4e35d7ec96d0220047c15de6361122fe4a6ea26a7e1ebf586a8b8b73666f837bebea594fb72d7d10121039d5ecf2993f4cbeadab7afdf4ea67a80121390786ea54eff2adbf10f3fac9944af960000",
  "lastprocessedblock": {
    "hash": "00000002b589492adf2d224922d957dd626fdcc7274f302cce1fbd2e7566e080",
    "height": 38575
  }
}
```

Generate addresses of the program and the state caboose state.

```bash
cargo run --bin gen_demo_params
```

Output:

```text
Program Address: tb1prns2nf4f79892nl9lv5fjkjsfz4qxw233hv0z46a62z367566plse0rkau
Caboose Address: tb1qvu62dh2l4d9j09e880musdew6g5ex8n6apx72cx5zafv2mjx6r5qn2hzkf
```

Create a raw transaction to send BTC to the program and the state caboose addresses.

```bash
catnet-bitcoin-cli createrawtransaction "[{\"txid\":\"f1c9d553e82e0d3839f42120ec0ff31c2b0a2b7902c4dc5234e8e4941b2f77ee\", \"vout\": 0}]" "[{\"tb1prns2nf4f79892nl9lv5fjkjsfz4qxw233hv0z46a62z367566plse0rkau\":13.42959670}, {\"tb1qvu62dh2l4d9j09e880musdew6g5ex8n6apx72cx5zafv2mjx6r5qn2hzkf\":0.0000033}]"
```

Output:

```text
0200000001ee772f1b94e4e83452dcc402792b0a2b1cf30fec2021f439380d2ee853d5c9f10000000000fdffffff0236f00b50000000002251201ce0a9a6a9f14e554fe5fb28995a5048aa0339518dd8f1575dd2851d7a9ad07f4a010000000000002200206734a6dd5fab4b2797273bf7c8372ed229931e7ae84de560d41752c56e46d0e800000000
```

Sign the transaction.

```bash
catnet-bitcoin-cli signrawtransactionwithwallet "0200000001ee772f1b94e4e83452dcc402792b0a2b1cf30fec2021f439380d2ee853d5c9f10000000000fdffffff0236f00b50000000002251201ce0a9a6a9f14e554fe5fb28995a5048aa0339518dd8f1575dd2851d7a9ad07f4a010000000000002200206734a6dd5fab4b2797273bf7c8372ed229931e7ae84de560d41752c56e46d0e800000000"
```

Output:

```json
{
  "hex": "02000000000101ee772f1b94e4e83452dcc402792b0a2b1cf30fec2021f439380d2ee853d5c9f10000000000fdffffff0236f00b50000000002251201ce0a9a6a9f14e554fe5fb28995a5048aa0339518dd8f1575dd2851d7a9ad07f4a010000000000002200206734a6dd5fab4b2797273bf7c8372ed229931e7ae84de560d41752c56e46d0e80247304402206f2f5931cadcf9abb845d44e7594625649fbaa0c3febd33d90f1b72638618cc102206efeaef454918fa322e8192b8a9ec08f22414c84381fd9c73c398463ca66cd680121039955f794dbff4e8fd022946e3815718c66025cccce2691ab09c4625fb4d242fd00000000",
  "complete": true
}
```

Send the transaction to the network.

```bash
catnet-bitcoin-cli sendrawtransaction "02000000000101ee772f1b94e4e83452dcc402792b0a2b1cf30fec2021f439380d2ee853d5c9f10000000000fdffffff0236f00b50000000002251201ce0a9a6a9f14e554fe5fb28995a5048aa0339518dd8f1575dd2851d7a9ad07f4a010000000000002200206734a6dd5fab4b2797273bf7c8372ed229931e7ae84de560d41752c56e46d0e80247304402206f2f5931cadcf9abb845d44e7594625649fbaa0c3febd33d90f1b72638618cc102206efeaef454918fa322e8192b8a9ec08f22414c84381fd9c73c398463ca66cd680121039955f794dbff4e8fd022946e3815718c66025cccce2691ab09c4625fb4d242fd00000000"
```

[tx](https://catnet-mempool.btcwild.life/tx/4ed6667656131c226658d7e20d9b7ea8505e11710427f6c66a267aa107fcaa2c)

Output:

```text
4ed6667656131c226658d7e20d9b7ea8505e11710427f6c66a267aa107fcaa2c
```

FUNDING_TXID: `f1c9d553e82e0d3839f42120ec0ff31c2b0a2b7902c4dc5234e8e4941b2f77ee`
INITIAL_PROGRAM_TXID: `4ed6667656131c226658d7e20d9b7ea8505e11710427f6c66a267aa107fcaa2c`

Run the demo program again with the funding txid and the initial program txid.

```bash
cargo run --bin demo -- -f f1c9d553e82e0d3839f42120ec0ff31c2b0a2b7902c4dc5234e8e4941b2f77ee -i 4ed6667656131c226658d7e20d9b7ea8505e11710427f6c66a267aa107fcaa2c
```

Output:

```text
================= INSTRUCTIONS =================
All 72 transactions have been generated and stored in the current directory.
```

After this, you have a directory containing the 72 transactions.


