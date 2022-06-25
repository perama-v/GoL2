%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.utils.hash_game import hash_game

@external
func test_hash_game{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (hash) = hash_game(107839786668602559178668060348078522694548577690162289924414444765192)
    assert hash = 0x1b8a88ed549497258738414a5c0d70a0a7b0e32091bd501d26573580392c92b
    return ()
end
