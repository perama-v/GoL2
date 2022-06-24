from starkware.cairo.common.hash_state import (hash_init,
    hash_update_single, HashState)
from starkware.cairo.common.cairo_builtins import HashBuiltin

func hash_game{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        item : felt
    ) -> (
        hash : felt
    ):
    let (hash_state : HashState*) = hash_init()
    let (hash_state : HashState*) = hash_update_single{
        hash_ptr=pedersen_ptr}(hash_state, item)
    return (hash_state.current_hash)
end
