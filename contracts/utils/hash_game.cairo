from starkware.cairo.common.hash_state import (hash_init,
    hash_update, HashState)
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)


# Computes the unique hash of a list of felts.
func hash_game{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        list : felt*,
        list_len : felt
    ) -> (
        hash : felt
    ):
    let (list_hash : HashState*) = hash_init()
    let (list_hash : HashState*) = hash_update{
        hash_ptr=pedersen_ptr}(list_hash, list, list_len)
    return (list_hash.current_hash)
end
