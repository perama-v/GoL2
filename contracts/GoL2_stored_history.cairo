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

## This is a high-storage implementation that does not require
## Events or a token contract.

##### Constants #####
# Width of the simulation grid.
const DIM = 32

# Maximum number of steps a single turn can evolve the game by.
const max_steps = 5

##### Storage #####
# Returns whether the game has started (bool=1) or not (bool=0).
@storage_var
func spawned() -> (bool : felt):
end

# Returns the gen_id of the current alive generation.
@storage_var
func current_generation() -> (gen_id : felt):
end

# Stores how many tokens have been redeemed for a give_life act.
@storage_var
func redemption_count() -> (count : felt):
end

# Mapping to enable walking along the game states while the gen_id
# may skip forward an arbitrary number of steps.
@storage_var
func generation_at_index(gen_index) -> (gen_id : felt):
end

# Mapping to enable walking along the game states while the gen_id
# may skip forward an arbitrary number of steps.
@storage_var
func index_at_generation(gen_id) -> (gen_index : felt):
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

# Temporary function to expose generation ownership to frontend.
# Is a stored list of ID's indexed from zero for every user.
@storage_var
func generation_of_owner(
        user_id : felt,
        nth_personal_token : felt
    ) -> (
        gen_id : felt
    ):
end

# Temporary function (pending Token) to help frontend track ownership.
@storage_var
func count_tokens_owned(user_id : felt) -> (tokens_owned : felt):
end

# Temporary function (pending Token) to help frontend track give_life.
@storage_var
func token_redeemed_at(token_id : felt) -> (gen_id_at_redemption : felt):
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

# Temporary function (pending Events) to keep track of give_life.
# Cell is (row, col) by index.
@storage_var
func token_gave_life(
        gen_id_of_token : felt,
    ) -> (
        cell : (felt, felt)
    ):
end

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
    historical_row.write(1, 12, 32)
    historical_row.write(1, 13, 8)
    historical_row.write(1, 14, 103)
    # Set the current generation as '1'.
    current_generation.write(1)
    # Prevent entry to this function again.
    spawned.write(1)
    # Generation index=0 will be saved as the first gen (gen_id=1).
    # The second turn will have index 1, but may have gen_id=5 (or n).
    generation_at_index.write(0, 1)
    index_at_generation.write(1, 0)
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
        user_id_admintemp : felt,
        number_of_generations : felt
    ):
    alloc_locals
    let (local last_gen) = current_generation.read()
    # Set limit on generations per turn: (0, max_steps].
    assert_not_zero(number_of_generations)
    assert_nn_le(number_of_generations, max_steps)
    local generations = number_of_generations
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
    #let (user) = get_caller_address()
    # For testing, skip account contract use. TODO add accounts.
    let user = user_id_admintemp

    let (prev_tokens) = count_tokens_owned.read(user)
    count_tokens_owned.write(user, prev_tokens + 1)
    # Store the token_id as a zero-based index of the uesrs token.
    generation_of_owner.write(user, prev_tokens, new_gen)
    owner_of_generation.write(new_gen, user)

    # Index the current generation for easy fetching.
    let (current_index) = index_at_generation.read(current_generation)
    generation_at_index.write(current_index + 1, new_gen)
    index_at_generation.write(new_gen, current_index + 1)

    return ()
end

# Give life to a specific cell.
@external
func give_life_to_cell{
        syscall_ptr : felt*,
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        user_id_admintemp : felt,
        cell_row_index : felt,
        cell_column_index : felt,
        gen_id_of_token_to_redeem : felt
    ):
    # This does not trigger an evolution. Multiple give_life
    # operations may be called, building up a shape before
    # a turn triggers evolution.
    alloc_locals

    # Only the caller can redeem
    # let (user) = get_caller_address()
    # For testing, skip account contract use. TODO add accounts.
    let user = user_id_admintemp

    let (owner) = owner_of_generation.read(gen_id_of_token_to_redeem)
    # Enable this check when accounts are used.
    assert owner = user

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

    return ()
end


# Returns a the current generation id and generation index.
# The index is based on turns while the id is evolution steps.
@view
func current_index_and_id{
        storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
    ) -> (
        gen_index : felt,
        gen_id : felt
    ):
    let (gen_id) = current_generation.read()
    let (gen_index) = index_at_generation.read(gen_id)
    return (gen_index, gen_id)
end


# Returns a the generation index for a given gen id.
# The index is based on turns while the id is evolution steps.
@view
func generation_index_from_id{
        storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        gen_id : felt
    ) -> (
        gen_index : felt
    ):
    let (gen_index) = index_at_generation.read(gen_id)
    return (gen_index)
end


# Returns a the generation id for a given turn index.
# The index is based on turns while the id is evolution steps.
@view
func generation_id_from_index{
        storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        gen_index : felt
    ) -> (
        gen_id : felt
    ):
    let (gen_id) = generation_at_index.read(gen_index)
    return (gen_id)
end

# Get the incrementing index of every give life action.
@view
func latest_give_life_index{
        storage_ptr : Storage*,
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
        storage_ptr : Storage*,
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
        storage_ptr : Storage*,
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


# Returns a list of rows for the specified generation.
@view
func view_game{
        storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        id_of_generation_to_view : felt
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
    let (row_15) = historical_row.read(gen_id, 15)
    let (row_16) = historical_row.read(gen_id, 16)
    let (row_17) = historical_row.read(gen_id, 17)
    let (row_18) = historical_row.read(gen_id, 18)
    let (row_19) = historical_row.read(gen_id, 19)
    let (row_20) = historical_row.read(gen_id, 20)
    let (row_21) = historical_row.read(gen_id, 21)
    let (row_22) = historical_row.read(gen_id, 22)
    let (row_23) = historical_row.read(gen_id, 23)
    let (row_24) = historical_row.read(gen_id, 24)
    let (row_25) = historical_row.read(gen_id, 25)
    let (row_26) = historical_row.read(gen_id, 26)
    let (row_27) = historical_row.read(gen_id, 27)
    let (row_28) = historical_row.read(gen_id, 28)
    let (row_29) = historical_row.read(gen_id, 29)
    let (row_30) = historical_row.read(gen_id, 30)
    let (row_31) = historical_row.read(gen_id, 31)

    return (row_0, row_1, row_2, row_3, row_4, row_5,
        row_6, row_7, row_8, row_9, row_10, row_11,
        row_12, row_13, row_14, row_15, row_16, row_17,
        row_18, row_19, row_20, row_21, row_22, row_23,
        row_24, row_25, row_26, row_27, row_28, row_29,
        row_30, row_31)
end


# First call this function to see how many tokens a user has.
@view
func user_token_count{
        storage_ptr : Storage*,
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
        storage_ptr : Storage*,
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
        storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        token_id : felt
    ) -> (
        has_used_give_life : felt,
        generation_during_give_life : felt,
        alive_cell_row : felt,
        alive_cell_col : felt
    ):
    alloc_locals
    let (redeemed) = token_redeemed_at.read(token_id)
    let (alive_cell) = token_gave_life.read(token_id)

    local has_used_give_life
    local alive_cell_row
    local alive_cell_col
    if redeemed == 0:
        assert has_used_give_life = 0
    else:
        assert has_used_give_life = 1
        assert alive_cell_row = alive_cell[0]
        assert alive_cell_col = alive_cell[1]
    end

    return (
        has_used_give_life=has_used_give_life,
        generation_during_give_life=redeemed,
        alive_cell_row=alive_cell_row,
        alive_cell_col=alive_cell_col
    )
end

##### Private functions #####
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

# Pre-sim. Walk rows then columns to build state.
func unpack_rows{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        gen_id : felt,
        cell_states : felt*,
        row : felt
    ):
    if row == 0:
        return ()
    end

    unpack_rows(gen_id=gen_id, cell_states=cell_states, row=row-1)
    # Get the binary encoded store.
    # (Note, on first entry, row=1 so row-1 gets the index)
    let (stored_row) = historical_row.read(gen_id, row-1)
    unpack_cols(cell_states=cell_states,
        row=row-1, col=DIM, stored_row=stored_row)

    return ()
end

# Executes rounds and returns an array with final state.
func evaluate_rounds{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        rounds : felt,
        cell_states : felt*
    ) -> (
        cell_states : felt*
    ):
    alloc_locals
    if rounds == 0:
        return(cell_states=cell_states)
    end

    let (cell_states) = evaluate_rounds(rounds=rounds-1, cell_states=cell_states)

    let (local pending_states : felt*) = alloc()
    # Fill up pending_states based on cell_states and GoL rules
    apply_rules(cell=DIM*DIM, cell_states=cell_states,
        pending_states=pending_states)

    # Return the pending states as canonical.
    return (cell_states=pending_states)
end

# Steps through every cell, checking neighbour states.
func apply_rules{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        cell : felt,
        cell_states : felt*,
        pending_states : felt*
    ):
    alloc_locals
    if cell == 0:
        return ()
    end

    apply_rules(cell=cell-1, cell_states=cell_states,
        pending_states=pending_states)

    # (Note, on first entry, cell=1 so cell-1 gets the index).
    local cell_idx = cell - 1

    local storage_ptr : Storage* = storage_ptr
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr

    # Get indices of neighbours.
    let (L, R, U, D, LU, RU, LD, RD) = get_adjacent(cell_idx)

    local range_check_ptr = range_check_ptr
    # Sum of 8 surrounding cells.
    let score = cell_states[L] + cell_states[R] +
        cell_states[D] + cell_states[U] +
        cell_states[LU] + cell_states[RU] +
        cell_states[LD] + cell_states[RD]

    # Final outcome
    # If alive
    if cell_states[cell_idx] == 1:
        # With good neighbours
        if (score - 2) * (score - 3) == 0:
            # Live
            assert pending_states[cell_idx] = 1
        else:
            assert pending_states[cell_idx] = 0
        end
    else:
        if score == 3:
            assert pending_states[cell_idx] = 1
        else:
            assert pending_states[cell_idx] = 0
        end

    end

    return ()
end

@external
func get_adjacent{
        range_check_ptr
    }(
        cell_idx : felt
    ) -> (
        L : felt,
        R : felt,
        U : felt,
        D : felt,
        LU : felt,
        RU : felt,
        LD : felt,
        RD : felt
    ):
    # cell_states and pending_states structure:
    #         Row 0               Row 1              Row 2
    #  <-------DIM-------> <-------DIM-------> <-------DIM------->
    # [0,0,0,0,1,...,1,0,1,0,1,1,0,...,1,0,0,1,1,1,0,1...,0,0,1,0...]
    #  ^col_0     col_DIM^ ^col_0     col_DIM^ ^col_0
    let (row, col) = unsigned_div_rem(cell_idx, DIM)
    let len = DIM * DIM
    let row_start = row * DIM
    # LU U RU
    # L  .  R
    # LD D RD
    # Wrap around: Index neighbours using modulo.

    # For a neighbour moving left and wrapping around:
    # 1. Move left by one (cell_idx - 1).
    # 2. Move to range [0, DIM] (- row_start).
    # 3. Add DIM to make positive (+ DIM).
    # 4. Take modulo DIM to keep in range [0, DIM] (% DIM).
    # 5. Add row for index of wrapped neighbour (+ row_start).
    let (_, L) = unsigned_div_rem(cell_idx - 1 - row_start + DIM,
        DIM)
    let L = L + row_start

    # Moving right and wrapping around from the left:
    # 1. Move right by one (cell_idx + 1).
    # 2. Move to range [0, DIM] (- row_start).
    # 3. Take modulo DIM to keep in range [0, DIM] (% DIM).
    # 4. Add row for index of wrapped neighbour (+ row_start).
    let (_, R) = unsigned_div_rem(cell_idx + 1 - row_start, DIM)
    let R = R + row_start

    # Moving down and wrapping down from the top:
    # 1. Move down by one (cell_idx + DIM).
    # 2. If beyond len, wrap (% len).
    let (_, D) = unsigned_div_rem(cell_idx + DIM, len)

    # Moving up and wrapping up from bottom:
    # 1. Move up by one (cell_idx - DIM).
    # 2. Add len to make positive if above grid (+ len).
    # 3. Modulo len (% len).
    let (_, U) = unsigned_div_rem(cell_idx - DIM + len, len)

    # First take L or R position and then apply U or D operation.
    let (_, LU) = unsigned_div_rem(L - DIM + len, len)
    let (_, RU) = unsigned_div_rem(R - DIM + len, len)
    let (_, LD) = unsigned_div_rem(L + DIM, len)
    let (_, RD) = unsigned_div_rem(R + DIM, len)

    return (L=L, R=R, U=U, D=D, LU=LU, RU=RU, LD=LD,
        RD=RD)
end


# User input may override state to make a cell alive.
func activate_cell{
        syscall_ptr : felt*,
        storage_ptr : Storage*,
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
    let (stored) = historical_row.read(gen, row)
    let (updated) = bitwise_or(bit, stored)
    historical_row.write(gen, row, updated)

    return ()
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

# Post-sim. Walk rows then columns to store state.
func pack_rows{
        storage_ptr : Storage*,
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
