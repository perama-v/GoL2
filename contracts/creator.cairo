%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.math import (assert_not_zero,
    assert_le, assert_not_equal, split_felt)
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

# Stores global game index for a given user as an index of their inventory.
@storage_var
func game_index_from_inventory(
        owner_id : felt,
        inventory_index : felt
    ) -> (
        game_index : felt
    ):
end

##### Events #####
@event
func game_created(
    owner_id: felt,
    game_index : felt,
    game_id : felt,
    user_game_count : felt,
    game_index_from_inventory : felt
):
end

@event
func contribution_made(
    user_id : felt,
    game_index : felt,
    current_game_generation : felt
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
    local acorn = 107839786668602559178668060348078522694548577690162289924414444765192
    let (game_id) = hash_game(acorn)

    # Acorn. Has no owner.
    stored_game.write(
        game_index=0,
        gen=0,
        value=acorn
    )

    # Ensure that spawn is only called once. All other games need
    # credits to begin.
    let (current_spawn_id) = game_id_from_game_index.read(0)
    assert current_spawn_id = 0
    let (caller) = get_caller_address()
    # Store the zeroth-index game as owned by the caller of spawn().
    owner_of_game.write(0, caller)

    game_id_from_game_index.write(0, game_id)
    game_index_from_game_id.write(game_id, 0)
    latest_game_index.write(0)
    game_created.emit(
        owner_id=caller,
        game_index=0,
        game_id=game_id,
        user_game_count=1,
        game_index_from_inventory=1
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
    local genesis_state = game_state

    let (local caller) = get_caller_address()
    assert_not_zero(caller)

    let (credits) = has_credits.read(caller)
    assert_le(CREDIT_REQUIREMENT, credits)
    has_credits.write(caller, credits - CREDIT_REQUIREMENT)

    # No two games are the same. Game_id == genesis hash.
    let (local game_id) = hash_game(genesis_state)
    let (existing_index) = game_index_from_game_id.read(game_id)
    # Ensure that the game has not yet been stored to an index.
    assert existing_index = 0
    # Get the id of the very first game.
    let (spawn_id) = game_index_from_game_id.read(0)
    # Make sure it is different.
    assert_not_equal(spawn_id, game_id)

    local syscall_ptr : felt* = syscall_ptr
    let (current_index) = latest_game_index.read()
    let idx = current_index + 1
    # Store the game
    stored_game.write(game_index=idx, gen=0, value=game_state)

    # Update trackers.
    owner_of_game.write(idx, caller)

    let (old_index) = latest_game_index.read()
    let new_index = old_index + 1
    game_id_from_game_index.write(new_index, game_id)
    game_index_from_game_id.write(game_id, new_index)
    latest_game_index.write(new_index)
    let (prev_game_count) = user_game_count.read(caller)
    user_game_count.write(caller, prev_game_count + 1)
    # Index of new = prev_game_count.
    game_index_from_inventory.write(caller, prev_game_count, new_index)
    game_created.emit(
        owner_id=caller,
        game_index=new_index,
        game_id=game_id,
        user_game_count=prev_game_count + 1,
        game_index_from_inventory=prev_game_count
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

    # Save the user data.
    let (user) = get_caller_address()
    assert_not_zero(user)
    # Give a credit for advancing this particular game.
    let (credits) = has_credits.read(user)
    has_credits.write(user, credits + 1)

    # Save the current generation for easy retrieval.
    latest_game_generation.write(game_index, prev_generation + 1)
    contribution_made.emit(
        user_id=user,
        game_index=game_index,
        current_game_generation=prev_generation + 1
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


# Returns game index from the index of a users inventory.
@view
func specific_game_of_user{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user_id : felt,
        index_of_inventory : felt
    ) -> (
        game_index : felt
    ):
    # E.g., 'Get the game index for the third game of this user'.
    let (game_index) = game_index_from_inventory.read(user_id,
        index_of_inventory)

    return (game_index)
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
