%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)

from contracts.creator import (create, contribute, user_counts, generation_of_game, view_game, newest_game)

@external
func test_create_happy_case{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    local game_state = 1
    local game_hash = 2001140082530619239661729809084578298299223810202097622761632384561112390979
    %{
        expect_events({"name": "game_created", "data": [123, 2, ids.game_hash, 1]})
        expect_events({"name": "credit_reduced", "data": [123, 0]})
    %}

    %{ stop_prank_callable = start_prank(123) %}
    # add credits by progressing 10 games
    contribute(game_index=1)
    contribute(game_index=1)
    contribute(game_index=1)
    contribute(game_index=1)
    contribute(game_index=1)
    contribute(game_index=1)
    contribute(game_index=1)
    contribute(game_index=1)
    contribute(game_index=1)
    contribute(game_index=1)

    let (_, credit_count) = user_counts(user_id=123)
    assert credit_count = 10

    # create new game
    create(game_state=game_state)

    %{ stop_prank_callable() %}

    # check if credits were reduced and game was accounted
    let (user_games, new_credit_count) = user_counts(user_id=123)
    assert new_credit_count = 0
    assert user_games = 1

    # check index
    let (game_index, game_id, generation) = newest_game()
    assert game_index = 2
    assert game_id = game_hash
    generation = 0

    # check the game is properly stored
    let (game_len, game) = view_game(game_index=game_index, generation=generation)
    assert game_len = 225
    assert game[0] = 0
    assert game[1] = 0
    assert game[2] = 0
    assert game[3] = 0
    assert game[4] = 0
    assert game[5] = 0
    assert game[6] = 0
    assert game[7] = 0
    assert game[8] = 0
    assert game[9] = 0
    assert game[10] = 0
    assert game[11] = 0
    assert game[12] = 0
    assert game[13] = 0
    assert game[14] = 0
    assert game[15] = 0
    assert game[16] = 0
    assert game[17] = 0
    assert game[18] = 0
    assert game[19] = 0
    assert game[20] = 0
    assert game[21] = 0
    assert game[22] = 0
    assert game[23] = 0
    assert game[24] = 0
    assert game[25] = 0
    assert game[26] = 0
    assert game[27] = 0
    assert game[28] = 0
    assert game[29] = 0
    assert game[30] = 0
    assert game[31] = 0
    assert game[32] = 0
    assert game[33] = 0
    assert game[34] = 0
    assert game[35] = 0
    assert game[36] = 0
    assert game[37] = 0
    assert game[38] = 0
    assert game[39] = 0
    assert game[40] = 0
    assert game[41] = 0
    assert game[42] = 0
    assert game[43] = 0
    assert game[44] = 0
    assert game[45] = 0
    assert game[46] = 0
    assert game[47] = 0
    assert game[48] = 0
    assert game[49] = 0
    assert game[50] = 0
    assert game[51] = 0
    assert game[52] = 0
    assert game[53] = 0
    assert game[54] = 0
    assert game[55] = 0
    assert game[56] = 0
    assert game[57] = 0
    assert game[58] = 0
    assert game[59] = 0
    assert game[60] = 0
    assert game[61] = 0
    assert game[62] = 0
    assert game[63] = 0
    assert game[64] = 0
    assert game[65] = 0
    assert game[66] = 0
    assert game[67] = 0
    assert game[68] = 0
    assert game[69] = 0
    assert game[70] = 0
    assert game[71] = 0
    assert game[72] = 0
    assert game[73] = 0
    assert game[74] = 0
    assert game[75] = 0
    assert game[76] = 0
    assert game[77] = 0
    assert game[78] = 0
    assert game[79] = 0
    assert game[80] = 0
    assert game[81] = 0
    assert game[82] = 0
    assert game[83] = 0
    assert game[84] = 0
    assert game[85] = 0
    assert game[86] = 0
    assert game[87] = 0
    assert game[88] = 0
    assert game[89] = 0
    assert game[90] = 0
    assert game[91] = 0
    assert game[92] = 0
    assert game[93] = 0
    assert game[94] = 0
    assert game[95] = 0
    assert game[96] = 0
    assert game[97] = 0
    assert game[98] = 0
    assert game[99] = 0
    assert game[100] = 0
    assert game[101] = 0
    assert game[102] = 0
    assert game[103] = 0
    assert game[104] = 0
    assert game[105] = 0
    assert game[106] = 0
    assert game[107] = 0
    assert game[108] = 0
    assert game[109] = 0
    assert game[110] = 0
    assert game[111] = 0
    assert game[112] = 1
    assert game[113] = 0
    assert game[114] = 0
    assert game[115] = 0
    assert game[116] = 0
    assert game[117] = 0
    assert game[118] = 0
    assert game[119] = 0
    assert game[120] = 0
    assert game[121] = 0
    assert game[122] = 0
    assert game[123] = 0
    assert game[124] = 0
    assert game[125] = 0
    assert game[126] = 0
    assert game[127] = 0
    assert game[128] = 0
    assert game[129] = 0
    assert game[130] = 0
    assert game[131] = 0
    assert game[132] = 0
    assert game[133] = 0
    assert game[134] = 0
    assert game[135] = 0
    assert game[136] = 0
    assert game[137] = 0
    assert game[138] = 0
    assert game[139] = 0
    assert game[140] = 0
    assert game[141] = 0
    assert game[142] = 0
    assert game[143] = 0
    assert game[144] = 0
    assert game[145] = 0
    assert game[146] = 0
    assert game[147] = 0
    assert game[148] = 0
    assert game[149] = 0
    assert game[150] = 0
    assert game[151] = 0
    assert game[152] = 0
    assert game[153] = 0
    assert game[154] = 0
    assert game[155] = 0
    assert game[156] = 0
    assert game[157] = 0
    assert game[158] = 0
    assert game[159] = 0
    assert game[160] = 0
    assert game[161] = 0
    assert game[162] = 0
    assert game[163] = 0
    assert game[164] = 0
    assert game[165] = 0
    assert game[166] = 0
    assert game[167] = 0
    assert game[168] = 0
    assert game[169] = 0
    assert game[170] = 0
    assert game[171] = 0
    assert game[172] = 0
    assert game[173] = 0
    assert game[174] = 0
    assert game[175] = 0
    assert game[176] = 0
    assert game[177] = 0
    assert game[178] = 0
    assert game[179] = 0
    assert game[180] = 0
    assert game[181] = 0
    assert game[182] = 0
    assert game[183] = 0
    assert game[184] = 0
    assert game[185] = 0
    assert game[186] = 0
    assert game[187] = 0
    assert game[188] = 0
    assert game[189] = 0
    assert game[190] = 0
    assert game[191] = 0
    assert game[192] = 0
    assert game[193] = 0
    assert game[194] = 0
    assert game[195] = 0
    assert game[196] = 0
    assert game[197] = 0
    assert game[198] = 0
    assert game[199] = 0
    assert game[200] = 0
    assert game[201] = 0
    assert game[202] = 0
    assert game[203] = 0
    assert game[204] = 0
    assert game[205] = 0
    assert game[206] = 0
    assert game[207] = 0
    assert game[208] = 0
    assert game[209] = 0
    assert game[210] = 0
    assert game[211] = 0
    assert game[212] = 0
    assert game[213] = 0
    assert game[214] = 0
    assert game[215] = 0
    assert game[216] = 0
    assert game[217] = 0
    assert game[218] = 0
    assert game[219] = 0
    assert game[220] = 0
    assert game[221] = 0
    assert game[222] = 0
    assert game[223] = 0
    assert game[224] = 0

    return ()

end

@external
func test_create_no_credits{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    %{ start_prank(123) %}
    let (_, credit_count) = user_counts(user_id=123)
    assert credit_count = 0

    %{ expect_revert("TRANSACTION_FAILED") %}
    create(game_state=2)

    return ()
end

@external
func test_create_game_already_exists{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    local acorn = 215679573337205118357336120696157045389097155380324579848828889530384
    %{ start_prank(123) %}
    contribute(game_index=0)
    contribute(game_index=0)
    contribute(game_index=0)
    contribute(game_index=0)
    contribute(game_index=0)
    contribute(game_index=0)
    contribute(game_index=0)
    contribute(game_index=0)
    contribute(game_index=0)
    contribute(game_index=0)

    %{ expect_revert("TRANSACTION_FAILED") %}
    create(game_state=acorn)

    return ()
end

@external
func test_contribute{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    %{
        expect_events({"name": "contribution_made", "data": [123, 1, 1]})
        expect_events({"name": "credit_earned", "data": [123, 1]})
    %}
    let (generation) = generation_of_game(game_index=0)
    assert generation = 0

    let (_, credit_count) = user_counts(user_id=123)
    assert credit_count = 0

    %{ stop_prank_callable = start_prank(123) %}

    contribute(game_index=1)

    %{ stop_prank_callable() %}

    let (new_generation) = generation_of_game(game_index=1)
    assert new_generation = 1

    let (_, new_credit_count) = user_counts(user_id=123)
    assert new_credit_count = 1

    let (progressed_game_len, progressed_game) = view_game(game_index=1, generation=1)
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
