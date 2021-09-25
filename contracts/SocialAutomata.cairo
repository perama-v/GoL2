%lang starknet
%builtins pedersen range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bitwise import bitwise_and, bitwise_or
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.pow import pow
from starkware.starknet.common.storage import Storage


# Width of the simulation grid.
const DIM = 16

@storage_var
func spawned() -> (bool : felt):
end

# Stores n=dim rows of cell status as a binary representation.
@storage_var
func row_binary(
        row : felt
    ) -> (
        val : felt
    ):
end

# Sets the initial state.
@external
func spawn{
        storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (has_spawned) = spawned.read()
    if has_spawned == 1:
        return ()
    end
    # Start with an acorn near bottom right in a 16x16 grid.
    # https://www.conwaylife.com/patterns/acorn.cells
    row_binary.write(0, 0)
    row_binary.write(1, 0)
    row_binary.write(2, 0)
    row_binary.write(3, 0)
    row_binary.write(4, 0)
    row_binary.write(5, 0)
    row_binary.write(6, 0)
    row_binary.write(7, 0)
    row_binary.write(8, 0)
    row_binary.write(9, 0)
    row_binary.write(10, 0)
    row_binary.write(11, 0)
    row_binary.write(12, 32)
    row_binary.write(13, 8)
    row_binary.write(14, 103)
    row_binary.write(15, 0)
    spawned.write(1)
    return ()
end

@external
func run{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        rounds : felt,
        give_life_row_index : felt,
        give_life_column_index : felt
    ) -> (
        first_init : felt, # testing.
        last_init : felt,
        sample_new : felt
    ):
    alloc_locals
    # Unpack the stored game
    # Iterate over rows, then cols to get an array of all cells.
    let (local cell_states_init : felt*) = alloc()
    unpack_rows(cell_states=cell_states_init,row=DIM)
    local first_cell : felt = cell_states_init[0]
    local last_cell : felt = cell_states_init[DIM*DIM - 1]
    # Run the game for the specified rounds.
    let (local cell_states : felt*) = evaluate_rounds(
        rounds, cell_states_init)
    # Pack the game for storage.
    pack_rows(cell_states, row=DIM)

    activate_cell(give_life_row_index, give_life_column_index)
    return (first_cell, last_cell, cell_states[3])
end

@view
func view_game{
        storage_ptr : Storage*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (
        row_0 : felt, row_1 : felt, row_2 : felt, row_3 : felt,
        row_4 : felt, row_5 : felt, row_6 : felt, row_7 : felt,
        row_8 : felt, row_9 : felt, row_10 : felt, row_11 : felt,
        row_12 : felt, row_13 : felt, row_14 : felt, row_15 : felt
    ):
    let (row_0) = row_binary.read(0)
    let (row_1) = row_binary.read(1)
    let (row_2) = row_binary.read(2)
    let (row_3) = row_binary.read(3)
    let (row_4) = row_binary.read(4)
    let (row_5) = row_binary.read(5)
    let (row_6) = row_binary.read(6)
    let (row_7) = row_binary.read(7)
    let (row_8) = row_binary.read(8)
    let (row_9) = row_binary.read(9)
    let (row_10) = row_binary.read(10)
    let (row_11) = row_binary.read(11)
    let (row_12) = row_binary.read(12)
    let (row_13) = row_binary.read(13)
    let (row_14) = row_binary.read(14)
    let (row_15) = row_binary.read(15)
    return (row_0, row_1, row_2, row_3, row_4, row_5, row_6, row_7,
        row_8, row_9, row_10, row_11, row_12, row_13, row_14, row_15)
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


# User input may override state to make a cell alive.
func activate_cell{
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
    let binary_position = DIM - col
    let (local bit) = pow(2, binary_position)
    let (stored) = row_binary.read(row)
    let (updated) = bitwise_or(bit, stored)
    row_binary.write(row, updated)

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

    # col=0 goes in MSB. col=DIM goes in LSB.
    let binary_position = DIM - (col - 1)
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
        cell_states : felt*,
        row : felt
    ):
    if row == 0:
        return ()
    end

    pack_rows(cell_states=cell_states, row=row-1)
    # (Note, on first entry, row=1 so row-1 gets the index)
    # Create the binary encoded state for the row.
    let (row_to_store) = pack_cols(cell_states=cell_states,
        row=row-1, col=DIM, row_to_store=0)
    row_binary.write(row=row-1, value=row_to_store)

    return ()
end
