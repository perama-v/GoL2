from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import unsigned_div_rem
from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.starknet.common.storage import Storage

const DIM = 32


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

