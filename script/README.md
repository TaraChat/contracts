
# Load .env

```sh
source .env
```
# Deploy the contract

```sh
forge script script/DeployTaraChatToken.s.sol:DeployTaraChatToken --rpc-url $TARAXA_RPC_URL --broadcast --legacy --private-key $PRIVATE_KEY
```

"""
output
contract addr = 0x81B4Aa2996677F54639BcF52A572D874D2554793
tx = 0x39923e4b7804f53f38c1b9b53010316978b6e6ef280fc691439346d25226d71c
https://testnet.explorer.taraxa.io/tx/0x39923e4b7804f53f38c1b9b53010316978b6e6ef280fc691439346d25226d71c
"""