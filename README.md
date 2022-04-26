# starkthon-mutlisig-wallet

## Contracts Description


### multisig.cairo: L2 Multi Sig Contract ERC20 Transfer
Contract allowing owners to set a threshold of required confirmations and execute and ERC20 transfer once enough confirmations are reached.

### multisig_tx.cairo: L2 Multi Sig Contract ERC20 Transfer
Contract allowing owners to set a threshold of required confirmations and execute an arbitray transaction payload on L2 once enough confirmations are reached.

### multisig_l2l1.cairo: L2 Multi Sig Contract ERC20 Transfer
Contract allowing owners to set a threshold of required confirmations and send a payload data to L1 to be consumed by the specified L1 contract once enough confirmations are reached.

## Deployed Contract Examples



### L2 Multi Sig Contract ERC20 Transfer - Goerli
[Contract](https://goerli.voyager.online/contracts/0x056ead718904883267826c62fd9d29f8c1d7b6287f648cd5d9cafd1de22334e2) </br>
Address: 0x056ead718904883267826c62fd9d29f8c1d7b6287f648cd5d9cafd1de22334e2

### L2 Multi Sig Contract - Arbitrat function call - Goerli
[Contract](https://goerli.voyager.online/contracts/0x00145f47b4ad5da8d201d4f2a651a28b11b26baa33634cb55f0b94c0d416edfb) </br>
Address: 0x00145f47b4ad5da8d201d4f2a651a28b11b26baa33634cb55f0b94c0d416edfb


### L2L1 Multi Sig Contract - Goerli
[Contract](https://goerli.voyager.online/contracts/0x01470297d544ad1f338376f77cad34ff6cc03b5fa89e5c952d437ca5f7194044) </br>
Address: 0x019e013dcbab0cc9c2268aab7fe92742183add1ef1bb454602695b25ca3db9f5

### L1 Target example  - Goerli - Verified
Example of Target contract consuming a decision made on L2 </br>
[Contract](https://goerli.etherscan.io/address/0xf18a5b57d9848cd8ae8c3ce044dae95ac93bd039#readContract)
