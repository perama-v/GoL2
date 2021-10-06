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
        image : GoL
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

    let (image : GoL) = array_to_struct(cell_states_final)
    # Save the user data.
    let (user) = get_caller_address()
    user_of_generation.write(number_of_generations, user)
    generation_of_user.write(user, number_of_generations)
    return (image=image)
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
    assert image.row_28 = state[28]
    assert image.row_29 = state[29]
    assert image.row_30 = state[30]
    assert image.row_31 = state[31]

    return(image_struct=image)
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
