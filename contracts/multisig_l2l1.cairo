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
    member l1_contract: felt
    member payload_len: felt
end

####################
# EVENTS
####################

@event
func transaction_submited(tx_id: felt, owner: felt, l1_contract: felt, payload_len: felt, payload: felt*):
end

@event
func transaction_confirmed(tx_id: felt, owner: felt):
end

@event
func confirmation_revoked(tx_id: felt, owner: felt):
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
func num_confirmations(tx_id: felt) -> (res: felt):
end

@storage_var
func is_owner(owner: felt) -> (res: felt):
end

@storage_var
func is_confirmed(tx_id: felt, owner: felt) -> (res: felt):
end

@storage_var
func is_executed(tx_id: felt) -> (res: felt):
end

@storage_var
func tx_count() -> (res: felt):
end

@storage_var
func transaction_data(tx_id: felt) -> (res: TransactionData):
end

@storage_var
func transaction_payloads(tx_id: felt, payload_id: felt) -> (payload: felt):
end


####################
# VIEW FUNCTIONS
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
    }(tx_id: felt) -> (res: felt, payload_len: felt):
    let (tx_data) = transaction_data.read(tx_id)
    let l1_contract: felt = tx_data.l1_contract
    let payload_len: felt = tx_data.payload_len
    return (l1_contract, payload_len)
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
# @param l1_contract concerned
# @param payload_len tx payload length
# @param payload A pointer to the tx payload
@external
func submit_transaction{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr  
     }(
        l1_contract: felt,
        payload_len: felt,
        payload: felt*,
       
    ):
    alloc_locals
    let (sender_address) = get_caller_address()

    # check is owner 
    let (owner_status) = is_owner.read(sender_address)
    with_attr error_message("not an owner"):
        assert owner_status = 1
    end

    # check is valid address 
    with_attr error_message("invalid address"):
        assert_not_zero(l1_contract)
    end

    # check is valid length 
    with_attr error_message("invalid length"):
        assert_lt(0, payload_len)
    end

    # get tx_count and write new tx_count
    let (tx_id) = tx_count.read() 
    let new_tx_id: felt =  tx_id + 1
    tx_count.write(new_tx_id)

    # write to mappings
    let tx_data : TransactionData = TransactionData(l1_contract=l1_contract, payload_len=payload_len)
    transaction_data.write(new_tx_id, tx_data)

    # fill transaction_payloads
    set_payloads(new_tx_id,payload_len, payload)

    # emit event
    transaction_submited.emit(new_tx_id, sender_address, l1_contract, payload_len, payload)
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
    let l1_contract: felt = tx_data.l1_contract
    let payload_len: felt = tx_data.payload_len
    let (payload) = get_payloads(tx_id, payload_len)

    # update mappings
    is_executed.write(tx_id, 1)

    # execute transaction 
    send_message_to_l1(to_address=l1_contract, payload_size=payload_len, payload=payload)
   
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


# @notice Sets payloads of tx recursively.
# @notice payloads are set in the inverse order and should be recovered in the inverse order too
# @param payloads_len The number of payloads to set
# @param owners A pointer to the payloads
func set_payloads{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr  
     }(
        tx_id: felt,
        #index: felt,
        payloads_len: felt,
        payloads: felt*,
    ):
    #alloc_locals
    # if no more owners
    if payloads_len == 0:
       return ()
    end
    
    # write to mappings
    transaction_payloads.write(tx_id, payloads_len, [payloads])     
    # set remaining payload recursively
    set_payloads(tx_id=tx_id ,payloads_len=payloads_len-1, payloads=payloads+1)
    return ()
end


# @notice gets payloads of tx recursively.
# @notice payloads are set in the inverse order and are recovered in the inverse order too
# @param tx_id transaction id
# @param payloads_len The number of payloads to set
# @return payloads A pointer to the payloads array
func get_payloads{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr  
     }(
        tx_id: felt,
        payloads_len: felt,
    )->(payloads: felt*):
    alloc_locals
    let (local payloads) = alloc()
    _get_payloads(tx_id, payloads_len, payloads)
    return(payloads)
   
end

# Fills `payloads` with the  of the payloads stored in transaction_payloads
func _get_payloads{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr  
     }(tx_id: felt, payloads_len: felt, payloads: felt*):
    if payloads_len == 0:
        return ()
    end

    let (payload) = transaction_payloads.read(tx_id, payloads_len) 
    assert [payloads] = payload 

    _get_payloads(tx_id=tx_id, payloads_len=payloads_len-1, payloads=payloads+1)
    return ()
end