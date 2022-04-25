%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.messages import send_message_to_l1
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero, assert_le, assert_nn, assert_nn_le, assert_lt
from starkware.starknet.common.syscalls import (
    get_contract_address, get_caller_address
)


####################
# STRUCTS
####################

struct TransactionData:
    member receiver: felt
    member amount: felt
end


####################
# EVENTS
####################

@event
func transaction_submited(tx_id: felt, owner: felt, receiver: felt, amount: felt):
end

@event
func transaction_confirmed(tx_id: felt, owner: felt):
end

@event
func transaction_executed(tx_id: felt, owner: felt):
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
func tx_count() -> (res: felt):
end

@storage_var
func transaction_data(tx_id: felt) -> (res: TransactionData):
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

@event
func confirmation_revoked(tx_id: felt, owner: felt):
end

####################
# CONSTRUCTOR
####################

@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
        
    }(
        _owners_len: felt,
        _owners: felt*,
        _required_confirmations: felt,
    ):
    alloc_locals 

    # check 1 <= _required_confirmations <= _owners_len
    assert_nn_le(_required_confirmations-1, _owners_len-1)
    required_confirmations.write(_required_confirmations)
    set_owners(owners_len=_owners_len, owners=_owners)

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
        amount: felt,
        #payload: felt*,
       
    ):
    alloc_locals
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
        assert_nn_le(1, amount)
    end


    # get tx_count and write new tx_count
    let (tx_id) = tx_count.read() 
    tx_id = tx_id + 1
    tx_count.write(tx_id)

    # write to mappings
    let tx_data : TransactionData = TransactionData(receiver=receiver, amount=amount)
    transaction_data.write(tx_id, tx_data)

    # emit event
    transaction_submited.emit(tx_id, sender_address, receiver, amount)
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
    let amount: felt = tx_data.amount

    # update mappings
    is_executed.write(tx_id, 1)

    # execute transaction 
    # make transfer here
   
    # emit event
    transaction_executed.emit(tx_id, sender_address)

    return()
end



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
    #alloc_locals
    # if no more owners
    if owners_len == 0:
       return ()
    end
    
    let current_owner: felt = [owners]

    # check owner not zero
    with_attr error_message("owner is 0"):
        assert_not_zero(current_owner)
    end

    # check not double owner
    let (owner_status) = is_owner.read(current_owner)
    with_attr error_message("already owner"):
        assert owner_status = 0
    end

    # set the owner
    is_owner.write(current_owner, 1)
    
    # set remaining owners recursively
    set_owners(owners_len=owners_len -1, owners=owners+1)
    return ()
end



