%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_or
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.math import (unsigned_div_rem, assert_nn,
    assert_not_zero, assert_nn_le)
from starkware.cairo.common.pow import pow
from starkware.starknet.common.storage import Storage
from starkware.starknet.common.syscalls import (call_contract,
    get_caller_address)

from contracts.utils.packing import pack_rows, unpack_cols

from contracts.utils.life_rules import (evaluate_rounds,
    apply_rules, get_adjacent)

##### Description #####
#
# This alternative version of GoL2 is a stripped down for
# minimum storage. A player selects the generation and the game is
# calculated and emitted as a return value (could be an Event).
# The next player generates from the start (no retained state).
# The contract records a user-generation mapping that can be used
# later to mint a token.
#
#######################

struct GoL:
    member row_0 : felt
    member row_1 : felt
    member row_2 : felt
    member row_3 : felt
    member row_4 : felt
    member row_5 : felt
    member row_6 : felt
    member row_7 : felt
    member row_8 : felt
    member row_9 : felt
    member row_10 : felt
    member row_11 : felt
    member row_12 : felt
    member row_13 : felt
    member row_14 : felt
    member row_15 : felt
    member row_16 : felt
    member row_17 : felt
    member row_18 : felt
    member row_19 : felt
    member row_20 : felt
    member row_21 : felt
    member row_22 : felt
    member row_23 : felt
    member row_24 : felt
    member row_25 : felt
    member row_26 : felt
    member row_27 : felt
    member row_28 : felt
    member row_29 : felt
    member row_30 : felt
    member row_31 : felt
end

##### Constants #####
# Width of the simulation grid.
const DIM = 32

##### Storage #####
# Returns whether the game has started (bool=1) or not (bool=0).
@storage_var
func spawned() -> (bool : felt):
end

# Returns the generation_id for a given user_id.
@storage_var
func generation_of_user(user_id : felt) -> (gen_id : felt):
end

# Returns the user_id for a given generation_id.
@storage_var
func user_of_generation(gen_id : felt) -> (user_id : felt):
end

# Stores n=dim rows of cell status as a binary representation.
@storage_var
func row_binary(
        row : felt
    ) -> (
        val : felt
    ):
end

##### Events #####
# GamePlayed(user_id, game_state_data_struct)
#    Used
# Token minted/transferred
#
#
#

##################

##### Public functions #####
# Sets the initial state.
@external
func spawn{
        syscall_ptr : felt*,
        storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (has_spawned) = spawned.read()
    if has_spawned == 1:
        return ()
    end
    # Start with an acorn near bottom right in a 32x32 grid.
    # https://www.conwaylife.com/patterns/acorn.cells
    # https://playgameoflife.com/lexicon/acorn
    row_binary.write(12, 32)
    row_binary.write(13, 8)
    row_binary.write(14, 103)
    # Prevent entry to this function again.
    spawned.write(1)
    return ()
end

# Progresses the game by a chosen number of generations
@external
func evolve_generations{
        syscall_ptr : felt*,
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        number_of_generations : felt
    ) -> (
        row_0 : felt, row_1 : felt, row_2 : felt, row_3 : felt,
        row_4 : felt, row_5 : felt, row_6 : felt, row_7 : felt,
        row_8 : felt, row_9 : felt, row_10 : felt, row_11 : felt,
        row_12 : felt, row_13 : felt, row_14 : felt, row_15 : felt,
        row_16 : felt, row_17 : felt, row_18 : felt, row_19 : felt,
        row_20 : felt, row_21 : felt, row_22 : felt, row_23 : felt,
        row_24 : felt, row_25 : felt, row_26 : felt, row_27 : felt,
        row_28 : felt, row_29 : felt, row_30 : felt, row_31 : felt
    ):
    alloc_locals
    # Set limit on generations per turn: (0, max_steps].
    assert_not_zero(number_of_generations)
    # Unpack the stored game
    # Iterates over rows, then cols to get an array of all cells.
    let (local cell_states_init : felt*) = alloc()
    unpack_rows(cell_states=cell_states_init,row=DIM)


    # Run the game for the specified number of generations.
    let (local cell_states : felt*) = evaluate_rounds(
        number_of_generations, cell_states_init)
    # Pack the game for compact return:
    let (local cell_states_final : felt*) = alloc()
    let (cell_states_final : felt*) = pack_rows(cell_states_final,
        cell_states, row=DIM)

    let (local image : GoL) = array_to_struct(cell_states_final)
    # Save the user data.
    let (user) = get_caller_address()
    user_of_generation.write(number_of_generations, user)
    generation_of_user.write(user, number_of_generations)

    return (
    image.row_0, image.row_1, image.row_2, image.row_3,
    image.row_4, image.row_5, image.row_6, image.row_7,
    image.row_8, image.row_9, image.row_10, image.row_11,
    image.row_12, image.row_13, image.row_14, image.row_15,
    image.row_16, image.row_17, image.row_18, image.row_19,
    image.row_20, image.row_21, image.row_22, image.row_23,
    image.row_24, image.row_25, image.row_26, image.row_27,
    image.row_28, image.row_29, image.row_30, image.row_31)
end

##### Private functions #####
# Converts an array of binary-encoded rows in to a struct.
func array_to_struct{
        syscall_ptr : felt*,
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (
        state : felt*
    ) -> (
        image_struct : GoL
    ):
    alloc_locals
    local image : GoL

    assert image.row_0 = state[0]
    assert image.row_1 = state[1]
    assert image.row_2 = state[2]
    assert image.row_3 = state[3]
    assert image.row_4 = state[4]
    assert image.row_5 = state[5]
    assert image.row_6 = state[6]
    assert image.row_7 = state[7]
    assert image.row_8 = state[8]
    assert image.row_9 = state[9]
    assert image.row_10 = state[10]
    assert image.row_11 = state[11]
    assert image.row_12 = state[12]
    assert image.row_13 = state[13]
    assert image.row_14 = state[14]
    assert image.row_15 = state[15]
    assert image.row_16 = state[16]
    assert image.row_17 = state[17]
    assert image.row_18 = state[18]
    assert image.row_19 = state[19]
    assert image.row_20 = state[20]
    assert image.row_21 = state[21]
    assert image.row_22 = state[22]
    assert image.row_23 = state[23]
    assert image.row_24 = state[24]
    assert image.row_25 = state[25]
    assert image.row_26 = state[26]
    assert image.row_27 = state[27]
    assert image.row_28 = state[28]
    assert image.row_29 = state[29]
    assert image.row_30 = state[30]
    assert image.row_31 = state[31]

    return(image_struct=image)
end

# Pre-sim. Walk rows then columns to build state.
func unpack_rows{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        cell_states : felt*,
        row : felt
    ):
    if row == 0:
        return ()
    end

    unpack_rows(cell_states=cell_states, row=row-1)
    # Get the binary encoded store.
    # (Note, on first entry, row=1 so row-1 gets the index)
    let (stored_row) = row_binary.read(row=row-1)
    unpack_cols(cell_states=cell_states,
        row=row-1, col=DIM, stored_row=stored_row)

    return ()
end