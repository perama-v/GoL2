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
    # Start with a 16x16 methuselah.
    # https://conwaylife.com/wiki/49768M
    row_binary.write(0, 32333)
    row_binary.write(1, 54472)
    row_binary.write(2, 1043)
    row_binary.write(3, 19359)
    row_binary.write(4, 53186)
    row_binary.write(5, 35818)
    row_binary.write(6, 55429)
    row_binary.write(7, 4183)
    row_binary.write(8, 64213)
    row_binary.write(9, 32877)
    row_binary.write(10, 18501)
    row_binary.write(11, 50706)
    row_binary.write(12, 45093)
    row_binary.write(13, 1293)
    row_binary.write(14, 60929)
    row_binary.write(15, 43246)
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
        alter_cell : felt
    ) -> (
        val0 : felt, # testing.
        val1 : felt,
        val2 : felt
    ):
    alloc_locals
    # Iterate over rows, then cols to get an array of all cells.
    let (cell_states : felt*) = alloc()
    let (cell_states : felt*) = unpack_rows(cell_states=cell_states,
        row=DIM)

    let (cell_states) = evaluate(rounds, cell_states)

    let (local cell_states) = apply_player_action(cell_states,
        alter_cell)

    pack_rows(cell_states, row=DIM)

    return (cell_states[0], cell_states[1], cell_states[2])
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
    ) -> (
        cell_states : felt*
    ):
    alloc_locals
    if col == 0:
        return (cell_states)
    end

    let (cell_states) = unpack_cols(cell_states=cell_states,
        row=row, col=col-1, stored_row=stored_row)

    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local storage_ptr : Storage* = storage_ptr
    local cell_states : felt* = cell_states
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    # state = 2**column_index AND row_binary
    let (mask) = pow(2, col)
    let (state) = bitwise_and(stored_row, mask)
    let index = row * DIM + col
    assert cell_states[index] = state

    return (cell_states)
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
    ) -> (
        cell_states: felt*
    ):
    if row == 0:
        return (cell_states)
    end

    let (cell_states) = unpack_rows(cell_states=cell_states,
        row=row-1)
    # Get the binary encoded store.
    let (stored_row) = row_binary.read(row=row)
    let (cell_states) = unpack_cols(cell_states=cell_states,
        row=row, col=DIM, stored_row=stored_row)

    return (cell_states)
end

# Executes rounds and returns an array with final state.
func evaluate{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        rounds : felt,
        cell_states : felt*,
    ) -> (
        cell_states : felt*
    ):
    if rounds == 0:
        return(cell_states)
    end
    let (cell_states) = evaluate(rounds=rounds-1,
        cell_states=cell_states)

    # Build pending.
    let (pending_states : felt*) = alloc()
    let (pending_states) = apply_rules(cell=DIM*DIM,
        cell_states=cell_states, pending_states=pending_states)

    # Return the pending state as canonical.
    return (pending_states)
end

func apply_rules{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        cell : felt,
        cell_states : felt*,
        pending_states : felt*
    ) -> (
        pending_states : felt*
    ):
    alloc_locals
    if cell == 0:
        return(pending_states)
    end

    let (local pending_states) = apply_rules(cell=cell-1,
        cell_states=cell_states, pending_states=pending_states)

    local storage_ptr : Storage* = storage_ptr
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr


    let (row, col) = unsigned_div_rem(cell, DIM)
    let len = DIM * DIM
    # Wrap around: Index neihbours using modulo array length.
    let (_, L) = unsigned_div_rem(cell - 1 + len, len)
    let (_, R) = unsigned_div_rem(cell + 1, len)
    let (_, D) = unsigned_div_rem(cell + DIM, len)
    let (_, U) = unsigned_div_rem(cell - DIM + len, len)
    let (_, LU) = unsigned_div_rem(U - 1 + len, len)
    let (_, RU) = unsigned_div_rem(U + 1, len)
    let (_, LD) = unsigned_div_rem(D - 1 + len, len)
    let (_, RD) = unsigned_div_rem(D + 1, len)

    local range_check_ptr = range_check_ptr
    # Sum of 8 surrounding cells.
    let score = cell_states[L] + cell_states[R] +
        cell_states[D] + cell_states[U] +
        cell_states[LU] + cell_states[RU] +
        cell_states[LD] + cell_states[RD]

    # 1 if True.
    let alive = cell_states[cell] ###
    let thrive = 1 - (score - 2) * (score - 3)
    let revive = 1 - score - 3

    # Final outcome
    let pending_states : felt* = pending_states
    assert pending_states[cell] = 0


    if alive + thrive == 2:
        assert pending_states[cell] = 1
    else:
        if revive == 1:
            assert pending_states[cell] = 1
        end
    end

    return (pending_states)
end

# User input may override state to make a cell alive.
func apply_player_action{
        storage_ptr : Storage*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        cell_states : felt*,
        alter_cell : felt
    ) -> (
        cell_states : felt*
    ):
    # Wrap around if need.
    let (_, alter_cell) = unsigned_div_rem(alter_cell, DIM*DIM)
    assert cell_states[alter_cell] = 1
    return (cell_states)
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

    let (row_to_store) = pack_cols(cell_states=cell_states,
        row=row, col=col-1, row_to_store=row_to_store)


    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local storage_ptr : Storage* = storage_ptr
    local cell_states : felt* = cell_states
    local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr

    let index = row * DIM + col
    let state = cell_states[index]
    # store = 2**column_index OR row_binary
    let (mask) = pow(2, col)
    let (row_to_store) = bitwise_or(state, mask)

    return (row_to_store)
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

    # Create the binary encoded state for the row.
    let (row_to_store) = pack_cols(cell_states=cell_states,
        row=row, col=DIM, row_to_store=0)
    row_binary.write(row=row, value=row_to_store)

    return ()
end
