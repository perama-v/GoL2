%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)

from contracts.infinite import (evolve_and_claim_next_generation,
    give_life_to_cell, current_generation_id, user_credits_count,
    get_owner_of_generation, get_revival_history, view_game)

@external
func test_evolve_and_claim_next_generation{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    local user_id = 123
    %{
        expect_events({"name": "game_evolved", "data": [ids.user_id, 2]})
        expect_events({"name": "credit_earned", "data": [ids.user_id, 1]})
    %}

    %{ stop_prank_callable = start_prank(ids.user_id) %}
    evolve_and_claim_next_generation()
    %{ stop_prank_callable() %}

    let (generation) = current_generation_id()
    assert generation = 2

    let (credit) = user_credits_count(user_id)
    assert credit = 1

    let (gen_owner) = get_owner_of_generation(generation)
    assert gen_owner = user_id

    let (progressed_game_len, progressed_game) = view_game(generation=generation)
    assert progressed_game_len = 225
    assert progressed_game[0] = 0
    assert progressed_game[1] = 0
    assert progressed_game[2] = 0
    assert progressed_game[3] = 0
    assert progressed_game[4] = 0
    assert progressed_game[5] = 0
    assert progressed_game[6] = 0
    assert progressed_game[7] = 0
    assert progressed_game[8] = 0
    assert progressed_game[9] = 0
    assert progressed_game[10] = 0
    assert progressed_game[11] = 0
    assert progressed_game[12] = 0
    assert progressed_game[13] = 0
    assert progressed_game[14] = 0
    assert progressed_game[15] = 0
    assert progressed_game[16] = 0
    assert progressed_game[17] = 0
    assert progressed_game[18] = 0
    assert progressed_game[19] = 0
    assert progressed_game[20] = 0
    assert progressed_game[21] = 0
    assert progressed_game[22] = 0
    assert progressed_game[23] = 0
    assert progressed_game[24] = 0
    assert progressed_game[25] = 0
    assert progressed_game[26] = 0
    assert progressed_game[27] = 0
    assert progressed_game[28] = 0
    assert progressed_game[29] = 0
    assert progressed_game[30] = 0
    assert progressed_game[31] = 0
    assert progressed_game[32] = 0
    assert progressed_game[33] = 0
    assert progressed_game[34] = 0
    assert progressed_game[35] = 0
    assert progressed_game[36] = 0
    assert progressed_game[37] = 0
    assert progressed_game[38] = 0
    assert progressed_game[39] = 0
    assert progressed_game[40] = 0
    assert progressed_game[41] = 0
    assert progressed_game[42] = 0
    assert progressed_game[43] = 0
    assert progressed_game[44] = 0
    assert progressed_game[45] = 0
    assert progressed_game[46] = 0
    assert progressed_game[47] = 0
    assert progressed_game[48] = 0
    assert progressed_game[49] = 0
    assert progressed_game[50] = 0
    assert progressed_game[51] = 0
    assert progressed_game[52] = 0
    assert progressed_game[53] = 0
    assert progressed_game[54] = 0
    assert progressed_game[55] = 0
    assert progressed_game[56] = 0
    assert progressed_game[57] = 0
    assert progressed_game[58] = 0
    assert progressed_game[59] = 0
    assert progressed_game[60] = 0
    assert progressed_game[61] = 0
    assert progressed_game[62] = 0
    assert progressed_game[63] = 0
    assert progressed_game[64] = 0
    assert progressed_game[65] = 0
    assert progressed_game[66] = 0
    assert progressed_game[67] = 0
    assert progressed_game[68] = 0
    assert progressed_game[69] = 0
    assert progressed_game[70] = 0
    assert progressed_game[71] = 0
    assert progressed_game[72] = 0
    assert progressed_game[73] = 0
    assert progressed_game[74] = 0
    assert progressed_game[75] = 0
    assert progressed_game[76] = 0
    assert progressed_game[77] = 0
    assert progressed_game[78] = 0
    assert progressed_game[79] = 0
    assert progressed_game[80] = 0
    assert progressed_game[81] = 0
    assert progressed_game[82] = 0
    assert progressed_game[83] = 0
    assert progressed_game[84] = 0
    assert progressed_game[85] = 0
    assert progressed_game[86] = 0
    assert progressed_game[87] = 0
    assert progressed_game[88] = 0
    assert progressed_game[89] = 0
    assert progressed_game[90] = 0
    assert progressed_game[91] = 0
    assert progressed_game[92] = 0
    assert progressed_game[93] = 0
    assert progressed_game[94] = 0
    assert progressed_game[95] = 0
    assert progressed_game[96] = 0
    assert progressed_game[97] = 0
    assert progressed_game[98] = 0
    assert progressed_game[99] = 0
    assert progressed_game[100] = 0
    assert progressed_game[101] = 0
    assert progressed_game[102] = 0
    assert progressed_game[103] = 0
    assert progressed_game[104] = 0
    assert progressed_game[105] = 0
    assert progressed_game[106] = 0
    assert progressed_game[107] = 0
    assert progressed_game[108] = 0
    assert progressed_game[109] = 0
    assert progressed_game[110] = 0
    assert progressed_game[111] = 0
    assert progressed_game[112] = 0
    assert progressed_game[113] = 1
    assert progressed_game[114] = 1
    assert progressed_game[115] = 1
    assert progressed_game[116] = 0
    assert progressed_game[117] = 1
    assert progressed_game[118] = 1
    assert progressed_game[119] = 0
    assert progressed_game[120] = 0
    assert progressed_game[121] = 0
    assert progressed_game[122] = 0
    assert progressed_game[123] = 0
    assert progressed_game[124] = 0
    assert progressed_game[125] = 0
    assert progressed_game[126] = 0
    assert progressed_game[127] = 0
    assert progressed_game[128] = 0
    assert progressed_game[129] = 0
    assert progressed_game[130] = 0
    assert progressed_game[131] = 0
    assert progressed_game[132] = 1
    assert progressed_game[133] = 1
    assert progressed_game[134] = 0
    assert progressed_game[135] = 0
    assert progressed_game[136] = 0
    assert progressed_game[137] = 0
    assert progressed_game[138] = 0
    assert progressed_game[139] = 0
    assert progressed_game[140] = 0
    assert progressed_game[141] = 0
    assert progressed_game[142] = 0
    assert progressed_game[143] = 0
    assert progressed_game[144] = 0
    assert progressed_game[145] = 0
    assert progressed_game[146] = 0
    assert progressed_game[147] = 0
    assert progressed_game[148] = 1
    assert progressed_game[149] = 0
    assert progressed_game[150] = 0
    assert progressed_game[151] = 0
    assert progressed_game[152] = 0
    assert progressed_game[153] = 0
    assert progressed_game[154] = 0
    assert progressed_game[155] = 0
    assert progressed_game[156] = 0
    assert progressed_game[157] = 0
    assert progressed_game[158] = 0
    assert progressed_game[159] = 0
    assert progressed_game[160] = 0
    assert progressed_game[161] = 0
    assert progressed_game[162] = 0
    assert progressed_game[163] = 0
    assert progressed_game[164] = 0
    assert progressed_game[165] = 0
    assert progressed_game[166] = 0
    assert progressed_game[167] = 0
    assert progressed_game[168] = 0
    assert progressed_game[169] = 0
    assert progressed_game[170] = 0
    assert progressed_game[171] = 0
    assert progressed_game[172] = 0
    assert progressed_game[173] = 0
    assert progressed_game[174] = 0
    assert progressed_game[175] = 0
    assert progressed_game[176] = 0
    assert progressed_game[177] = 0
    assert progressed_game[178] = 0
    assert progressed_game[179] = 0
    assert progressed_game[180] = 0
    assert progressed_game[181] = 0
    assert progressed_game[182] = 0
    assert progressed_game[183] = 0
    assert progressed_game[184] = 0
    assert progressed_game[185] = 0
    assert progressed_game[186] = 0
    assert progressed_game[187] = 0
    assert progressed_game[188] = 0
    assert progressed_game[189] = 0
    assert progressed_game[190] = 0
    assert progressed_game[191] = 0
    assert progressed_game[192] = 0
    assert progressed_game[193] = 0
    assert progressed_game[194] = 0
    assert progressed_game[195] = 0
    assert progressed_game[196] = 0
    assert progressed_game[197] = 0
    assert progressed_game[198] = 0
    assert progressed_game[199] = 0
    assert progressed_game[200] = 0
    assert progressed_game[201] = 0
    assert progressed_game[202] = 0
    assert progressed_game[203] = 0
    assert progressed_game[204] = 0
    assert progressed_game[205] = 0
    assert progressed_game[206] = 0
    assert progressed_game[207] = 0
    assert progressed_game[208] = 0
    assert progressed_game[209] = 0
    assert progressed_game[210] = 0
    assert progressed_game[211] = 0
    assert progressed_game[212] = 0
    assert progressed_game[213] = 0
    assert progressed_game[214] = 0
    assert progressed_game[215] = 0
    assert progressed_game[216] = 0
    assert progressed_game[217] = 0
    assert progressed_game[218] = 0
    assert progressed_game[219] = 0
    assert progressed_game[220] = 0
    assert progressed_game[221] = 0
    assert progressed_game[222] = 0
    assert progressed_game[223] = 0
    assert progressed_game[224] = 0

    return ()
end

@external
func test_give_life_to_cell_happy_case{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    local user_id = 123
    local cell_index = 0
    %{
        expect_events({"name": "cell_revived", "data": [ids.user_id, 2, ids.cell_index]})
        expect_events({"name": "credit_reduced", "data": [ids.user_id, 0]})
    %}

    %{ stop_prank_callable = start_prank(ids.user_id) %}
    # get credit by progressing game
    evolve_and_claim_next_generation()
    give_life_to_cell(cell_index)
    %{ stop_prank_callable() %}

    let (generation) = current_generation_id()
    assert generation = 2

    let (credit) = user_credits_count(user_id)
    assert credit = 0

    let (revived_cell_index, revived_generation) = get_revival_history(user_id)
    assert revived_cell_index = cell_index
    assert revived_generation = generation

    let (revived_game_len, revived_game) = view_game(generation=generation)
    assert revived_game_len = 225
    assert revived_game[0] = 1
    assert revived_game[1] = 0
    assert revived_game[2] = 0
    assert revived_game[3] = 0
    assert revived_game[4] = 0
    assert revived_game[5] = 0
    assert revived_game[6] = 0
    assert revived_game[7] = 0
    assert revived_game[8] = 0
    assert revived_game[9] = 0
    assert revived_game[10] = 0
    assert revived_game[11] = 0
    assert revived_game[12] = 0
    assert revived_game[13] = 0
    assert revived_game[14] = 0
    assert revived_game[15] = 0
    assert revived_game[16] = 0
    assert revived_game[17] = 0
    assert revived_game[18] = 0
    assert revived_game[19] = 0
    assert revived_game[20] = 0
    assert revived_game[21] = 0
    assert revived_game[22] = 0
    assert revived_game[23] = 0
    assert revived_game[24] = 0
    assert revived_game[25] = 0
    assert revived_game[26] = 0
    assert revived_game[27] = 0
    assert revived_game[28] = 0
    assert revived_game[29] = 0
    assert revived_game[30] = 0
    assert revived_game[31] = 0
    assert revived_game[32] = 0
    assert revived_game[33] = 0
    assert revived_game[34] = 0
    assert revived_game[35] = 0
    assert revived_game[36] = 0
    assert revived_game[37] = 0
    assert revived_game[38] = 0
    assert revived_game[39] = 0
    assert revived_game[40] = 0
    assert revived_game[41] = 0
    assert revived_game[42] = 0
    assert revived_game[43] = 0
    assert revived_game[44] = 0
    assert revived_game[45] = 0
    assert revived_game[46] = 0
    assert revived_game[47] = 0
    assert revived_game[48] = 0
    assert revived_game[49] = 0
    assert revived_game[50] = 0
    assert revived_game[51] = 0
    assert revived_game[52] = 0
    assert revived_game[53] = 0
    assert revived_game[54] = 0
    assert revived_game[55] = 0
    assert revived_game[56] = 0
    assert revived_game[57] = 0
    assert revived_game[58] = 0
    assert revived_game[59] = 0
    assert revived_game[60] = 0
    assert revived_game[61] = 0
    assert revived_game[62] = 0
    assert revived_game[63] = 0
    assert revived_game[64] = 0
    assert revived_game[65] = 0
    assert revived_game[66] = 0
    assert revived_game[67] = 0
    assert revived_game[68] = 0
    assert revived_game[69] = 0
    assert revived_game[70] = 0
    assert revived_game[71] = 0
    assert revived_game[72] = 0
    assert revived_game[73] = 0
    assert revived_game[74] = 0
    assert revived_game[75] = 0
    assert revived_game[76] = 0
    assert revived_game[77] = 0
    assert revived_game[78] = 0
    assert revived_game[79] = 0
    assert revived_game[80] = 0
    assert revived_game[81] = 0
    assert revived_game[82] = 0
    assert revived_game[83] = 0
    assert revived_game[84] = 0
    assert revived_game[85] = 0
    assert revived_game[86] = 0
    assert revived_game[87] = 0
    assert revived_game[88] = 0
    assert revived_game[89] = 0
    assert revived_game[90] = 0
    assert revived_game[91] = 0
    assert revived_game[92] = 0
    assert revived_game[93] = 0
    assert revived_game[94] = 0
    assert revived_game[95] = 0
    assert revived_game[96] = 0
    assert revived_game[97] = 0
    assert revived_game[98] = 0
    assert revived_game[99] = 0
    assert revived_game[100] = 0
    assert revived_game[101] = 0
    assert revived_game[102] = 0
    assert revived_game[103] = 0
    assert revived_game[104] = 0
    assert revived_game[105] = 0
    assert revived_game[106] = 0
    assert revived_game[107] = 0
    assert revived_game[108] = 0
    assert revived_game[109] = 0
    assert revived_game[110] = 0
    assert revived_game[111] = 0
    assert revived_game[112] = 0
    assert revived_game[113] = 1
    assert revived_game[114] = 1
    assert revived_game[115] = 1
    assert revived_game[116] = 0
    assert revived_game[117] = 1
    assert revived_game[118] = 1
    assert revived_game[119] = 0
    assert revived_game[120] = 0
    assert revived_game[121] = 0
    assert revived_game[122] = 0
    assert revived_game[123] = 0
    assert revived_game[124] = 0
    assert revived_game[125] = 0
    assert revived_game[126] = 0
    assert revived_game[127] = 0
    assert revived_game[128] = 0
    assert revived_game[129] = 0
    assert revived_game[130] = 0
    assert revived_game[131] = 0
    assert revived_game[132] = 1
    assert revived_game[133] = 1
    assert revived_game[134] = 0
    assert revived_game[135] = 0
    assert revived_game[136] = 0
    assert revived_game[137] = 0
    assert revived_game[138] = 0
    assert revived_game[139] = 0
    assert revived_game[140] = 0
    assert revived_game[141] = 0
    assert revived_game[142] = 0
    assert revived_game[143] = 0
    assert revived_game[144] = 0
    assert revived_game[145] = 0
    assert revived_game[146] = 0
    assert revived_game[147] = 0
    assert revived_game[148] = 1
    assert revived_game[149] = 0
    assert revived_game[150] = 0
    assert revived_game[151] = 0
    assert revived_game[152] = 0
    assert revived_game[153] = 0
    assert revived_game[154] = 0
    assert revived_game[155] = 0
    assert revived_game[156] = 0
    assert revived_game[157] = 0
    assert revived_game[158] = 0
    assert revived_game[159] = 0
    assert revived_game[160] = 0
    assert revived_game[161] = 0
    assert revived_game[162] = 0
    assert revived_game[163] = 0
    assert revived_game[164] = 0
    assert revived_game[165] = 0
    assert revived_game[166] = 0
    assert revived_game[167] = 0
    assert revived_game[168] = 0
    assert revived_game[169] = 0
    assert revived_game[170] = 0
    assert revived_game[171] = 0
    assert revived_game[172] = 0
    assert revived_game[173] = 0
    assert revived_game[174] = 0
    assert revived_game[175] = 0
    assert revived_game[176] = 0
    assert revived_game[177] = 0
    assert revived_game[178] = 0
    assert revived_game[179] = 0
    assert revived_game[180] = 0
    assert revived_game[181] = 0
    assert revived_game[182] = 0
    assert revived_game[183] = 0
    assert revived_game[184] = 0
    assert revived_game[185] = 0
    assert revived_game[186] = 0
    assert revived_game[187] = 0
    assert revived_game[188] = 0
    assert revived_game[189] = 0
    assert revived_game[190] = 0
    assert revived_game[191] = 0
    assert revived_game[192] = 0
    assert revived_game[193] = 0
    assert revived_game[194] = 0
    assert revived_game[195] = 0
    assert revived_game[196] = 0
    assert revived_game[197] = 0
    assert revived_game[198] = 0
    assert revived_game[199] = 0
    assert revived_game[200] = 0
    assert revived_game[201] = 0
    assert revived_game[202] = 0
    assert revived_game[203] = 0
    assert revived_game[204] = 0
    assert revived_game[205] = 0
    assert revived_game[206] = 0
    assert revived_game[207] = 0
    assert revived_game[208] = 0
    assert revived_game[209] = 0
    assert revived_game[210] = 0
    assert revived_game[211] = 0
    assert revived_game[212] = 0
    assert revived_game[213] = 0
    assert revived_game[214] = 0
    assert revived_game[215] = 0
    assert revived_game[216] = 0
    assert revived_game[217] = 0
    assert revived_game[218] = 0
    assert revived_game[219] = 0
    assert revived_game[220] = 0
    assert revived_game[221] = 0
    assert revived_game[222] = 0
    assert revived_game[223] = 0
    assert revived_game[224] = 0

    return ()
end

@external
func test_give_life_to_cell_no_credits{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    %{ stop_prank_callable = start_prank(123) %}
    evolve_and_claim_next_generation()
    give_life_to_cell(1)

    %{ expect_revert("TRANSACTION_FAILED") %}
    give_life_to_cell(2)
    %{ stop_prank_callable() %}
    return ()
end

@external
func test_give_life_to_cell_wrong_owner{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    %{ stop_prank_callable = start_prank(123) %}
    evolve_and_claim_next_generation()
    %{ stop_prank_callable() %}

    %{ start_prank(321) %}
    %{ expect_revert("TRANSACTION_FAILED") %}
    give_life_to_cell(5)

    return ()
end

@external
func test_give_life_to_cell_out_of_range{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    %{ start_prank(123) %}
    evolve_and_claim_next_generation()
    %{ expect_revert("TRANSACTION_FAILED") %}
    give_life_to_cell(255)
    return ()
end

@external
func test_give_life_to_cell_not_changed{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    %{ start_prank(123) %}
    evolve_and_claim_next_generation()
    %{ expect_revert("TRANSACTION_FAILED") %}
    give_life_to_cell(113)
    return ()
end
