"""contract.cairo test file."""
import os

import pytest
from starkware.starknet.services.api.contract_definition import ContractDefinition
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.testing.starknet import Starknet
from nile.signer import Signer
from deploy import deploy_contract

SIGNER1 = Signer(1)
SIGNER2 = Signer(2)
SIGNER3 = Signer(3)

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "contract.cairo")

@pytest.fixture
async def dust_factory(starknet: Starknet) -> StarknetContract:
    starknet = await Starknet.empty()
    account1 = await deploy_contract(starknet, CONTRACT_FILE, 'openzeppelin/token/erc721/utils/ERC721_Holder.cairo')
    account2 = await deploy_contract(starknet, CONTRACT_FILE, 'openzeppelin/token/erc721/utils/ERC721_Holder.cairo')
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    return contract, account1, account2


# The testing library uses python's asyncio. So the following
# decorator and the ``async`` keyword are needed.
@pytest.mark.asyncio
async def test_increase_balance():
    """Test increase_balance method."""
    # Create a new Starknet class that simulates the StarkNet
    # system.
    starknet = await Starknet.empty()
    account = await starknet.deploy(
        contract_def=get_account_definition(), constructor_calldata=[SIGNER1.public_key]
    )

    # Deploy the contract.
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )

    # Invoke increase_balance() twice.
    await contract.increase_balance(amount=10).invoke()
    await contract.increase_balance(amount=20).invoke()


    # Single tx
    await send_transaction(
        SIGNER1, account, contract.contract_address, "increase_balance", [1]
    )
   

    # Check the result of get_balance().
    execution_info = await contract.get_balance().call()
    assert execution_info.result == (31,)
