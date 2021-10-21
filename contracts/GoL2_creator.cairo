%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_or
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.hash_state import (hash_init,
    hash_update, HashState)
from starkware.cairo.common.math import (unsigned_div_rem, assert_nn,
    assert_not_zero, assert_nn_le, assert_le)
from starkware.cairo.common.pow import pow
from starkware.starknet.common.storage import Storage
from starkware.starknet.common.syscalls import (call_contract,
    get_caller_address)


from contracts.utils.hash_game import hash_game
#from contracts.utils.packing import pack_cols, unpack_cols
from contracts.utils.life_rules import (evaluate_rounds,
    apply_rules, get_adjacent)

##### Description #####
#
# Creator is a version of GoL2 where a user may create their own
# starting point for the game. A player may participate only
# once they have contributed to other games to evolve them.
#
#######################

##### Constants #####
# Width of the simulation grid.
const DIM = 32
const CREDIT_REQUIREMENT = 10

##### Storage #####

# Stores n=dim rows of cell status as a binary representation.
# For a given game at a given state.
@storage_var
func stored_row(
        game_id : felt,
        gen : felt,
        row : felt
    ) -> (
        val : felt
    ):
end

# Stores the genesis state hash for a given user.
@storage_var
func owner_of_game_id(
        game_id : felt
    ) -> (
        owner_id : felt
    ):
end

# Gets the game ID. New games get the next index. Allows iteration.
@storage_var
func game_id_from_game_index(
        game_index : felt
    ) -> (
        game_id : felt
    ):
end

# Inndex of most recent game.
@storage_var
func latest_game_index(
    ) -> (
        game_index : felt
    ):
end

# Lets you find the latest state of a given game.
@storage_var
func latest_game_generation(
        game_id : felt
    ) -> (
        game_generation : felt
    ):
end

# Stores the count of credits.
@storage_var
func has_credits(
        owner_id : felt
    ) -> (
        credits : felt
    ):
end

##################

##### Public functions #####
@external
func spawn{
        syscall_ptr : felt*,
        storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (acorn : felt*) = alloc()
    # Skipped the first 11 rows for hashing.
    assert acorn[0] = 32
    assert acorn[1] = 8
    assert acorn[2] = 103

    let (game_id) = hash_game(acorn, 3)

    # Acorn. Has no owner.
    stored_row.write(game_id=0, gen=0, row=12, value=32)
    stored_row.write(game_id=0, gen=0, row=13, value=8)
    stored_row.write(game_id=0, gen=0, row=14, value=103)

    # Ensure that spawn is only called once. All other games need
    # credits to begin.
    let (current_owner) = owner_of_game_id.read(game_id)
    assert current_owner = 0
    let (caller) = get_caller_address()
    owner_of_game_id.write(game_id, caller)

    game_id_from_game_index.write(0, game_id)
    latest_game_index.write(0)
    return ()
end

# Sets the initial state of a game.
@external
func create{
        syscall_ptr : felt*,
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        genesis_state_len : felt,
        genesis_state : felt*
    ):
    # Accepts a 32 element list representing the rows of the game.
    alloc_locals
    assert genesis_state_len = DIM

    let (local caller) = get_caller_address()
    # Check that the caller has enough credits, subtract some.
    # TODO Uncomment and test credits
    #let (credits) = has_credits.read(caller)
    #assert_le(CREDIT_REQUIREMENT, credits)
    #has_credits.write(caller, credits - CREDIT_REQUIREMENT)


    local storage_ptr : Storage* = storage_ptr
    # No two games are the same. Game_id == genesis hash.
    let (local game_id) = hash_game(genesis_state, genesis_state_len)
    let (local current_owner) = owner_of_game_id.read(game_id)
    assert current_owner = 0

    local syscall_ptr : felt* = syscall_ptr
    # Store the game
    save_rows(game_id=game_id, generation=0,
        cell_states=genesis_state, row=DIM)

    # Update trackers.
    owner_of_game_id.write(game_id, caller)
    let (old_index) = latest_game_index.read()
    let new_index = old_index + 1
    game_id_from_game_index.write(new_index, game_id)
    latest_game_index.write(new_index)

    return ()
end

# Progresses the game by a chosen number of generations
@external
func contribute{
        syscall_ptr : felt*,
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_id : felt
    ):
    alloc_locals
    let (local prev_generation) = latest_game_generation.read(
        game_id)
    # Unpack the stored game.
    # Iterates over rows, then cols to get an array of all cells.
    let (local cell_states_init : felt*) = alloc()
    unpack_rows(game_id=game_id, generation=prev_generation,
        cell_states=cell_states_init,row=DIM)

    # Evolve the game by one generation.
    let (local cell_states : felt*) = evaluate_rounds(1,
        cell_states_init)
    # Pack the game for compact storage.

    save_rows(game_id=game_id, generation=prev_generation + 1,
        cell_states=cell_states, row=DIM)

    # Save the user data.
    let (user) = get_caller_address()
    # Give a credit for advancing this particular game.
    let (credits) = has_credits.read(user)
    has_credits.write(user, credits + 1)

    # Save the current generation for easy retrieval.
    latest_game_generation.write(game_id, prev_generation + 1)
    return ()
end


# TODO A function that gets the index of the latest game.

# TODO A function that returns user data (credits, games owned).

# Returns a list of rows for the specified generation.
@view
func view_game{
        storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_id : felt,
        gen : felt
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

    let (row_0) = stored_row.read(game_id, gen, 0)
    let (row_1) = stored_row.read(game_id, gen, 1)
    let (row_2) = stored_row.read(game_id, gen, 2)
    let (row_3) = stored_row.read(game_id, gen, 3)
    let (row_4) = stored_row.read(game_id, gen, 4)
    let (row_5) = stored_row.read(game_id, gen, 5)
    let (row_6) = stored_row.read(game_id, gen, 6)
    let (row_7) = stored_row.read(game_id, gen, 7)
    let (row_8) = stored_row.read(game_id, gen, 8)
    let (row_9) = stored_row.read(game_id, gen, 9)
    let (row_10) = stored_row.read(game_id, gen, 10)
    let (row_11) = stored_row.read(game_id, gen, 11)
    let (row_12) = stored_row.read(game_id, gen, 12)
    let (row_13) = stored_row.read(game_id, gen, 13)
    let (row_14) = stored_row.read(game_id, gen, 14)
    let (row_15) = stored_row.read(game_id, gen, 15)
    let (row_16) = stored_row.read(game_id, gen, 16)
    let (row_17) = stored_row.read(game_id, gen, 17)
    let (row_18) = stored_row.read(game_id, gen, 18)
    let (row_19) = stored_row.read(game_id, gen, 19)
    let (row_20) = stored_row.read(game_id, gen, 20)
    let (row_21) = stored_row.read(game_id, gen, 21)
    let (row_22) = stored_row.read(game_id, gen, 22)
    let (row_23) = stored_row.read(game_id, gen, 23)
    let (row_24) = stored_row.read(game_id, gen, 24)
    let (row_25) = stored_row.read(game_id, gen, 25)
    let (row_26) = stored_row.read(game_id, gen, 26)
    let (row_27) = stored_row.read(game_id, gen, 27)
    let (row_28) = stored_row.read(game_id, gen, 28)
    let (row_29) = stored_row.read(game_id, gen, 29)
    let (row_30) = stored_row.read(game_id, gen, 30)
    let (row_31) = stored_row.read(game_id, gen, 31)

    return (row_0, row_1, row_2, row_3, row_4, row_5,
        row_6, row_7, row_8, row_9, row_10, row_11,
        row_12, row_13, row_14, row_15, row_16, row_17,
        row_18, row_19, row_20, row_21, row_22, row_23,
        row_24, row_25, row_26, row_27, row_28, row_29,
        row_30, row_31)
end

##### Private functions #####
# Pre-sim. Walk rows then columns to build state.
func unpack_rows{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_id : felt,
        generation : felt,
        cell_states : felt*,
        row : felt
    ):
    if row == 0:
        return ()
    end

    unpack_rows(game_id=game_id, generation=generation,
        cell_states=cell_states, row=row-1)
    # Get the binary encoded store.
    # (Note, on first entry, row=1 so row-1 gets the index)
    let (packed_row) = stored_row.read(game_id=game_id,
        gen=generation, row=row-1)

    unpack_cols(cell_states=cell_states,
        row=row-1, col=DIM, stored_row=packed_row)

    return ()
end

# Saves inidividual rows in the given array.
func save_rows{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_id : felt,
        generation : felt,
        cell_states : felt*,
        row : felt
    ):
    if row == 0:
        return ()
    end

    save_rows(
        game_id=game_id,
        generation=generation,
        cell_states=cell_states,
        row=row-1)
    # (Note, on first entry, row=1 so row-1 gets the index)
    # Create the binary encoded state for the row.
    let (row_to_store) = pack_cols(cell_states=cell_states,
        row=row-1, col=DIM, row_to_store=0)

    # Permanently store the game state.
    stored_row.write(
        game_id=game_id,
        gen=generation,
        row=row-1,
        value=row_to_store)

    return ()
end


### PACKING LOGIC ###
# Post-sim. Walk rows then columns to store state.
func pack_rows{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        compact : felt*,
        cell_states : felt*,
        row : felt
    ) -> (
        compact : felt*
    ):
    if row == 0:
        return (compact=compact)
    end
    alloc_locals
    let (local compact : felt*) = pack_rows(compact=compact, cell_states=cell_states, row=row-1)
    # (Note, on first entry, row=1 so row-1 gets the index)
    # Create the binary encoded state for the row.
    let (row_to_store) = pack_cols(cell_states=cell_states,
        row=row-1, col=DIM, row_to_store=0)
    # row_binary.write(row=row-1, value=row_to_store)
    assert compact[row - 1] = row_to_store

    return (compact=compact)
end



# Post-sim. Walk columns for a given row and saves array to state.
func pack_cols{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        cell_states : felt*,
        row : felt,
        col : felt,
        row_to_store : felt
    ) -> (
        row_to_store : felt
    ):
    alloc_locals
    if col == 0:
        return (row_to_store)
    end
    # Loops over columns, adding to a single felt using a mask.
    let (local row_to_store) = pack_cols(cell_states=cell_states,
        row=row, col=col-1, row_to_store=row_to_store)
    # (Note, on first entry, col=1 so col-1 gets the index)

    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local storage_ptr : Storage* = storage_ptr
    local cell_states : felt* = cell_states
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr


    # Get index of cell in cell_state for this row-col combo.
    # "Move 'row length' blocks down list, then add the column index".
    let index = row * DIM + (col - 1)
    let state = cell_states[index]


    # col=0 goes in MSB. col=DIM-1 goes in LSB.
    let binary_position = DIM - (col - 1) - 1
    # 000...00000000011 row_to_store (old aggregator)
    # 000...00000001000 cell_binary (cell state)
    # 000...00000001011 bitwise OR (new aggregator)

    # Binary = state * bit = state * 2**column_index
    # E.g., For index-0: 1 * 2**0 = 0b1
    # E.g., For index-2: 1 * 2**2 = 0b100

    let (bit) = pow(2, binary_position)
    let cell_binary = state * bit
    # store = store OR row_binary
    let (new_row) = bitwise_or(cell_binary, row_to_store)

    return (new_row)
end


# Pre-sim. Walk columns for a given row and saves state to an array.
func unpack_cols{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        cell_states : felt*,
        row : felt,
        col : felt,
        stored_row : felt
    ):
    alloc_locals
    if col == 0:
        return ()
    end

    unpack_cols(cell_states=cell_states,
        row=row, col=col-1, stored_row=stored_row)
    # (Note, on first entry, col=1 so col-1 gets the index)
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local storage_ptr : Storage* = storage_ptr
    local cell_states : felt* = cell_states
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    # state = 2**column_index AND row_binary
    # Column zero is the MSB, so (DIM_index - col_index) accesses the bit.
    let binary_position = (DIM - 1) - (col - 1)
    let (mask) = pow(2, binary_position)
    let (state) = bitwise_and(stored_row, mask)
    # E.g., if in col_index 2, for an alive 'state=4 (0b100)',
    # convert to 1
    local alive_or_dead
    if state == 0:
        assert alive_or_dead = 0
    else:
        assert alive_or_dead = 1
    end
    let index = row * DIM + (col - 1)
    assert cell_states[index] = alive_or_dead


    return ()
end
