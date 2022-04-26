# *Sig X*


## Problem
Voting on L1 is expensive.

## TL;DR
The goal of the project is to design a system where participants can take decisions on L2 and execute it on L1. </br>

**Example** </br>
DAO taking a decision on L2 about fund allocation, where to allocate money and to whom. </br>

Work flow :
- Have an L2 multi sig contract (for example our multisig_l2l1.cairo).
- Have an L1 contract that consume messages from this specific L2 governance contract, in DAO example L1 consumes message with payload including the address of the recipient and amount of allocation.
- Submit a transaction with L1 target contract and the payload to be consumed.
- Vote.
- If successful execute and send message to L1.
- Consume message by L1 contract and allocate funds.

## Contracts Description

### multisig_l2l1.cairo: L2 Multi Sig Contract ERC20 Transfer
Contract allowing owners to set a threshold of required confirmations and send a payload data to L1 to be consumed by the specified L1 contract once enough confirmations are reached. </br>
Address: [Contract](https://goerli.voyager.online/contracts/0x01470297d544ad1f338376f77cad34ff6cc03b5fa89e5c952d437ca5f7194044) </br>

#### L1 Target example  - Goerli - Verified
Example of Target contract the consumed a decision made on L2 </br>
Decision is to increase a storage variable in this case. </br>
[Contract](https://goerli.etherscan.io/address/0xf18a5b57d9848cd8ae8c3ce044dae95ac93bd039#readContract)


### multisig_tx.cairo: L2 Multi Sig Arbitrat function call on L2
Contract allowing owners to set a threshold of required confirmations and execute an arbitray transaction payload on L2 once enough confirmations are reached. </br>
Address: [Contract](https://goerli.voyager.online/contracts/0x00145f47b4ad5da8d201d4f2a651a28b11b26baa33634cb55f0b94c0d416edfb) </br>


### multisig.cairo: L2 Multi Sig Contract ERC20 Transfer
Contract allowing owners to set a threshold of required confirmations and execute and ERC20 transfer once enough confirmations are reached.  </br>
Address: [Contract](https://goerli.voyager.online/contracts/0x056ead718904883267826c62fd9d29f8c1d7b6287f648cd5d9cafd1de22334e2) </br>
