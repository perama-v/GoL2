%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.math import (assert_not_zero,
    assert_le_felt, assert_not_equal, split_felt)
from starkware.starknet.common.syscalls import get_caller_address

from contracts.utils.hash_game import hash_game
from contracts.utils.life_rules import evaluate_rounds
from contracts.utils.packing import (pack_cells,
    unpack_cells, pack_game)

##### Description #####
#
# Creator is a version of GoL2 where a user may create their own
# starting point for the game. A player may participate only
# once they have contributed to other games to evolve them.
#
#######################

##### Constants #####
# Width of the simulation grid.
const DIM = 15
const CREDIT_REQUIREMENT = 10

##### Storage #####
# Game index is predominantly used. Game id is to ensure uniqueness.
@storage_var
func stored_game(
        game_index : felt,
        gen : felt,
    ) -> (
        val : felt
    ):
end

# Stores the genesis state hash for a given user.
@storage_var
func owner_of_game(
        game_index : felt
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

@storage_var
func game_index_from_game_id(
        game_id : felt
    ) -> (
        game_index : felt
    ):
end

# Index of most recent game.
@storage_var
func latest_game_index(
    ) -> (
        game_index : felt
    ):
end

# Lets you find the latest state of a given game.
@storage_var
func latest_game_generation(
        game_index : felt
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

# Stores how many games a user has created
@storage_var
func user_game_count(
        owner_id : felt
    ) -> (
        count : felt
    ):
end

##### Events #####
@event
func game_created(
    owner_id: felt,
    game_index : felt,
    game_id : felt,
    user_game_count : felt
):
end

@event
func contribution_made(
    user_id : felt,
    game_index : felt,
    current_game_generation : felt
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

##################
@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    local acorn = 215679573337205118357336120696157045389097155380324579848828889530384
    local game_index = 1
    let (game_id) = hash_game(acorn)

    stored_game.write(
        game_index=game_index,
        gen=0,
        value=acorn
    )

    let (caller) = get_caller_address()

    # Store the zeroth-index game as owned by the caller of spawn().
    owner_of_game.write(game_index, caller)

    game_id_from_game_index.write(game_index, game_id)
    game_index_from_game_id.write(game_id, game_index)
    latest_game_index.write(game_index)
    latest_game_generation.write(game_index, 0)
    game_created.emit(
        owner_id=caller,
        game_index=game_index,
        game_id=game_id,
        user_game_count=1
    )
    return ()
end

##### Public functions #####
# Sets the initial state of a game.
@external
func create{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_state : felt
    ):
    alloc_locals

    let (local caller) = get_caller_address()
    assert_not_zero(caller)

    let (credits) = has_credits.read(caller)
    assert_le_felt(CREDIT_REQUIREMENT, credits)
    has_credits.write(caller, credits - CREDIT_REQUIREMENT)

    # No two games are the same. Game_id == game hash.
    let (local game_id) = hash_game(game_state)
    let (existing_index) = game_index_from_game_id.read(game_id)

    # Ensure that the game has not yet been stored to an index.
    assert existing_index = 0
    let (current_index) = latest_game_index.read()
    let new_index = current_index + 1

    # Store the game
    stored_game.write(game_index=new_index, gen=0, value=game_state)
    owner_of_game.write(new_index, caller)
    game_id_from_game_index.write(new_index, game_id)
    game_index_from_game_id.write(game_id, new_index)
    latest_game_index.write(new_index)
    latest_game_generation.write(new_index, 0)

    let (prev_game_count) = user_game_count.read(caller)
    local new_game_count = prev_game_count + 1
    user_game_count.write(caller, new_game_count)

    game_created.emit(
        owner_id=caller,
        game_index=new_index,
        game_id=game_id,
        user_game_count=new_game_count
    )
    credit_reduced.emit(
        user_id=caller,
        balance=credits - CREDIT_REQUIREMENT
    )
    return ()
end

# Progresses the game by a chosen number of generations
@external
func contribute{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_index : felt
    ):
    alloc_locals
    let (caller) = get_caller_address()
    assert_not_zero(caller)

    let (local prev_generation) = latest_game_generation.read(
        game_index)

    # Unpack the stored game.
    let (game) = stored_game.read(game_index, prev_generation)
    let (high, low) = split_felt(game)
    let (cells_len, cells) = unpack_cells(
        high=high,
        low=low
    )
    # Evolve the game by one generation.
    let (local new_cell_states : felt*) = evaluate_rounds(1, cells)

    # Split the game to high and low parts and pack it for compact storage.
    let (new_high) = pack_cells(
        cells_len=112,
        cells=new_cell_states,
        packed_cells=0
    )
    let (new_low) = pack_cells(
        cells_len=113,
        cells=new_cell_states + 112,
        packed_cells=0
    )

    let (packed_game) = pack_game(
        high=new_high,
        low=new_low
    )

    stored_game.write(
        game_index=game_index,
        gen=prev_generation + 1,
        value=packed_game
    )

    # Give a credit for advancing this particular game.
    let (credits) = has_credits.read(caller)
    has_credits.write(caller, credits + 1)

    # Save the current generation for easy retrieval.
    latest_game_generation.write(game_index, prev_generation + 1)
    contribution_made.emit(
        user_id=caller,
        game_index=game_index,
        current_game_generation=prev_generation + 1
    )
    credit_earned.emit(
        user_id=caller,
        balance=credits + 1
    )
    return ()
end


# Gets the index and id of the latest game that was created.
@view
func newest_game{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        game_index : felt,
        game_id : felt,
        generation : felt
    ):
    let (game_index) = latest_game_index.read()
    let (game_id) = game_id_from_game_index.read(game_index)
    let (generation) = latest_game_generation.read(game_index)
    return (game_index, game_id, generation)
end

# Returns user data (credits, games owned).
@view
func user_counts{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user_id : felt
    ) -> (
        game_count : felt,
        credit_count : felt
    ):
    let (game_count) = user_game_count.read(user_id)
    let (credit_count) = has_credits.read(user_id)
    return (game_count, credit_count)
end

# Returns the latest generation of a given game.
@view
func generation_of_game{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_index : felt
    ) -> (
        generation : felt
    ):
    # E.g., 'Get the latest generation number for this game index'.
    let (generation) = latest_game_generation.read(game_index)
    return (generation)
end


# Returns a felt of cells for the specified generation.
@view
func view_game{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_index : felt,
        generation : felt
    ) -> (
        cells_len : felt, cells : felt*
    ):

    let (game) = stored_game.read(game_index, generation)
    let (high, low) = split_felt(game)
    let (cells_len, cells) = unpack_cells(
        high=high,
        low=low
    )
    return (cells_len, cells)
end
