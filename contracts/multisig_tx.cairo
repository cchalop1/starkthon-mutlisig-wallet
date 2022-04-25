%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import assert_not_zero, assert_le, assert_nn, assert_nn_le, assert_lt
from starkware.starknet.common.syscalls import (
    get_contract_address, get_caller_address, call_contract
)
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_mul, uint256_le, uint256_lt, uint256_check, uint256_eq, uint256_neg
)



####################
# STRUCTS
####################

struct TransactionData:
    member l2_contract: felt
    member function_selector: felt
    member payload_len: felt
end


####################
# EVENTS
####################

@event
func transaction_submited(tx_id: felt, owner: felt, l2_contract: felt, payload_len: felt, payload: felt*):
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

@storage_var
func eth_address() -> (res: felt):
end

@storage_var
func transaction_payload(tx_id: felt, payload_id: felt) -> (payload: felt):
end

@storage_var
func _transaction_calldata(tx_id : felt, payload_id : felt) -> (res : felt):
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
    }(tx_id: felt) -> (res: felt, function_selector: felt, payload_len: felt):
    let (tx_data) = transaction_data.read(tx_id)
    let l2_contract: felt = tx_data.l2_contract
    let function_selector: felt = tx_data.function_selector
    let payload_len: felt = tx_data.payload_len
    return (l2_contract, function_selector, payload_len)
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
        _required_confirmations: felt,
        _owners_len: felt,
        _owners: felt*
    ):
    #alloc_locals 

    #check 1 <= _required_confirmations <= _owners_len
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
        l2_contract: felt,
        function_selector: felt,
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
        assert_not_zero(l2_contract)
    end


    # get tx_count and write new tx_count
    let (tx_id) = tx_count.read() 
    let new_tx_id: felt =  tx_id + 1
    tx_count.write(new_tx_id)

    # write to mappings
    let tx_data : TransactionData = TransactionData(l2_contract=l2_contract,function_selector=function_selector,payload_len=payload_len)
    transaction_data.write(new_tx_id, tx_data)

    # fill transaction_payload
    #set_payload(new_tx_id, payload_len, payload)
    set_transaction_payload(new_tx_id,0, payload_len, payload)
    # emit event
    transaction_submited.emit(new_tx_id, sender_address, l2_contract, payload_len, payload)
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
    )-> (
        response_len: felt,
        response: felt*,
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
    let l2_contract: felt = tx_data.l2_contract
    let function_selector: felt = tx_data.function_selector
    let payload_len: felt = tx_data.payload_len
    #let (payload) = get_payload(tx_id, payload_len)

    # update mappings
    is_executed.write(tx_id, 1)

    # execute transaction 
    # let (tx, tx_calldata_len, tx_calldata) = get_transaction(tx_index=tx_index)
    let (payload_len, payload) = get_transaction_payload(tx_id=tx_id)

    # Actually execute it
    let response = call_contract(
        contract_address=l2_contract,
        function_selector=function_selector,
        calldata_size=payload_len,
        calldata=payload,
    )
   
    # emit event
    transaction_executed.emit(tx_id, sender_address)

    return (response_len=response.retdata_size, response=response.retdata)
end



# @notice owner execute  tx.
# @param tx_id of tx
@external
func execute{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr  
     }(
        l2_contract: felt,
        function_selector: felt,
        payload_len: felt,
        payload: felt*
    )-> (
       
        response_len: felt,
        response: felt*,
    ):
    alloc_locals
    # Actually execute it
    let response = call_contract(
        contract_address=l2_contract,
        function_selector=function_selector,
        calldata_size=payload_len,
        calldata=payload,
    )

    return (response_len=response.retdata_size, response=response.retdata)
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

    # Account_get_public_key(current_owner)
    # with_attr error_message("Account address is invalid"):
    #     assert_not_zero(current_owner)
    # end

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



# @notice Sets payload of tx recursively.
# @notice payload are set in the inverse order and should be recovered in the inverse order too
# @param payload_len The number of payload to set
# @param owners A pointer to the payload
# func set_payload{
#         syscall_ptr: felt*, 
#         pedersen_ptr: HashBuiltin*,
#         range_check_ptr  
#      }(
#         tx_id: felt,
#         #index: felt,
#         payload_len: felt,
#         payload: felt*,
#     ):
#     #alloc_locals
#     # if no more owners
#     if payload_len == 0:
#        return ()
#     end
    
#     # write to mappings
#     transaction_payload.write(tx_id, payload_len, [payload])     
#     # set remaining payload recursively
#     set_payload(tx_id=tx_id ,payload_len=payload_len-1, payload=payload+1)
#     return ()
# end



func set_transaction_payload{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        tx_id : felt,
        payload_id : felt,
        payload_len : felt,
        payload : felt*,
    ):
    if payload_id == payload_len:
        return ()
    end

     # Write the current iteration to storage
    _transaction_calldata.write(
        tx_id=tx_id,
        payload_id=payload_id,
        value=[payload],
    )

    # Recursively write the rest
    set_transaction_payload(
        tx_id=tx_id,
        payload_id=payload_id + 1,
        payload_len=payload_len,
        payload=payload + 1,
    )
    return ()
end


# @notice gets payload of tx recursively.
# @notice payload are set in the inverse order and are recovered in the inverse order too
# @param tx_id transaction id
# @param payload_len The number of payload to set
# @return payload A pointer to the payload array
# func get_payload{
#         syscall_ptr: felt*, 
#         pedersen_ptr: HashBuiltin*,
#         range_check_ptr  
#      }(
#         tx_id: felt,
#         payload_len: felt,
#     )->(payload: felt*):
#     alloc_locals
#     let (local payload) = alloc()
#     _get_payload(tx_id, payload_len, payload)
#     return(payload)
   
# end

# # Fills `payload` with the  of the payload stored in transaction_payload
# func _get_payload{
#         syscall_ptr: felt*, 
#         pedersen_ptr: HashBuiltin*,
#         range_check_ptr  
#      }(tx_id: felt, payload_len: felt, payload: felt*):
#     if payload_len == 0:
#         return ()
#     end

#     let (payload) = transaction_payload.read(tx_id, payload_len) 
#     assert [payload] = payload 

#     _get_payload(tx_id=tx_id, payload_len=payload_len-1, payload=payload+1)
#     return ()
# end

func _get_transaction_payload{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        tx_id : felt,
        payload_id : felt,
        payload_len : felt,
        payload : felt*
    ):
    if payload_id == payload_len:
        return ()
    end

    let (payload_arg) = _transaction_calldata.read(tx_id=tx_id, payload_id=payload_id)
    assert payload[payload_id] = payload_arg

    _get_transaction_payload(
        tx_id=tx_id,
        payload_id=payload_id + 1,
        payload_len=payload_len,
        payload=payload
    )
    return ()
end

@view
func get_transaction_payload{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(tx_id : felt) ->(
        payload_len: felt,
        payload: felt*
    ):
    alloc_locals
    let (tx_data) = transaction_data.read(tx_id=tx_id)
    let payload_len: felt = tx_data.payload_len
    let (payload) = alloc()
    if payload_len == 0:
        return (0 , payload)
    end

    # Recursively get more calldata args and add them to the list
    _get_transaction_payload(
        tx_id=tx_id,
        payload_id=0,
        payload_len=payload_len,
        payload=payload
    )
    return (payload_len=payload_len, payload=payload)
end