%lang starknet
%builtins pedersen range_check
# Stub source: https://github.com/OpenZeppelin/cairo-contracts/blob/main/contracts/token/ERC721.cairo
# Version: ca397ff
# License: MIT

# This is a stub-only contract: Implementation to follow.

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.starknet.common.storage import Storage
from starkware.cairo.common.math import assert_nn_le

# The Ownable module is non-functional - requires implicit arguments
# which is not currently possible through this import-module style.
#from contracts.utils.Ownable import initialize_ownable, only_owner

@storage_var
func owners(token_id: felt) -> (res: felt):
end

@storage_var
func total_supply() -> (res: felt):
end

@external
func initialize_token{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } ():
    # The game contract calls this function.
    let (caller) = get_caller_address()
    # The game contract owns the token contract.
    #initialize_ownable(caller)
    return ()
end

@external
func mint{
        storage_ptr: Storage*,
        pedersen_ptr: HashBuiltin*,
        syscall_ptr: felt*,
        range_check_ptr
    } (recipient: felt, token_id: felt):
    # Only the game contract can mint.
    #only_owner(pedersen_ptr)

    # Rudimentary mint - just store the owner for the given token.
    owners.write(token_id, recipient)

    # Keep a count of tokens.
    let (supply) = total_supply.read()
    total_supply.write(supply + 1)
    return ()
end
