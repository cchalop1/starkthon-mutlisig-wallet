%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero, assert_le, assert_nn, assert_nn_le, assert_lt
from starkware.starknet.common.syscalls import (
    get_contract_address, get_caller_address, storage_write
)
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_mul, uint256_le, uint256_lt, uint256_check, uint256_eq, uint256_neg
)

from starkware.starknet.common.syscalls import (
    get_block_number
)
from contracts.utils.Utils import TRANSACTION_EXPIRY
from contracts.token.IERC20 import IERC20
from contracts.interfaces.IAccount import IAccount

####################
# STRUCTS
####################

struct TransactionData:
    member receiver: felt
    member amount: Uint256
end


####################
# EVENTS
####################

@event
func transaction_submited(tx_id: felt, owner: felt, receiver: felt, amount: Uint256):
end

@event
func transaction_confirmed(tx_id: felt, owner: felt):
end

@event
func transaction_executed(tx_id: felt, owner: felt):
end

@event
func confirmation_revoked(tx_id: felt, owner: felt):
end

####################
# STORAGE VARIABLES
####################

@storage_var
func required_confirmations() -> (res: felt):
end

@storage_var
func is_owner(owner: felt) -> (res: felt):
end

@storage_var
func owner() -> (res:felt):
end

@storage_var
func tx_count() -> (res: felt):
end

@storage_var
func transaction_data(tx_id: felt) -> (res: TransactionData):
end

@storage_var
func transaction_block() -> (res: felt):
end

@storage_var
func is_confirmed(tx_id: felt, owner: felt) -> (res: felt):
end

@storage_var
func is_executed(tx_id: felt) -> (res: felt):
end

@storage_var
func num_confirmations(tx_id: felt) -> (res: felt):
end

@storage_var
func eth_address() -> (res: felt):
end


####################
# INTERNAL FUNCTIONS
####################
@view
func view_is_owner{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt) -> (res: felt):
    let (result) = is_owner.read(owner)
    return (result)
end

@view
func view_required_confirmations{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (result) = required_confirmations.read()
    return (result)
end

@view
func view_tx_count{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (result) = tx_count.read()
    return (result)
end

@view
func view_transaction_data{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tx_id: felt) -> (res: felt, amount:Uint256):
    let (tx_data) = transaction_data.read(tx_id)
    let receiver: felt = tx_data.receiver
    let amount: Uint256 = tx_data.amount
    return (receiver, amount)
end

@view
func view_is_confirmed{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tx_id: felt, owner: felt) -> (res: felt):
    let (result) = is_confirmed.read(tx_id, owner)
    return (result)
end

@view
func view_is_executed{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tx_id: felt) -> (res: felt):
    let (result) = is_executed.read(tx_id)
    return (result)
end

@view
func view_num_confirmations{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tx_id: felt) -> (res: felt):
    let (result) = num_confirmations.read(tx_id)
    return(result)
end


@view
func view_eth_address{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (res: felt):
    let (result) = eth_address.read()
    return (result)
end

@view
func view_owners{}() -> (res: felt*):
let (result) = owner.read()
return (result)

####################
# CONSTRUCTOR
####################

@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
        
    }(  
        
        _required_confirmations: felt,
        _eth_address: felt,
        _owners_len: felt,
        _owners: felt*
    ):

    #check 1 <= _required_confirmations <= _owners_len
    assert_nn_le(_required_confirmations-1, _owners_len-1)
    # stores the required confirmations on storage
    required_confirmations.write(_required_confirmations)
    # check that the number of signers is greater than 1
    assert_le(1,_owners_len)
    # writes owner to storage
    set_owners(owners_len=_owners_len, owners=_owners)
    #TESTING - TO REMOVE
    eth_address.write(_eth_address)

    return ()
end



####################
# EXTERNAL FUNCTIONS
####################


# @notice owner submits a tx.
# @param receiver: contract to receive the funds
# @param amount: amount to send
@external
func submit_transaction{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr  
     }(
        receiver: felt,
        amount: Uint256,
        #payload: felt*,
       
    ):
    alloc_locals
    let (current_block) = get_block_number()
    transaction_block.write(current_block)
    let (sender_address) = get_caller_address()

    # check is owner 
    let (owner_status) = is_owner.read(sender_address)
    with_attr error_message("not an owner"):
        assert owner_status = 1
    end


    # check is receiver is not 0
    with_attr error_message("not allowed receiver"):
        assert_not_zero(receiver)
    end

    # check is amount is positif
    with_attr error_message("non positif amount"):
        let zero : Uint256 = Uint256(0, 0)
        uint256_lt(zero, amount)
    end


    # get tx_count and write new tx_count
    let (tx_id) = tx_count.read() 
    let new_tx_id: felt =  tx_id + 1
    tx_count.write(new_tx_id)

    # write to mappings
    let tx_data : TransactionData = TransactionData(receiver=receiver, amount=amount)
    transaction_data.write(new_tx_id, tx_data)

    # emit event
    transaction_submited.emit(new_tx_id, sender_address, receiver, amount)
    return()
end


# @notice owner confirms a tx.
# @param tx_id of tx
@external
func confirm_transaction{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr  
     }(
        tx_id: felt,
    ):

    # check is owner
    let (sender_address) = get_caller_address() 
    let (owner_status) = is_owner.read(sender_address)
    with_attr error_message("not an owner"):
        assert owner_status = 1
    end

    # check transaction exists 
    let (transactions_count) = tx_count.read()
    with_attr error_message("Tx doenst exist"):
        assert_le(tx_id,transactions_count) 
    end

    # check not already confirmed
    let (confirmation_status) = is_confirmed.read(tx_id, sender_address)
    with_attr error_message("already confirmed"):
        assert confirmation_status = 0   
    end

    # check not already executed
    let (execution_status) = is_executed.read(tx_id)
    with_attr error_message("already executed"):
        assert execution_status = 0   
    end

    # add confirmation and update mapping
    let (confirmations) = num_confirmations.read(tx_id)
    num_confirmations.write(tx_id, confirmations + 1)
    is_confirmed.write(tx_id, sender_address, 1)

    # emit event
    transaction_confirmed.emit(tx_id, sender_address)

    return()
end

# @notice owner revoke confirmation of tx.
# @param tx_id of tx
@external
func revoke_confirmation{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr  
     }(
        tx_id: felt,
    ):

    # check is owner
    let (sender_address) = get_caller_address() 
    let (owner_status) = is_owner.read(sender_address)
    with_attr error_message("not an owner"):
        assert owner_status = 1
    end

    # check transaction exists 
    let (transactions_count) = tx_count.read()
    with_attr error_message("already confirmed"):
        assert_le(tx_id,transactions_count) 
    end

    # check confirmed
    let (confirmation_status) = is_confirmed.read(tx_id, sender_address)
    with_attr error_message("not confirmed yet"):
        assert confirmation_status = 1  
    end

    # check not already executed
    let (execution_status) = is_executed.read(tx_id)
    with_attr error_message("already executed"):
        assert execution_status = 0   
    end

    # remove confirmation and update mapping
    let (confirmations) = num_confirmations.read(tx_id)
    num_confirmations.write(tx_id, confirmations - 1)
    is_confirmed.write(tx_id, sender_address, 0)

    # emit event
    confirmation_revoked.emit(tx_id, sender_address)

    return()
end

# @notice owner execute  tx.
# @param tx_id of tx
@external
func execute_transaction{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr  
     }(
        tx_id: felt,
    ):
    alloc_locals
    isExpired()
    # check is owner
    let (sender_address) = get_caller_address() 
    let (owner_status) = is_owner.read(sender_address)
    with_attr error_message("not an owner"):
        assert owner_status = 1
    end

    # check transaction exists 
    let (transactions_count) = tx_count.read()
    with_attr error_message("already confirmed"):
        assert_le(tx_id,transactions_count) 
    end


    # check not already executed
    let (execution_status) = is_executed.read(tx_id)
    with_attr error_message("already executed"):
        assert execution_status = 0   
    end


    # check enough confirmations
    let (confirmations) = num_confirmations.read(tx_id)
    let (req_confirmations) = required_confirmations.read()
    with_attr error_message("not enough confirmations"):
        assert_le(req_confirmations, confirmations)
    end

    # get transaction data to execute
    let (tx_data) = transaction_data.read(tx_id)
    let receiver: felt = tx_data.receiver
    let amount: Uint256 = tx_data.amount

    # update mappings
    is_executed.write(tx_id, 1)

    # execute transaction 
    let (weth) = eth_address.read()
    IERC20.transfer(contract_address=weth, recipient=receiver, amount=amount)
   
    # emit event
    transaction_executed.emit(tx_id, sender_address)

    return()
end

@external
func change_owner{syscall_ptr: felt*, 
                pedersen_ptr: HashBuiltin*,
                range_check_ptr} (
                previous_owner: felt, 
                new_owner: felt
                ) -> (res: felt):
                let (public_key) = IAccount.get_public_key(new_owner)
                with_attr error_message("Account address is invalid"):
                    assert_not_zero(public_key)
                end
                # removes the account as owner
                is_owner.write(previous_owner, 0)
                # stores a reference to the previous owner
                let (previous_owner : felt*) = owner.read()
                # updates the storage slot of previous owner with the new owner
                &[previous_owner] = new_owner
                return (1) 

####################
# INTERNAL FUNCTIONS
####################


# @notice Sets a list of owners  recursively.
# @param owners_len The number of owners to set
# @param owners A pointer to the owners array
func set_owners{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr  
     }(
        owners_len: felt,
        owners: felt*,
    ):
    if owners_len == 0:
       return ()
    end
    
    let current_owner: felt = [owners]

    # check owner has a valid account
    let (public_key) = IAccount.get_public_key(current_owner)
    with_attr error_message("Account address is invalid"):
        assert_not_zero(public_key)
    end
    # check not double owner
    let (owner_status) = is_owner.read(current_owner)
    with_attr error_message("already owner"):
        assert owner_status = 0
    end

    # set the owner
    is_owner.write(current_owner, 1)

    # store the owner account and its address
    owner.write(current_owner)
    
    # set remaining owners recursively
    set_owners(owners_len=owners_len -1, owners=owners+1)
    return ()
end


# @notice Checks if a transaction is expired
# @notice the transaction is valid for 5 hours
func isExpired{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr}():
        alloc_locals
        let (block_creation_number : felt) = transaction_block.read()
        let target_block_number : felt = block_creation_number + TRANSACTION_EXPIRY
        let (current_block : felt) = get_block_number()
        assert_le(current_block, target_block_number)
        return()
end





