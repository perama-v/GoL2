from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.pow import pow
from starkware.cairo.common.bitwise import bitwise_or, bitwise_and
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.math import split_int

const DIM = 32
# Post-sim. Walk rows then columns to store state.
func pack_rows{
        syscall_ptr : felt*,
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



# Post-sim. Walk columns for a given row and saves array to state.
func pack_cols{
        syscall_ptr : felt*,
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
    # Don't need bitwise_or here
    #let (new_row) = bitwise_or(cell_binary, row_to_store)
    let new_row = cell_binary + row_to_store

    return (new_row)
end


# Pre-sim. Walk columns for a given row and saves state to an array.
func append_cols{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        cell_states : felt*,
        row : felt,
        col : felt,
        stored_row : felt*
    ):
    alloc_locals
    if col == 0:
        return ()
    end

    append_cols(cell_states=cell_states,
        row=row, col=col-1, stored_row=stored_row)
    # (Note, on first entry, col=1 so col-1 gets the index)
    #local pedersen_ptr : HashBuiltin* = pedersen_ptr
    #local cell_states : felt* = cell_states
    #local bitwise_ptr : BitwiseBuiltin* = bitwise_ptr
    # state = 2**column_index AND row_binary
    # Column zero is the MSB, so (DIM_index - col_index) accesses the bit.
    let binary_position = (DIM - 1) - (col - 1)
    # let (mask) = pow(2, binary_position)
    # Avoid bitwise builtin use ecause it has a global cap ~1024.
    # let (state) = bitwise_and(stored_row, mask)
    let state = stored_row[binary_position]
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

# Performs bitwise_and functionality without using bitwise builtin.
func custom_bitwise_and{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        packed_value : felt,
        binary_position : felt
    ) -> (
        res : felt
    ):
    alloc_locals
    let (local result_array : felt*) = alloc()
    # Only read up to 32 values.
    split_int(value=packed_value, n=32, base=2, bound=2, output=result_array)
    let res = result_array[binary_position]
    return (res)
end
