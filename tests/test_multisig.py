# """contract.cairo test file."""
# import os

# import pytest
# from starkware.starknet.testing.starknet import Starknet
# from nile.signer import Signer

# SIGNER1 = Signer(1)
# SIGNER2 = Signer(2)
# SIGNER3 = Signer(3)

# # The path to the contract source code.
# CONTRACT_FILE = os.path.join("contracts", "multisig.cairo")


# @pytest.mark.asyncio
# async def test_increase_balance():
#     """Test increase_balance method."""
#     # Create a new Starknet class that simulates the StarkNet
#     # system.
#     starknet = await Starknet.empty()

#     # Deploy the contract.
#     contract = await starknet.deploy(
#         source=CONTRACT_FILE,
#     )

#     # Invoke increase_balance() twice.
#     await contract.increase_balance(amount=10).invoke()
#     await contract.increase_balance(amount=20).invoke()

#     # Check the result of get_balance().
#     execution_info = await contract.get_balance().call()
#     assert execution_info.result == (30,)
