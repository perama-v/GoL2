%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_or
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.math import (unsigned_div_rem, assert_nn,
    assert_not_zero, assert_nn_le, assert_not_equal, split_int)
from starkware.cairo.common.pow import pow
from starkware.starknet.common.syscalls import (call_contract,
    get_caller_address)

from contracts.utils.packing import pack_cols, append_cols
from contracts.utils.life_rules import (evaluate_rounds,
    apply_rules, get_adjacent)

## This is a high-storage implementation that does not require
## Events or a token contract.

##### Constants #####
# Width of the simulation grid.
const DIM = 15

##### Storage #####

# Returns the gen_id of the current alive generation.
@storage_var
func current_generation() -> (gen_id : felt):
end

# Stores how many tokens have been redeemed for a give_life act.
@storage_var
func redemption_count() -> (count : felt):
end

# A store of the sequence of redemptions for walking the history.
@storage_var
func token_at_redemption_index(red_index) -> (token_id : felt):
end

# A store of the sequence of redemptions for walking the history.
@storage_var
func redemption_index_of_token(token_id) -> (red_index : felt):
end

# Returns the user_id for a given generation_id.
@storage_var
func owner_of_generation(gen_id : felt) -> (user_id : felt):
end

# Is a stored list of ID's indexed from zero for every user.
@storage_var
func generation_of_owner(
        user_id : felt,
        nth_personal_token : felt
    ) -> (
        gen_id : felt
    ):
end

# Returns the total number of tokens owned by a user.
@storage_var
func count_tokens_owned(user_id : felt) -> (tokens_owned : felt):
end

# Returns at which generation of the game a tokens give_life was used.
@storage_var
func token_redeemed_at(token_id : felt) -> (gen_id_at_redemption : felt):
end

# For a given generation, returns the highest redemption index.
# This way, you can find all the give_life cells at historical states.
@storage_var
func highest_redemption_index_of_gen(gen_id : felt) -> (
    redemption_index_of_token : felt):
end

# Records the history of the game on chain.
# Could pack this more efficiently (E.g., 1/4 storage if packed).
@storage_var
func historical_row(
        gen_id : felt,
        row_index : felt
    ) -> (
        row_state : felt
    ):
end

# For a given token id, returns the cell as (row, col) by index.
@storage_var
func token_gave_life(
        gen_id_of_token : felt,
    ) -> (
        cell : (felt, felt)
    ):
end

##################

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():

    # Start with an acorn near bottom right in a 32x32 grid.
    # https://www.conwaylife.com/patterns/acorn.cells
    # https://playgameoflife.com/lexicon/acorn
    historical_row.write(1, 6, 32)
    historical_row.write(1, 7, 8)
    historical_row.write(1, 8, 103)
    # Set the current generation as '1'.
    current_generation.write(1)
    # Prevent entry to this function again.
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
    }(
        user_id : felt
    ):
    alloc_locals
    let (local last_gen) = current_generation.read()
    # Limit to one generation per turn.
    local generations = 1
    local new_gen = last_gen + generations
    # Unpack the stored game
    # Iterates over rows, then cols to get an array of all cells.
    let (local cell_states_init : felt*) = alloc()
    unpack_rows(gen_id=last_gen, cell_states=cell_states_init,row=DIM)

    # Run the game for the specified number of generations.
    let (local cell_states : felt*) = evaluate_rounds(
        generations, cell_states_init)
    # Pack the game for storage.
    pack_rows(new_gen, cell_states, row=DIM)

    # Save the current generation.
    current_generation.write(new_gen)

    # To expose information to the frontend (pending Token/Events).
    let user = user_id
    let (caller) = get_caller_address()
    # For testing, skip account contract use.
    assert_not_zero(caller)
    assert user = caller

    let (prev_tokens) = count_tokens_owned.read(user)
    count_tokens_owned.write(user, prev_tokens + 1)
    # Store the token_id as a zero-based index of the users token.
    generation_of_owner.write(user, prev_tokens, new_gen)
    owner_of_generation.write(new_gen, user)
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
        user_id : felt,
        cell_row_index : felt,
        cell_column_index : felt,
        gen_id_of_token_to_redeem : felt
    ):
    # This does not trigger an evolution. Multiple give_life
    # operations may be called, building up a shape before
    # a turn triggers evolution.
    alloc_locals

    # Only the caller can redeem
    let (user) = get_caller_address()
    # For testing, skip account contract use. TODO add accounts.
    assert user = user_id
    assert_not_zero(user)

    let (local owner) = owner_of_generation.read(gen_id_of_token_to_redeem)
    # Enable this check when accounts are used.
    assert owner = user_id

    activate_cell(cell_row_index, cell_column_index)

    # Temporary record pending Events.
    let (current_gen) = current_generation.read()
    let (local redeemed) = token_redeemed_at.read(gen_id_of_token_to_redeem)
    # Assumption: storage is initialized as zero.
    # Enable this check when accounts are used.
    assert redeemed = 0

    token_gave_life.write(gen_id_of_token_to_redeem,
        (cell_row_index, cell_column_index))
    token_redeemed_at.write(gen_id_of_token_to_redeem, current_gen)

    # Index the redemption for simpler database creation.
    let (redemptions) = redemption_count.read()
    redemption_count.write(redemptions + 1)
    # New redemption index = count - 1 + 1 = count
    token_at_redemption_index.write(redemptions, current_gen)
    redemption_index_of_token.write(current_gen, redemptions)
    # For the current generation overwrite the redemption index.
    # If multiple give_live actions are used, stores the highest index.
    highest_redemption_index_of_gen.write(current_gen, redemptions)
    return ()
end


# Returns a the current generation id.
# The index is based on turns while the id is evolution steps.
@view
func current_generation_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
    ) -> (
        gen_id : felt
    ):
    let (gen_id) = current_generation.read()
    return (gen_id)
end

# Get the incrementing index of every give life action.
@view
func latest_give_life_index{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
    ) -> (
        redemption_index : felt
    ):
    let (red_index) = redemption_count.read()
    # Index is: count - 1
    return (red_index - 1)
end


# Returns the index of redemption for a given token id.
@view
func redemption_index_from_token_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token_id : felt
    ) -> (
        red_index : felt
    ):
    let (red_index) = redemption_index_of_token.read(token_id)
    return (red_index)
end


# Returns the token id for a given redemption index.
@view
func token_id_from_redemption_index{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        red_index : felt
    ) -> (
        token_id : felt
    ):
    let (token_id) = token_at_redemption_index.read(red_index)
    return (token_id)
end


# Returns the highest redemption index at a particular generation.
@view
func highest_redemption_index_of_generation{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        generation_id : felt
    ) -> (
        redemption_index : felt
    ):
    let (red_index) = highest_redemption_index_of_gen.read(
        generation_id)
    return (red_index)
end


# Returns a list of rows for the specified generation.
@view
func view_game{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        id_of_generation_to_view : felt
    ) -> (
        row_0 : felt, row_1 : felt, row_2 : felt, row_3 : felt,
        row_4 : felt, row_5 : felt, row_6 : felt, row_7 : felt,
        row_8 : felt, row_9 : felt, row_10 : felt, row_11 : felt,
        row_12 : felt, row_13 : felt, row_14 : felt
    ):
    let gen_id = id_of_generation_to_view

    let (row_0) = historical_row.read(gen_id, 0)
    let (row_1) = historical_row.read(gen_id, 1)
    let (row_2) = historical_row.read(gen_id, 2)
    let (row_3) = historical_row.read(gen_id, 3)
    let (row_4) = historical_row.read(gen_id, 4)
    let (row_5) = historical_row.read(gen_id, 5)
    let (row_6) = historical_row.read(gen_id, 6)
    let (row_7) = historical_row.read(gen_id, 7)
    let (row_8) = historical_row.read(gen_id, 8)
    let (row_9) = historical_row.read(gen_id, 9)
    let (row_10) = historical_row.read(gen_id, 10)
    let (row_11) = historical_row.read(gen_id, 11)
    let (row_12) = historical_row.read(gen_id, 12)
    let (row_13) = historical_row.read(gen_id, 13)
    let (row_14) = historical_row.read(gen_id, 14)

    return (row_0, row_1, row_2, row_3, row_4, row_5,
        row_6, row_7, row_8, row_9, row_10, row_11,
        row_12, row_13, row_14)
end


# First call this function to see how many tokens a user has.
@view
func user_token_count{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user_id : felt
    ) -> (
        count : felt
    ):
    let (count) = count_tokens_owned.read(user_id)
    return(count)
end


# Call after user_token_count. 0-based index gets token data of a user.
@view
func get_user_data{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user_id : felt,
        nth_token_of_user : felt
    ) -> (
        token_id : felt,
        has_used_give_life : felt,
        generation_during_give_life : felt,
        alive_cell_row : felt,
        alive_cell_col : felt
    ):
    alloc_locals
    # Get the token_id (generation during mint) of the specified token.
    let (token_id) = generation_of_owner.read(user_id, nth_token_of_user)
    let (redeemed) = token_redeemed_at.read(token_id)
    let (alive_cell) = token_gave_life.read(token_id)

    local has_used_give_life
    local alive_cell_row
    local alive_cell_col
    if redeemed == 0:
        assert has_used_give_life = 0
        assert alive_cell_row = 0
        assert alive_cell_col = 0
    else:
        assert has_used_give_life = 1
        assert alive_cell_row = alive_cell[0]
        assert alive_cell_col = alive_cell[1]
    end

    return (
        token_id=token_id,
        has_used_give_life=has_used_give_life,
        generation_during_give_life=redeemed,
        alive_cell_row=alive_cell_row,
        alive_cell_col=alive_cell_col
    )
end


# The token_id (equal to gen_id at end of mint/turn) can be used to get data.
@view
func get_token_data{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token_id : felt
    ) -> (
        has_used_give_life : felt,
        generation_during_give_life : felt,
        alive_cell_row : felt,
        alive_cell_col : felt,
        owner : felt
    ):
    alloc_locals
    let (redeemed) = token_redeemed_at.read(token_id)
    let (alive_cell) = token_gave_life.read(token_id)

    local has_used_give_life
    local alive_cell_row
    local alive_cell_col
    if redeemed == 0:
        assert has_used_give_life = 0
        assert alive_cell_row = 0
        assert alive_cell_col = 0
    else:
        assert has_used_give_life = 1
        assert alive_cell_row = alive_cell[0]
        assert alive_cell_col = alive_cell[1]
    end

    let (owner) = owner_of_generation.read(token_id)

    return (
        has_used_give_life=has_used_give_life,
        generation_during_give_life=redeemed,
        alive_cell_row=alive_cell_row,
        alive_cell_col=alive_cell_col,
        owner=owner
    )
end

# Get a collection of useful contemporary information
@view
func latest_useful_state{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        enter_zero_or_specific_generation_id : felt
    ) -> (
        gen_id, latest_red, a_owner, b_owner, c_owner,
        r0_id, r0_gen, r0_row, r0_col, r0_owner,
        r1_id, r1_gen, r1_row, r1_col, r1_owner,
        r2_id, r2_gen, r2_row, r2_col, r2_owner,
        r3_id, r3_gen, r3_row, r3_col, r3_owner,
        r4_id, r4_gen, r4_row, r4_col, r4_owner,
        r5_id, r5_gen, r5_row, r5_col, r5_owner,
        r6_id, r6_gen, r6_row, r6_col, r6_owner,
        r7_id, r7_gen, r7_row, r7_col, r7_owner,
        r8_id, r8_gen, r8_row, r8_col, r8_owner,
        r9_id, r9_gen, r9_row, r9_col, r9_owner,
        a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14
    ):
    # gen_id = la
    alloc_locals
    # If the caller used '0', use the latest ID, otherwise use specified.
    let (current_id) = current_generation.read()

    local gen_id : felt
    if enter_zero_or_specific_generation_id != 0:
        assert gen_id = enter_zero_or_specific_generation_id
    else:
        assert gen_id = current_id
    end
    # Returns:
    # Current generation_id
    # three images (a=current, b=n-1, c=n-2).
    # a4 = image a (current image), row index 4 (fifth row).

    # For the given generation, get the index of the latest
    # give_live redemption.
    let (latest_red) = highest_redemption_index_of_gen.read(gen_id)

    # TODO if caller is asking for an older generation, perhaps need
    # fetch for redemption tokens from that generation.
    # Get token_ids of the 5 most recently redeemed give-life tokens.
    let (r0_id) = token_id_from_redemption_index(latest_red)
    let (r1_id) = token_id_from_redemption_index(latest_red - 1)
    let (r2_id) = token_id_from_redemption_index(latest_red - 2)
    let (r3_id) = token_id_from_redemption_index(latest_red - 3)
    let (r4_id) = token_id_from_redemption_index(latest_red - 4)
    let (r5_id) = token_id_from_redemption_index(latest_red - 5)
    let (r6_id) = token_id_from_redemption_index(latest_red - 6)
    let (r7_id) = token_id_from_redemption_index(latest_red - 7)
    let (r8_id) = token_id_from_redemption_index(latest_red - 8)
    let (r9_id) = token_id_from_redemption_index(latest_red - 9)
    # Get the effect of the give_life action (generation, row, col).
    let (_, r0_gen, r0_row, r0_col, r0_owner) = get_token_data(r0_id)
    let (_, r1_gen, r1_row, r1_col, r1_owner) = get_token_data(r1_id)
    let (_, r2_gen, r2_row, r2_col, r2_owner) = get_token_data(r2_id)
    let (_, r3_gen, r3_row, r3_col, r3_owner) = get_token_data(r3_id)
    let (_, r4_gen, r4_row, r4_col, r4_owner) = get_token_data(r4_id)
    let (_, r5_gen, r5_row, r5_col, r5_owner) = get_token_data(r5_id)
    let (_, r6_gen, r6_row, r6_col, r6_owner) = get_token_data(r6_id)
    let (_, r7_gen, r7_row, r7_col, r7_owner) = get_token_data(r7_id)
    let (_, r8_gen, r8_row, r8_col, r8_owner) = get_token_data(r8_id)
    let (_, r9_gen, r9_row, r9_col, r9_owner) = get_token_data(r9_id)

    let (a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14) = view_game(gen_id)

    let (b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14) = view_game(gen_id - 1)

    let (c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14) = view_game(gen_id - 2)

    let (a_owner) = owner_of_generation.read(gen_id)
    let (b_owner) = owner_of_generation.read(gen_id - 1)
    let (c_owner) = owner_of_generation.read(gen_id - 2)

    return (gen_id, latest_red, a_owner, b_owner, c_owner,
        r0_id, r0_gen, r0_row, r0_col, r0_owner,
        r1_id, r1_gen, r1_row, r1_col, r1_owner,
        r2_id, r2_gen, r2_row, r2_col, r2_owner,
        r3_id, r3_gen, r3_row, r3_col, r3_owner,
        r4_id, r4_gen, r4_row, r4_col, r4_owner,
        r5_id, r5_gen, r5_row, r5_col, r5_owner,
        r6_id, r6_gen, r6_row, r6_col, r6_owner,
        r7_id, r7_gen, r7_row, r7_col, r7_owner,
        r8_id, r8_gen, r8_row, r8_col, r8_owner,
        r9_id, r9_gen, r9_row, r9_col, r9_owner,
        a0, a1, a2, a3, a4, a5, a6, a7, a8, a9,
        a10, a11, a12, a13, a14,
        b0, b1, b2, b3, b4, b5, b6, b7, b8, b9,
        b10, b11, b12, b13, b14,
        c0, c1, c2, c3, c4, c5, c6, c7, c8, c9,
        c10, c11, c12, c13, c14)
end

# Pass a list of generation ids to fetch multiple states.
@view
func get_arbitrary_state_arrays{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        gen_ids_array_len : felt,
        gen_ids_array : felt*,
        n_latest_states : felt,
        give_life_array_len : felt,
        give_life_array : felt*,
        n_latest_give_life : felt
    ) -> (
        current_generation_id : felt,
        gen_ids_array_result_len : felt,
        gen_ids_array_result : felt*,
        specific_state_owners_len : felt,
        specific_state_owners : felt*,
        n_latest_states_result_len : felt,
        n_latest_states_result : felt*,
        latest_state_owners_len : felt,
        latest_state_owners : felt*,
        latest_redemption_index : felt,
        give_life_array_result_len : felt,
        give_life_array_result : felt*,
        n_latest_give_life_result_len : felt,
        n_latest_give_life_result : felt*
    ):
    # Input:
    #   gen_ids_array -> Specific game states requested.
    #   n_latest_states -> n latest game states requested.
    #   give_life_array -> Specific give life actions requested.
    #   n_latest_give_life -> n latest give life actions requested.
    # Output descriptions:
    # A  current_generation_id -> ID of the latest state.
    # B  gen_ids_array_result -> specific game states.
    # C  specific_state_owners -> owners of specific game states.
    # D  n_latest_states_result -> latest game states.
    # E  latest_state_owners -> owners of latest game states.
    # F  latest_redemption_index -> index of the latest give life redemption.
    # G  give_life_array_result -> specific give live events.
    # H  n_latest_give_life_result -> latest give life events.

    # The give life data is: [redemption_index, id_minted, id_used, row, col, owner]
    alloc_locals

    # A Current generation
    let (local current_generation_id) = current_generation.read()

    # B Append rows for all the generations requested.
    let (local gen_ids_array_result : felt*) = alloc()
    append_states(gen_ids_array_len, gen_ids_array, gen_ids_array_result)
    local gen_ids_array_result_len = 15 * gen_ids_array_len

    # C Add owners for specific.
    let (local specific_state_owners : felt*) = alloc()
    local specific_state_owners_len = gen_ids_array_len
    append_owners(gen_ids_array_len, gen_ids_array, specific_state_owners)

    # D Append rows for the recent generations.
    let (local recent_gen_ids : felt*) = alloc()
    # Make a list of descending numbers.
    build_array(current_generation_id, n_latest_states, recent_gen_ids)
    let (local n_latest_states_result : felt*) = alloc()
    local n_latest_states_result_len = 15 * n_latest_states
    append_states(n_latest_states, recent_gen_ids, n_latest_states_result)

    # E Add owners for latest.
    local latest_state_owners_len = n_latest_states
    let (local latest_state_owners : felt*) = alloc()
    local latest_state_owners_len = n_latest_states
    append_owners(n_latest_states, recent_gen_ids, latest_state_owners)

    # F ID of the latest give life redemption.
    let (local latest_redemption_index) = highest_redemption_index_of_gen.read(
        current_generation_id)

    # G Specific give life events.
    let (local give_life_array_result : felt*) = alloc()
    # There are 6 fields per give life event.
    local give_life_array_result_len = give_life_array_len * 6
    append_redemptions(give_life_array_len, give_life_array,
        give_life_array_result)

    # H Latest give life events.
    let (local recent_red_indices : felt*) = alloc()
    # Make a list of descending numbers.
    build_array(latest_redemption_index, n_latest_give_life,
        recent_red_indices)
    let (local n_latest_give_life_result : felt*) = alloc()
    append_redemptions(n_latest_give_life, recent_red_indices,
        n_latest_give_life_result)
    # There are 6 fields per give life event.
    local n_latest_give_life_result_len = n_latest_give_life * 6

    return (
        current_generation_id,
        gen_ids_array_result_len,
        gen_ids_array_result,
        specific_state_owners_len,
        specific_state_owners,
        n_latest_states_result_len,
        n_latest_states_result,
        latest_state_owners_len,
        latest_state_owners,
        latest_redemption_index,
        give_life_array_result_len,
        give_life_array_result,
        n_latest_give_life_result_len,
        n_latest_give_life_result)
end

# @notice Returns the details of give life tokens for a given player.
# @param token_ids Array of token ids owned by the user.
# @param gave_life_at Array of generations where a token was redeemed (0=unused).
@view
func get_user_tokens{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user_id : felt
    ) -> (
        token_ids_len : felt,
        token_ids : felt*,
        gave_life_at_len : felt,
        gave_life_at : felt*,
    ):
    alloc_locals
    let (local count) = count_tokens_owned.read(user_id)
    let (local token_ids : felt*) = alloc()
    let (local gave_life_at : felt*) = alloc()

    append_token_data(user_id, count, token_ids, gave_life_at)
    return (
        count,
        token_ids,
        count,
        gave_life_at
    )
end

##### Private functions #####
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
    if n == 0:
        return ()
    end
    build_array(x, n-1, array)
    # n=1 upon first entry here.
    let index = n - 1
    assert array[index] = x - index
    return ()
end

# @notice For a known number of tokens owned by a user, returns a list of their ids.
# @dev Iterates recursively over n, using that as the users nth token.
# @param n Number of tokens the user owns.
# @param token_ids Empty array to populate with ids.
# @param gave_life_at Empty array to populate with when token was redeemed (unused=0).
func append_token_data{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user_id : felt,
        n : felt,
        token_ids : felt*,
        gave_life_at : felt*
    ):
    if n == 0:
        return ()
    end
    append_token_data(user_id, n - 1, token_ids, gave_life_at)
    # n=1 upon first entry here.
    let index = n - 1
    let (gen_id) = generation_of_owner.read(user_id, index)
    # Add id.
    assert token_ids[index] = gen_id
    # Add details about whether and when it has given life yet.
    let (redeemed_at) = token_redeemed_at.read(gen_id)
    assert gave_life_at[index] = redeemed_at
    return ()
end


# For a list of gen_ids, adds state to a state array (for a frontend).
func append_states{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        len : felt,
        gen_id_array : felt*,
        states : felt*
    ):
    # This helper function can be used to grab a large number of specific
    # states for a frontend to quickly get game data.
    if len == 0:
        return ()
    end
    # Loop with recursion.
    append_states(len - 1, gen_id_array, states)
    let index = len - 1
    # Get rows for the n-th requested generation.
    let (r0, r1, r2, r3, r4, r5, r6, r7, r8, r9,
        r10, r11, r12, r13, r14) = view_game(gen_id_array[index])
    # Append 32 new rows to the multi-state for every gen requested.
    assert states[index * 15 + 0] = r0
    assert states[index * 15 + 1] = r1
    assert states[index * 15 + 2] = r2
    assert states[index * 15 + 3] = r3
    assert states[index * 15 + 4] = r4
    assert states[index * 15 + 5] = r5
    assert states[index * 15 + 6] = r6
    assert states[index * 15 + 7] = r7
    assert states[index * 15 + 8] = r8
    assert states[index * 15 + 9] = r9
    assert states[index * 15 + 10] = r10
    assert states[index * 15 + 11] = r11
    assert states[index * 15 + 12] = r12
    assert states[index * 15 + 13] = r13
    assert states[index * 15 + 14] = r14

    return ()
end

# For an array of generation IDs, creates an array of their owners.
func append_owners{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        len : felt,
        gen_id_array : felt*,
        owners : felt*
    ):
    if len == 0:
        return ()
    end
    # Loop with recursion.
    append_owners(len - 1, gen_id_array, owners)
    # On first entry here, len=1.
    let index = len - 1
    let gen_id = gen_id_array[index]
    let (owner) = owner_of_generation.read(gen_id)
    assert owners[index] = owner
    return ()
end


# For an array of redemption indices, creates an array of their data.
func append_redemptions{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        len : felt,
        red_index_array : felt*,
        redemptions : felt*
    ):
    if len == 0:
        return ()
    end
    # Loop with recursion.
    append_redemptions(len - 1, red_index_array, redemptions)
    # On first entry here, len=1.
    let index = len - 1

    # Every redemption event has 6 fields
    let fields = 6  # index, id_minted, id_used, row, col, owner.


    let red_index = red_index_array[index]
    # Get the ID of the five life token (when it was created).
    let (gen_minted) = token_at_redemption_index.read(red_index)
    let (_, r_gen_used, r_row, r_col, r_owner) = get_token_data(gen_minted)
    assert redemptions[index * fields] = red_index
    assert redemptions[index * fields + 1] = gen_minted
    assert redemptions[index * fields + 2] = r_gen_used
    assert redemptions[index * fields + 3] = r_row
    assert redemptions[index * fields + 4] = r_col
    assert redemptions[index * fields + 5] = r_owner
    return ()
end



# Pre-sim. Walk rows then columns to build state.
func unpack_rows{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        gen_id : felt,
        cell_states : felt*,
        row : felt
    ):
    alloc_locals
    if row == 0:
        return ()
    end

    unpack_rows(gen_id=gen_id, cell_states=cell_states, row=row-1)
    # Get the binary encoded store.
    # (Note, on first entry, row=1 so row-1 gets the index)
    let (stored_row) = historical_row.read(gen_id, row-1)
    # New empty array to store the cell states for that row.
    let (local stored_row_unpacked : felt*) = alloc()
    split_int(
        value=stored_row,
        n=15,
        base=2,
        bound=2,
        output=stored_row_unpacked)
    # Pass the 32-long array to add to the cell_states array.
    append_cols(cell_states=cell_states,
        row=row-1, col=DIM, stored_row=stored_row_unpacked)

    return ()
end


# User input may override state to make a cell alive.
func activate_cell{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        row : felt,
        col : felt
    ):
    alloc_locals
    # Wrap around if chosen value out of range.
    let (_, local row) = unsigned_div_rem(row, DIM)
    let (_, col) = unsigned_div_rem(col, DIM)
    # 000...0000001000000 Selected bit (column) for this row.
    # 000...0100100001010 Stored.
    # 000...0100101001010 Selected OR Stored.
    #                 ^ index 2
    let binary_position = DIM - 1 - col
    let (local bit) = pow(2, binary_position)
    let (gen) = current_generation.read()
    let (local stored) = historical_row.read(gen, row)
    let (local updated) = bitwise_or(bit, stored)
    # Reject the transaction if the user is going to waste their time.
    assert_not_equal(stored, updated)
    historical_row.write(gen, row, updated)

    return ()
end

# Post-sim. Walk rows then columns to store state.
func pack_rows{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        new_gen_id : felt,
        cell_states : felt*,
        row : felt
    ):
    if row == 0:
        return ()
    end


    pack_rows(
        new_gen_id=new_gen_id,
        cell_states=cell_states,
        row=row-1)
    # (Note, on first entry, row=1 so row-1 gets the index)
    # Create the binary encoded state for the row.
    let (row_to_store) = pack_cols(cell_states=cell_states,
        row=row-1, col=DIM, row_to_store=0)

    # Permanently store the game state.
    historical_row.write(
        gen_id=new_gen_id,
        row_index=row-1,
        value=row_to_store)

    return ()
end
