%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_or
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.hash_state import (hash_init,
    hash_update, HashState)
from starkware.cairo.common.math import (unsigned_div_rem, assert_nn,
    assert_not_zero, assert_nn_le, assert_le, assert_not_equal)
from starkware.cairo.common.pow import pow
from starkware.starknet.common.syscalls import (call_contract,
    get_caller_address)


from contracts.utils.hash_game import hash_game
from contracts.utils.packing import pack_cols, unpack_cols
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

##### Public functions #####
@external
func spawn{
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
    stored_row.write(game_index=0, gen=0, row=12, value=32)
    stored_row.write(game_index=0, gen=0, row=13, value=8)
    stored_row.write(game_index=0, gen=0, row=14, value=103)

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
        row_12 : felt, row_13 : felt, row_14 : felt, row_15 : felt,
        row_16 : felt, row_17 : felt, row_18 : felt, row_19 : felt,
        row_20 : felt, row_21 : felt, row_22 : felt, row_23 : felt,
        row_24 : felt, row_25 : felt, row_26 : felt, row_27 : felt,
        row_28 : felt, row_29 : felt, row_30 : felt, row_31 : felt
    ):
    # Accepts a 32 element list representing the rows of the game.
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
    assert genesis_state[15] = row_15
    assert genesis_state[16] = row_16
    assert genesis_state[17] = row_17
    assert genesis_state[18] = row_18
    assert genesis_state[19] = row_19
    assert genesis_state[20] = row_20
    assert genesis_state[21] = row_21
    assert genesis_state[22] = row_22
    assert genesis_state[23] = row_23
    assert genesis_state[24] = row_24
    assert genesis_state[25] = row_25
    assert genesis_state[26] = row_26
    assert genesis_state[27] = row_27
    assert genesis_state[28] = row_28
    assert genesis_state[29] = row_29
    assert genesis_state[30] = row_30
    assert genesis_state[31] = row_31

    # TODO - make input an array after resolving this issue:
    # Pytest expects the length to be a list element.
    # It wants [32, row_0, row_1, row_31]
    # Inside the function, the first element of the list is addressed
    # by index=1,  function accepts the list

    let (local caller) = get_caller_address()
    # Check that the caller has enough credits, subtract some.
    # TODO Uncomment and test credits
    let (credits) = has_credits.read(caller)
    assert_le(CREDIT_REQUIREMENT, credits)
    has_credits.write(caller, credits - CREDIT_REQUIREMENT)

    # No two games are the same. Game_id == genesis hash.
    let (local game_id) = hash_game(genesis_state, 32)
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
    stored_row.write(game_index=idx, gen=0, row=15, value=row_15)
    stored_row.write(game_index=idx, gen=0, row=16, value=row_16)
    stored_row.write(game_index=idx, gen=0, row=17, value=row_17)
    stored_row.write(game_index=idx, gen=0, row=18, value=row_18)
    stored_row.write(game_index=idx, gen=0, row=19, value=row_19)
    stored_row.write(game_index=idx, gen=0, row=20, value=row_20)
    stored_row.write(game_index=idx, gen=0, row=21, value=row_21)
    stored_row.write(game_index=idx, gen=0, row=22, value=row_22)
    stored_row.write(game_index=idx, gen=0, row=23, value=row_23)
    stored_row.write(game_index=idx, gen=0, row=24, value=row_24)
    stored_row.write(game_index=idx, gen=0, row=25, value=row_25)
    stored_row.write(game_index=idx, gen=0, row=26, value=row_26)
    stored_row.write(game_index=idx, gen=0, row=27, value=row_27)
    stored_row.write(game_index=idx, gen=0, row=28, value=row_28)
    stored_row.write(game_index=idx, gen=0, row=29, value=row_29)
    stored_row.write(game_index=idx, gen=0, row=30, value=row_30)
    stored_row.write(game_index=idx, gen=0, row=31, value=row_31)

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
        row_12 : felt, row_13 : felt, row_14 : felt, row_15 : felt,
        row_16 : felt, row_17 : felt, row_18 : felt, row_19 : felt,
        row_20 : felt, row_21 : felt, row_22 : felt, row_23 : felt,
        row_24 : felt, row_25 : felt, row_26 : felt, row_27 : felt,
        row_28 : felt, row_29 : felt, row_30 : felt, row_31 : felt
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
    let (row_15) = stored_row.read(game_index, gen, 15)
    let (row_16) = stored_row.read(game_index, gen, 16)
    let (row_17) = stored_row.read(game_index, gen, 17)
    let (row_18) = stored_row.read(game_index, gen, 18)
    let (row_19) = stored_row.read(game_index, gen, 19)
    let (row_20) = stored_row.read(game_index, gen, 20)
    let (row_21) = stored_row.read(game_index, gen, 21)
    let (row_22) = stored_row.read(game_index, gen, 22)
    let (row_23) = stored_row.read(game_index, gen, 23)
    let (row_24) = stored_row.read(game_index, gen, 24)
    let (row_25) = stored_row.read(game_index, gen, 25)
    let (row_26) = stored_row.read(game_index, gen, 26)
    let (row_27) = stored_row.read(game_index, gen, 27)
    let (row_28) = stored_row.read(game_index, gen, 28)
    let (row_29) = stored_row.read(game_index, gen, 29)
    let (row_30) = stored_row.read(game_index, gen, 30)
    let (row_31) = stored_row.read(game_index, gen, 31)

    return (row_0, row_1, row_2, row_3, row_4, row_5,
        row_6, row_7, row_8, row_9, row_10, row_11,
        row_12, row_13, row_14, row_15, row_16, row_17,
        row_18, row_19, row_20, row_21, row_22, row_23,
        row_24, row_25, row_26, row_27, row_28, row_29,
        row_30, row_31)
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
        a10, a11, a12, a13, a14, a15, a16, a17, a18, a19,
        a20, a21, a22, a23, a24, a25, a26, a27, a28, a29,
        a30, a31,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14, b15, b16, b17, b18, b19,
        b20, b21, b22, b23, b24, b25, b26, b27, b28, b29,
        b30, b31,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14, c15, c16, c17, c18, c19,
        c20, c21, c22, c23, c24, c25, c26, c27, c28, c29,
        c30, c31,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14, d15, d16, d17, d18, d19,
        d20, d21, d22, d23, d24, d25, d26, d27, d28, d29,
        d30, d31,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14, e15, e16, e17, e18, e19,
        e20, e21, e22, e23, e24, e25, e26, e27, e28, e29,
        e30, e31
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
        a10, a11, a12, a13, a14, a15, a16, a17, a18, a19,
        a20, a21, a22, a23, a24, a25, a26, a27, a28, a29,
        a30, a31) = view_game(game_index, a_gen)

    let (local b_gen) = latest_game_generation.read(game_index - 1)
    let (b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14, b15, b16, b17, b18, b19,
        b20, b21, b22, b23, b24, b25, b26, b27, b28, b29,
        b30, b31) = view_game(game_index - 1, b_gen)

    let (local c_gen) = latest_game_generation.read(game_index - 2)
    let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14, c15, c16, c17, c18, c19,
        c20, c21, c22, c23, c24, c25, c26, c27, c28, c29,
        c30, c31) = view_game(game_index - 2, c_gen)

    let (local d_gen) = latest_game_generation.read(game_index - 3)
    let (d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14, d15, d16, d17, d18, d19,
        d20, d21, d22, d23, d24, d25, d26, d27, d28, d29,
        d30, d31) = view_game(game_index - 3, d_gen)

    let (local e_gen) = latest_game_generation.read(game_index - 4)
    let (e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14, e15, e16, e17, e18, e19,
        e20, e21, e22, e23, e24, e25, e26, e27, e28, e29,
        e30, e31) = view_game(game_index - 4, e_gen)

    let (a_owner) = owner_of_game.read(game_index)
    let (b_owner) = owner_of_game.read(game_index - 1)
    let (c_owner) = owner_of_game.read(game_index - 2)
    let (d_owner) = owner_of_game.read(game_index - 3)
    let (e_owner) = owner_of_game.read(game_index - 4)

    return (game_index,
        a_gen, b_gen, c_gen, d_gen, e_gen,
        a_owner, b_owner, c_owner, d_owner, e_owner,
        a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14, a15, a16, a17, a18, a19,
        a20, a21, a22, a23, a24, a25, a26, a27, a28, a29,
        a30, a31,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14, b15, b16, b17, b18, b19,
        b20, b21, b22, b23, b24, b25, b26, b27, b28, b29,
        b30, b31,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14, c15, c16, c17, c18, c19,
        c20, c21, c22, c23, c24, c25, c26, c27, c28, c29,
        c30, c31,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14, d15, d16, d17, d18, d19,
        d20, d21, d22, d23, d24, d25, d26, d27, d28, d29,
        d30, d31,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14, e15, e16, e17, e18, e19,
        e20, e21, e22, e23, e24, e25, e26, e27, e28, e29,
        e30, e31)
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
        a10, a11, a12, a13, a14, a15, a16, a17, a18, a19,
        a20, a21, a22, a23, a24, a25, a26, a27, a28, a29,
        a30, a31,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14, b15, b16, b17, b18, b19,
        b20, b21, b22, b23, b24, b25, b26, b27, b28, b29,
        b30, b31,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14, c15, c16, c17, c18, c19,
        c20, c21, c22, c23, c24, c25, c26, c27, c28, c29,
        c30, c31,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14, d15, d16, d17, d18, d19,
        d20, d21, d22, d23, d24, d25, d26, d27, d28, d29,
        d30, d31,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14, e15, e16, e17, e18, e19,
        e20, e21, e22, e23, e24, e25, e26, e27, e28, e29,
        e30, e31,
        z0, z1, z2, z3, z4, z5, z6, z7, z8, z9,
        z10, z11, z12, z13, z14, z15, z16, z17, z18, z19,
        z20, z21, z22, z23, z24, z25, z26, z27, z28, z29,
        z30, z31
    ):
    # Can return the states of a single game
    # for indices n, n-1, n-2, n-3, n-4, where
    # n is the the specified index. If the index specified is 0,
    # the n is set to the latest ga.
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
        a10, a11, a12, a13, a14, a15, a16, a17, a18, a19,
        a20, a21, a22, a23, a24, a25, a26, a27, a28, a29,
        a30, a31) = view_game(game_index, gen)

    let (b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14, b15, b16, b17, b18, b19,
        b20, b21, b22, b23, b24, b25, b26, b27, b28, b29,
        b30, b31) = view_game(game_index, gen - 1)

    let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14, c15, c16, c17, c18, c19,
        c20, c21, c22, c23, c24, c25, c26, c27, c28, c29,
        c30, c31) = view_game(game_index, gen - 2)

    let (d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14, d15, d16, d17, d18, d19,
        d20, d21, d22, d23, d24, d25, d26, d27, d28, d29,
        d30, d31) = view_game(game_index, gen - 3)

    let (e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14, e15, e16, e17, e18, e19,
        e20, e21, e22, e23, e24, e25, e26, e27, e28, e29,
        e30, e31) = view_game(game_index, gen - 4)

    # Also get the image from when the game was created.
    let (z0, z1, z2, z3, z4, z5, z6, z7, z8, z9,
        z10, z11, z12, z13, z14, z15, z16, z17, z18, z19,
        z20, z21, z22, z23, z24, z25, z26, z27, z28, z29,
        z30, z31) = view_game(game_index, 0)

    let (owner) = owner_of_game.read(game_index)

    return (owner,
        a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14, a15, a16, a17, a18, a19,
        a20, a21, a22, a23, a24, a25, a26, a27, a28, a29,
        a30, a31,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14, b15, b16, b17, b18, b19,
        b20, b21, b22, b23, b24, b25, b26, b27, b28, b29,
        b30, b31,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14, c15, c16, c17, c18, c19,
        c20, c21, c22, c23, c24, c25, c26, c27, c28, c29,
        c30, c31,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14, d15, d16, d17, d18, d19,
        d20, d21, d22, d23, d24, d25, d26, d27, d28, d29,
        d30, d31,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14, e15, e16, e17, e18, e19,
        e20, e21, e22, e23, e24, e25, e26, e27, e28, e29,
        e30, e31,
        z0, z1, z2, z3, z4, z5, z6, z7, z8, z9,
        z10, z11, z12, z13, z14, z15, z16, z17, z18, z19,
        z20, z21, z22, z23, z24, z25, z26, z27, z28, z29,
        z30, z31)
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
        a10, a11, a12, a13, a14, a15, a16, a17, a18, a19,
        a20, a21, a22, a23, a24, a25, a26, a27, a28, a29,
        a30, a31,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14, b15, b16, b17, b18, b19,
        b20, b21, b22, b23, b24, b25, b26, b27, b28, b29,
        b30, b31,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14, c15, c16, c17, c18, c19,
        c20, c21, c22, c23, c24, c25, c26, c27, c28, c29,
        c30, c31,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14, d15, d16, d17, d18, d19,
        d20, d21, d22, d23, d24, d25, d26, d27, d28, d29,
        d30, d31,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14, e15, e16, e17, e18, e19,
        e20, e21, e22, e23, e24, e25, e26, e27, e28, e29,
        e30, e31
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
        a10, a11, a12, a13, a14, a15, a16, a17, a18, a19,
        a20, a21, a22, a23, a24, a25, a26, a27, a28, a29,
        a30, a31) = view_game(a_index, a_gen)

    let (local b_gen) = latest_game_generation.read(b_index)
    let (b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14, b15, b16, b17, b18, b19,
        b20, b21, b22, b23, b24, b25, b26, b27, b28, b29,
        b30, b31) = view_game(b_index, b_gen)

    let (local c_gen) = latest_game_generation.read(c_index)
    let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14, c15, c16, c17, c18, c19,
        c20, c21, c22, c23, c24, c25, c26, c27, c28, c29,
        c30, c31) = view_game(c_index, c_gen)

    let (local d_gen) = latest_game_generation.read(d_index)
    let (d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14, d15, d16, d17, d18, d19,
        d20, d21, d22, d23, d24, d25, d26, d27, d28, d29,
        d30, d31) = view_game(d_index, d_gen)

    let (local e_gen) = latest_game_generation.read(e_index)
    let (e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14, e15, e16, e17, e18, e19,
        e20, e21, e22, e23, e24, e25, e26, e27, e28, e29,
        e30, e31) = view_game(e_index, e_gen)

    return (count, credits,
        a_index, b_index, c_index, d_index, e_index,
        a_gen, b_gen, c_gen, d_gen, e_gen,
        a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14, a15, a16, a17, a18, a19,
        a20, a21, a22, a23, a24, a25, a26, a27, a28, a29,
        a30, a31,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14, b15, b16, b17, b18, b19,
        b20, b21, b22, b23, b24, b25, b26, b27, b28, b29,
        b30, b31,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14, c15, c16, c17, c18, c19,
        c20, c21, c22, c23, c24, c25, c26, c27, c28, c29,
        c30, c31,
        d0, d1, d2, d3, d4, d5, d6, d7, d8, d9,
        d10, d11, d12, d13, d14, d15, d16, d17, d18, d19,
        d20, d21, d22, d23, d24, d25, d26, d27, d28, d29,
        d30, d31,
        e0, e1, e2, e3, e4, e5, e6, e7, e8, e9,
        e10, e11, e12, e13, e14, e15, e16, e17, e18, e19,
        e20, e21, e22, e23, e24, e25, e26, e27, e28, e29,
        e30, e31)
end

##### Private functions #####
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
    if row == 0:
        return ()
    end

    unpack_rows(game_index=game_index, generation=generation,
        cell_states=cell_states, row=row-1)
    # Get the binary encoded store.
    # (Note, on first entry, row=1 so row-1 gets the index)
    let (packed_row) = stored_row.read(game_index=game_index,
        gen=generation, row=row-1)

    unpack_cols(cell_states=cell_states,
        row=row-1, col=DIM, stored_row=packed_row)

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

