%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_or
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.hash_state import (hash_init,
    hash_update, HashState)
from starkware.cairo.common.math import (unsigned_div_rem, assert_nn,
    assert_not_zero, assert_nn_le, assert_le, assert_not_equal,
    split_int)
from starkware.cairo.common.pow import pow
from starkware.starknet.common.syscalls import (call_contract,
    get_caller_address)


from contracts.utils.hash_game import hash_game
from contracts.utils.packing import pack_cols, append_cols
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
const DIM = 15
const CREDIT_REQUIREMENT = 10

##### Storage #####
# Game index is predominantly used. Game id is to ensure uniqueness.

# Stores n=dim rows of cell status as a binary representation.
# For a given game at a given state.
@storage_var
func stored_row(
        game_index : felt,
        gen : felt,
        row : felt
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


##################
@constructor
func constructor{
        syscall_ptr : felt*,
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
    stored_row.write(game_index=0, gen=0, row=6, value=32)
    stored_row.write(game_index=0, gen=0, row=7, value=8)
    stored_row.write(game_index=0, gen=0, row=8, value=103)

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
        row_0 : felt, row_1 : felt, row_2 : felt, row_3 : felt,
        row_4 : felt, row_5 : felt, row_6 : felt, row_7 : felt,
        row_8 : felt, row_9 : felt, row_10 : felt, row_11 : felt,
        row_12 : felt, row_13 : felt, row_14 : felt
    ):
    alloc_locals
    let (local genesis_state : felt*) = alloc()
    assert genesis_state[0] = row_0
    assert genesis_state[1] = row_1
    assert genesis_state[2] = row_2
    assert genesis_state[3] = row_3
    assert genesis_state[4] = row_4
    assert genesis_state[5] = row_5
    assert genesis_state[6] = row_6
    assert genesis_state[7] = row_7
    assert genesis_state[8] = row_8
    assert genesis_state[9] = row_9
    assert genesis_state[10] = row_10
    assert genesis_state[11] = row_11
    assert genesis_state[12] = row_12
    assert genesis_state[13] = row_13
    assert genesis_state[14] = row_14

    # TODO - make input an array after resolving this issue:
    # Pytest expects the length to be a list element.
    # It wants [32, row_0, row_1, row_31]
    # Inside the function, the first element of the list is addressed
    # by index=1,  function accepts the list

    let (local caller) = get_caller_address()
    assert_not_zero(caller)
    # Check that the caller has enough credits, subtract some.
    # TODO Uncomment and test credits
    let (credits) = has_credits.read(caller)
    assert_le(CREDIT_REQUIREMENT, credits)
    has_credits.write(caller, credits - CREDIT_REQUIREMENT)

    # No two games are the same. Game_id == genesis hash.
    let (local game_id) = hash_game(genesis_state, 15)
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
    stored_row.write(game_index=idx, gen=0, row=0, value=row_0)
    stored_row.write(game_index=idx, gen=0, row=1, value=row_1)
    stored_row.write(game_index=idx, gen=0, row=2, value=row_2)
    stored_row.write(game_index=idx, gen=0, row=3, value=row_3)
    stored_row.write(game_index=idx, gen=0, row=4, value=row_4)
    stored_row.write(game_index=idx, gen=0, row=5, value=row_5)
    stored_row.write(game_index=idx, gen=0, row=6, value=row_6)
    stored_row.write(game_index=idx, gen=0, row=7, value=row_7)
    stored_row.write(game_index=idx, gen=0, row=8, value=row_8)
    stored_row.write(game_index=idx, gen=0, row=9, value=row_9)
    stored_row.write(game_index=idx, gen=0, row=10, value=row_10)
    stored_row.write(game_index=idx, gen=0, row=11, value=row_11)
    stored_row.write(game_index=idx, gen=0, row=12, value=row_12)
    stored_row.write(game_index=idx, gen=0, row=13, value=row_13)
    stored_row.write(game_index=idx, gen=0, row=14, value=row_14)

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
    # Iterates over rows, then cols to get an array of all cells.
    # Cell_states array is DIM**2 long: One cell per index (no packing).
    let (local cell_states_init : felt*) = alloc()
    unpack_rows(game_index=game_index, generation=prev_generation,
        cell_states=cell_states_init,row=DIM)

    # Evolve the game by one generation.
    let (local cell_states : felt*) = evaluate_rounds(1,
        cell_states_init)
    # Pack the game for compact storage.

    save_rows(game_index=game_index, generation=prev_generation + 1,
        cell_states=cell_states, row=DIM)

    # Save the user data.
    let (user) = get_caller_address()
    assert_not_zero(user)
    # Give a credit for advancing this particular game.
    let (credits) = has_credits.read(user)
    has_credits.write(user, credits + 1)

    # Save the current generation for easy retrieval.
    latest_game_generation.write(game_index, prev_generation + 1)
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


# Returns a list of rows for the specified generation.
@view
func view_game{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_index : felt,
        gen : felt
    ) -> (
        row_0 : felt, row_1 : felt, row_2 : felt, row_3 : felt,
        row_4 : felt, row_5 : felt, row_6 : felt, row_7 : felt,
        row_8 : felt, row_9 : felt, row_10 : felt, row_11 : felt,
        row_12 : felt, row_13 : felt, row_14 : felt
    ):

    let (row_0) = stored_row.read(game_index, gen, 0)
    let (row_1) = stored_row.read(game_index, gen, 1)
    let (row_2) = stored_row.read(game_index, gen, 2)
    let (row_3) = stored_row.read(game_index, gen, 3)
    let (row_4) = stored_row.read(game_index, gen, 4)
    let (row_5) = stored_row.read(game_index, gen, 5)
    let (row_6) = stored_row.read(game_index, gen, 6)
    let (row_7) = stored_row.read(game_index, gen, 7)
    let (row_8) = stored_row.read(game_index, gen, 8)
    let (row_9) = stored_row.read(game_index, gen, 9)
    let (row_10) = stored_row.read(game_index, gen, 10)
    let (row_11) = stored_row.read(game_index, gen, 11)
    let (row_12) = stored_row.read(game_index, gen, 12)
    let (row_13) = stored_row.read(game_index, gen, 13)
    let (row_14) = stored_row.read(game_index, gen, 14)

    return (row_0, row_1, row_2, row_3, row_4, row_5,
        row_6, row_7, row_8, row_9, row_10, row_11,
        row_12, row_13, row_14)
end

# Get a collection of recently created (or specified) games.
@view
func get_recently_created{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        enter_zero_or_specific_game_index : felt
    ) -> (game_index,
        a_gen, b_gen, c_gen, d_gen, e_gen,
        a_owner, b_owner, c_owner, d_owner, e_owner,
        a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14,
    ):
    # Can return the games for indices n, n-1, n-2, n-3, n-4, where
    # n is the the specified index. If the index specified is 0,
    # the n is set to the latest game.
    alloc_locals
    # If the caller used '0', use the latest ID, otherwise use specified.
    let (index) = latest_game_index.read()
    local game_index : felt
    if enter_zero_or_specific_game_index != 0:
        assert game_index = enter_zero_or_specific_game_index
    else:
        assert game_index = index
    end

    # Fetch images for the latest games
    let (local a_gen) = latest_game_generation.read(game_index)
    let (a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14) = view_game(game_index, a_gen)

    let (local b_gen) = latest_game_generation.read(game_index - 1)
    let (b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14) = view_game(game_index - 1, b_gen)

    let (local c_gen) = latest_game_generation.read(game_index - 2)
    let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14) = view_game(game_index - 2, c_gen)

    let (local d_gen) = latest_game_generation.read(game_index - 3)
    let (d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14) = view_game(game_index - 3, d_gen)

    let (local e_gen) = latest_game_generation.read(game_index - 4)
    let (e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14) = view_game(game_index - 4, e_gen)

    let (a_owner) = owner_of_game.read(game_index)
    let (b_owner) = owner_of_game.read(game_index - 1)
    let (c_owner) = owner_of_game.read(game_index - 2)
    let (d_owner) = owner_of_game.read(game_index - 3)
    let (e_owner) = owner_of_game.read(game_index - 4)

    return (game_index,
        a_gen, b_gen, c_gen, d_gen, e_gen,
        a_owner, b_owner, c_owner, d_owner, e_owner,
        a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14)
end


# Get a collection of recently created (or specified) games.
@view
func get_recent_generations_of_game{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        enter_zero_or_specific_game_index : felt
    ) -> (
        owner,
        a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14,
        z0, z1, z2, z3, z4, z5, z6, z7, z8, z9,
        z10, z11, z12, z13, z14,
    ):
    # Can return the states of a single game
    # for indices n, n-1, n-2, n-3, n-4, where
    # n is the the specified index. If the index specified is 0,
    # the n is set to the latest game.
    alloc_locals
    # If the caller used '0', use the latest ID, otherwise use specified.
    let (index) = latest_game_index.read()
    local game_index : felt
    if enter_zero_or_specific_game_index != 0:
        assert game_index = enter_zero_or_specific_game_index
    else:
        assert game_index = index
    end

    let (local gen) = latest_game_generation.read(game_index)

    # Fetch images for the latest generations
    let (a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14) = view_game(game_index, gen)

    let (b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14) = view_game(game_index, gen - 1)

    let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14) = view_game(game_index, gen - 2)

    let (d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14) = view_game(game_index, gen - 3)

    let (e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14) = view_game(game_index, gen - 4)

    # Also get the image from when the game was created.
    let (z0, z1, z2, z3, z4, z5, z6, z7, z8, z9,
        z10, z11, z12, z13, z14) = view_game(game_index, 0)

    let (owner) = owner_of_game.read(game_index)

    return (owner,
        a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14,
        z0, z1, z2, z3, z4, z5, z6, z7, z8, z9,
        z10, z11, z12, z13, z14)
end

# View games and tokens of a particular user.
@view
func get_user_data{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user_address : felt,
        enter_zero_or_specific_inventory_index : felt
    ) -> (
        count, credits,
        a_index, b_index, c_index, d_index, e_index,
        a_gen, b_gen, c_gen, d_gen, e_gen,
        a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14
    ):
    # Returns the current state of games that a user owns,
    # plus how many credits tokens they have, plus how many games
    # they own.
    # The games returned at the 5 most recently created, starting
    # with 'a', the most recent.
    # By specifying an inventory index you can query the next page
    # of tokens if they own more than 5.
    alloc_locals

    let (local credits) = has_credits.read(user_address)
    let (count) = user_game_count.read(user_address)
    local idx : felt
    if enter_zero_or_specific_inventory_index != 0:
        assert idx = enter_zero_or_specific_inventory_index
    else:
        assert idx = count - 1
    end

    let (local a_index) = game_index_from_inventory.read(user_address, idx)
    let (local b_index) = game_index_from_inventory.read(user_address, idx - 1)
    let (local c_index) = game_index_from_inventory.read(user_address, idx - 2)
    let (local d_index) = game_index_from_inventory.read(user_address, idx - 3)
    let (local e_index) = game_index_from_inventory.read(user_address, idx - 4)

    # Fetch images for the latest generations
    let (local a_gen) = latest_game_generation.read(a_index)
    let (a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14) = view_game(a_index, a_gen)

    let (local b_gen) = latest_game_generation.read(b_index)
    let (b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14) = view_game(b_index, b_gen)

    let (local c_gen) = latest_game_generation.read(c_index)
    let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14) = view_game(c_index, c_gen)

    let (local d_gen) = latest_game_generation.read(d_index)
    let (d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14) = view_game(d_index, d_gen)

    let (local e_gen) = latest_game_generation.read(e_index)
    let (e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14) = view_game(e_index, e_gen)

    return (count, credits,
        a_index, b_index, c_index, d_index, e_index,
        a_gen, b_gen, c_gen, d_gen, e_gen,
        a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14)
end

# Fetch state for a particular user to some depth from most recent.
@view
func get_recent_user_data{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user_address : felt,
        n_games_to_fetch : felt,
        n_gens_to_fetch_per_game : felt
    ) -> (
        credits : felt,
        games_owned_len : felt,
        games_owned : felt*,
        states_len : felt,
        states : felt*
    ):
    alloc_locals
    # Returns:
    # An array of m games with n states per game:
        # game_a: sa sb sc sd
        # game_b: sa sb sc sd
        #. etc.
        # Length = m * n * 32
    let (local count) = user_game_count.read(user_address)
    let (local inventory_indices : felt*) = alloc()
    # Build a list of games of interest that the player owns.
    # E.g., get 5 of the users games with indices: 9, 8, 7, 6 & 5.
    build_array(count - 1, n_games_to_fetch, inventory_indices)
    # Length of the state array:
    let states_len = n_games_to_fetch * n_gens_to_fetch_per_game * 15
    let (local states : felt*) = alloc()
    append_recent_user_games(user_address, inventory_indices,
        n_games_to_fetch, n_gens_to_fetch_per_game, states)
    let (local a_index) = game_index_from_inventory.read(
        user_address, inventory_indices[0])

    let (credits) = has_credits.read(user_address)
    return(
        credits,
        n_games_to_fetch,
        inventory_indices,
        states_len,
        states)
end

# Get info about n recently created games.
@view
func get_recent_games{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        number_of_recent_games : felt
    ) -> (g_game_index, current_gen, game_owner, game_genesis_row_0, game_genesis_row_1, game_genesis_row_2, game_genesis_row_3, game_genesis_row_4, game_genesis_row_5, game_genesis_row_6, game_genesis_row_7, game_genesis_row_8, game_genesis_row_9, game_genesis_row_10, game_genesis_row_11, game_genesis_row_12, game_genesis_row_13, game_genesis_row_14
    ):
    alloc_locals
    assert_not_zero(number_of_recent_games)

    # get latest game index
    let (g_game_index) = latest_game_index.read()
    # get its current gen
    let (current_gen) = latest_game_generation.read(g_game_index)
    # get its genesis state
    let (game_genesis_row_0) = stored_row.read(game_index=g_game_index, gen=0, row=0)
    let (game_genesis_row_1) = stored_row.read(game_index=g_game_index, gen=0, row=1)
    let (game_genesis_row_2) = stored_row.read(game_index=g_game_index, gen=0, row=2)
    let (game_genesis_row_3) = stored_row.read(game_index=g_game_index, gen=0, row=3)
    let (game_genesis_row_4) = stored_row.read(game_index=g_game_index, gen=0, row=4)
    let (game_genesis_row_5) = stored_row.read(game_index=g_game_index, gen=0, row=5)
    let (game_genesis_row_6) = stored_row.read(game_index=g_game_index, gen=0, row=6)
    let (game_genesis_row_7) = stored_row.read(game_index=g_game_index, gen=0, row=7)
    let (game_genesis_row_8) = stored_row.read(game_index=g_game_index, gen=0, row=8)
    let (game_genesis_row_9) = stored_row.read(game_index=g_game_index, gen=0, row=9)
    let (game_genesis_row_10) = stored_row.read(game_index=g_game_index, gen=0, row=10)
    let (game_genesis_row_11) = stored_row.read(game_index=g_game_index, gen=0, row=11)
    let (game_genesis_row_12) = stored_row.read(game_index=g_game_index, gen=0, row=12)
    let (game_genesis_row_13) = stored_row.read(game_index=g_game_index, gen=0, row=13)
    let (game_genesis_row_14) = stored_row.read(game_index=g_game_index, gen=0, row=14)

    # get the owner
    let (game_owner) = owner_of_game.read(g_game_index)

    # repeat in recursion, pack into something and return

    return (g_game_index=g_game_index, current_gen=current_gen, game_owner=game_owner, game_genesis_row_0=game_genesis_row_0, game_genesis_row_1=game_genesis_row_1, game_genesis_row_2=game_genesis_row_2, game_genesis_row_3=game_genesis_row_3, game_genesis_row_4=game_genesis_row_4, game_genesis_row_5=game_genesis_row_5, game_genesis_row_6=game_genesis_row_6, game_genesis_row_7=game_genesis_row_7, game_genesis_row_8=game_genesis_row_8, game_genesis_row_9=game_genesis_row_9, game_genesis_row_10=game_genesis_row_10, game_genesis_row_11=game_genesis_row_11, game_genesis_row_12=game_genesis_row_12, game_genesis_row_13=game_genesis_row_13, game_genesis_row_14=game_genesis_row_14)
end

#############################
##### Private functions #####
#############################

# Gets m games with n states. 1D array representing a 2D state array.
func append_recent_user_games{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user : felt,
        user_inventory_indices : felt*,
        n_games : felt,
        n_gens_per_game : felt,
        states : felt*
    ):
    alloc_locals
    if n_games == 0:
        return ()
    end
    append_recent_user_games(user, user_inventory_indices,
        n_games - 1, n_gens_per_game, states)
    # Upon first entry here, n_games=1.
    let inventory_index = n_games - 1
    # Get the global game index using the index of the players inventory.
    let game_index = user_inventory_indices[inventory_index]
    # Get the most recent index for the given game
    let (latest_gen) = latest_game_generation.read(game_index)
    # Calculate the offset for this particular game.
    # For the first game in the inventory, offset=0.
    let offset = inventory_index * n_gens_per_game * 15
    # Build an array of the desired generations.
    let (local game_gens : felt*) = alloc()
    build_array(latest_gen, n_gens_per_game, game_gens)
    # For each game, loop over the requested number of recent states.
    append_states(game_index, n_gens_per_game, game_gens, states, offset)

    return ()
end


# Creates an array of n numbers starting from x: [x, x-1, x-2, x-n-1].
func build_array{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        x : felt,
        n : felt,
        array : felt*
    ):
    # Returns a descending array of continuous numbers.
    if n == 0:
        return ()
    end
    build_array(x, n-1, array)
    # n=1 upon first entry here.
    let index = n - 1
    assert array[index] = x - index
    return ()
end


# For a list of gen_ids, adds state to a state array (for a frontend).
func append_states{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_index : felt,
        len : felt,
        gen_id_array : felt*,
        states : felt*,
        offset : felt
    ):
    # This helper function can be used to grab a large number of specific
    # The offset is where to start appending this particular
    # set of states (there may be preceeding games in the array).
    # states for a frontend to quickly get game data.
    if len == 0:
        return ()
    end
    # Loop with recursion.
    append_states(game_index, len - 1, gen_id_array, states, offset)
    let index = len - 1
    # Get rows for the n-th requested generation.
    let (r0, r1, r2, r3, r4, r5, r6, r7, r8, r9,
        r10, r11, r12, r13, r14) = view_game(game_index, gen_id_array[index])
    # Append 32 new rows to the multi-state for every gen requested.
    assert states[offset + index * 15 + 0] = r0
    assert states[offset + index * 15 + 1] = r1
    assert states[offset + index * 15 + 2] = r2
    assert states[offset + index * 15 + 3] = r3
    assert states[offset + index * 15 + 4] = r4
    assert states[offset + index * 15 + 5] = r5
    assert states[offset + index * 15 + 6] = r6
    assert states[offset + index * 15 + 7] = r7
    assert states[offset + index * 15 + 8] = r8
    assert states[offset + index * 15 + 9] = r9
    assert states[offset + index * 15 + 10] = r10
    assert states[offset + index * 15 + 11] = r11
    assert states[offset + index * 15 + 12] = r12
    assert states[offset + index * 15 + 13] = r13
    assert states[offset + index * 15 + 14] = r14

    return ()
end


# Pre-sim. Walk rows then columns to build state.
func unpack_rows{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_index : felt,
        generation : felt,
        cell_states : felt*,
        row : felt
    ):
    alloc_locals
    if row == 0:
        return ()
    end

    unpack_rows(game_index=game_index, generation=generation,
        cell_states=cell_states, row=row-1)
    # Get the binary encoded store.
    # (Note, on first entry, row=1 so row-1 gets the index)
    let (saved_row) = stored_row.read(game_index=game_index,
        gen=generation, row=row-1)

    let (local stored_row_unpacked : felt*) = alloc()
    split_int(
        value=saved_row,
        n=15,
        base=2,
        bound=2,
        output=stored_row_unpacked)
    # Pass the 32-long array to add to the cell_states array.
    append_cols(cell_states=cell_states,
        row=row-1, col=DIM, stored_row=stored_row_unpacked)
    return ()
end

# Saves inidividual rows in the given array. (pack rows and save)
func save_rows{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        game_index : felt,
        generation : felt,
        cell_states : felt*,
        row : felt
    ):
    if row == 0:
        return ()
    end

    save_rows(
        game_index=game_index,
        generation=generation,
        cell_states=cell_states,
        row=row-1)
    # (Note, on first entry, row=1 so row-1 gets the index)
    # Create the binary encoded state for the row.
    let (row_to_store) = pack_cols(cell_states=cell_states,
        row=row-1, col=DIM, row_to_store=0)

    # Permanently store the game state.
    stored_row.write(
        game_index=game_index,
        gen=generation,
        row=row-1,
        value=row_to_store)

    return ()
end

