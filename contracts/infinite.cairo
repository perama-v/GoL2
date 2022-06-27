%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.math import (assert_not_zero, 
    assert_le_felt, assert_not_equal, split_felt)
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.memcpy import memcpy

from contracts.utils.packing import pack_game, pack_cells, unpack_cells
from contracts.utils.life_rules import evaluate_rounds
from starkware.cairo.common.alloc import alloc


##### Constants #####
# Width of the simulation grid.
const DIM = 15

##### Storage #####

# Returns the generation of the current alive generation.
@storage_var
func current_generation() -> (generation : felt):
end

# Returns the user_id for a given generation_id.
@storage_var
func owner_of_generation(generation : felt) -> (user_id : felt):
end

# Returns the total number of credits owned by a user.
@storage_var
func count_credits_owned(user_id : felt) -> (credits_owned : felt):
end

# Stores cells revival history for user in (cell_index, generation) tuple
@storage_var
func revival_history(
    user_id: felt
    ) -> (
    info : (felt, felt)
):
end

# Records the history of the game on chain.
@storage_var
func historical_state(
        generation : felt
    ) -> (
        state : felt
    ):
end

##### Events #####
@event
func game_evolved(
    user_id : felt, 
    generation : felt
):
end

@event
func credit_earned(
    user_id : felt,
    balance : felt
):
end

@event
func credit_reduced(
    user_id : felt,
    balance : felt
):
end

@event
func cell_revived(
    user_id : felt,
    generation : felt,
    cell_index : felt
):
end

##################

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    historical_state.write(1, 215679573337205118357336120696157045389097155380324579848828889530384)
    current_generation.write(1)
    return ()
end

##### Public functions #####
# Sets the initial state.
# Progresses the game by a chosen number of generations
@external
func evolve_and_claim_next_generation{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals

    let (caller) = get_caller_address()
    assert_not_zero(caller)

    # Limit to one generation per turn.
    let (local last_gen) = current_generation.read()
    local generations = 1
    local new_gen = last_gen + generations

    # Unpack the stored game
    let (game) = historical_state.read(last_gen)
    let (high, low) = split_felt(game)
    let (cells_len, cells) = unpack_cells(
        high=high,
        low=low
    )

    # Run the game for the specified number of generations.
    let (local cell_states : felt*) = evaluate_rounds(
        generations, cells)

    # Split the game to high and low parts and pack it for compact storage.
    let (new_high) = pack_cells(
        cells_len=112,
        cells=cell_states,
        packed_cells=0
    )
    let (new_low) = pack_cells(
        cells_len=113,
        cells=cell_states + 112,
        packed_cells=0
    )

    let (packed_game) = pack_game(
        high=new_high,
        low=new_low
    )

    historical_state.write(new_gen, packed_game)
    current_generation.write(new_gen)

    # Grant credits
    let (credits) = count_credits_owned.read(caller)
    count_credits_owned.write(caller, credits + 1)
    owner_of_generation.write(new_gen, caller)

    game_evolved.emit(
        user_id=caller,
        generation=new_gen
    )
    credit_earned.emit(
        user_id=caller,
        balance=credits + 1
    )
    return ()
end

# Give life to a specific cell.
@external
func give_life_to_cell{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        cell_index : felt
    ):
    # This does not trigger an evolution. Multiple give_life
    # operations may be called, building up a shape before
    # a turn triggers evolution.
    alloc_locals

    # Only the owner can revive
    let (caller) = get_caller_address()
    assert_not_zero(caller)
    let (generation) = current_generation.read()
    let (local owner) = owner_of_generation.read(generation)
    assert owner = caller

    let (local owned_credits) = count_credits_owned.read(caller)
    assert_le_felt(1, owned_credits)

    activate_cell(cell_index)

    count_credits_owned.write(
        user_id=caller,
        value=owned_credits - 1
    )

    revival_history.write(
        user_id=caller,
        value=(cell_index, generation)
    )

    credit_reduced.emit(
        user_id=caller,
        balance=owned_credits - 1
    )
    cell_revived.emit(
        user_id=caller,
        generation=generation,
        cell_index=cell_index
    )

    return ()
end


# Returns a the current generation id.
@view
func current_generation_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
    ) -> (
        generation : felt
    ):
    let (generation) = current_generation.read()
    return (generation)
end

# Returns user credits count
@view
func user_credits_count{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user_id : felt
    ) -> (
        count : felt
    ):
    let (count) = count_credits_owned.read(user_id)
    return(count)
end

# Returns the owner of the current generation
@view
func get_owner_of_generation{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        generation : felt
    ) -> (
        user_id : felt
    ):
    let (owner) = owner_of_generation.read(generation)
    return(owner)
end

# Returns revival history for user
@view
func get_revival_history{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user_id: felt
    ) -> (
        cell_index : felt,
        generation : felt
    ):
    let (info) = revival_history.read(user_id)
    return (info[0], info[1])
end

# Returns a list of cells for the specified generation.
@view
func view_game{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        generation : felt
    ) -> (
        cells_len : felt, cells : felt*
    ):

    let (game) = historical_state.read(generation)
    let (high, low) = split_felt(game)
    let (cells_len, cells) = unpack_cells(
        high=high,
        low=low
    )

    return (cells_len, cells)
end

# User input may override state to make a cell alive.
func activate_cell{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        cell_index : felt
    ):
    alloc_locals
    let (local updated_cells : felt*) = alloc()

    assert_le_felt(cell_index, DIM*DIM-1)
    local upper_len = DIM*DIM - 1 - cell_index
    local offset = cell_index + 1

    let (local generation) = current_generation.read()
    let (local game) = historical_state.read(generation)
    let (high, low) = split_felt(game)
    let (cells_len, cells) = unpack_cells(
        high=high,
        low=low
    )

    memcpy(updated_cells, cells, cell_index)
    assert updated_cells[cell_index] = 1
    memcpy(updated_cells + offset, cells + offset, upper_len)    

    let (new_high) = pack_cells(
        cells_len=112,
        cells=updated_cells,
        packed_cells=0
    )
    let (new_low) = pack_cells(
        cells_len=113,
        cells=updated_cells + 112,
        packed_cells=0
    )

    let (updated) = pack_game(
        high=new_high,
        low=new_low
    )

    assert_not_equal(game, updated)
    historical_state.write(generation, updated)

    return ()
end
