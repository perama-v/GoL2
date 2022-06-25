%lang starknet

from starkware.cairo.common.cairo_builtins import (HashBuiltin,
    BitwiseBuiltin)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.math import split_felt

from contracts.utils.packing import (pack_cells,
    unpack_cells, pack_game)

@external
func test_pack_cells{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (local cells : felt*) = alloc()
    assert cells[0] = 0
    assert cells[1] = 0
    assert cells[2] = 0
    assert cells[3] = 0
    assert cells[4] = 1
    assert cells[5] = 0
    assert cells[6] = 0
    assert cells[7] = 0
    assert cells[8] = 0
    assert cells[9] = 0

    let (packed_cells) = pack_cells(10, cells, packed_cells=0)
    assert packed_cells = 16

    return ()
end

@external
func test_unpack_cells{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (unpacked_cells_len, unpacked_cells) = unpack_cells(0, 16)

    assert unpacked_cells_len = 225
    assert unpacked_cells[0] = 0
    assert unpacked_cells[1] = 0
    assert unpacked_cells[2] = 0
    assert unpacked_cells[3] = 0
    assert unpacked_cells[4] = 0
    assert unpacked_cells[5] = 0
    assert unpacked_cells[6] = 0
    assert unpacked_cells[7] = 0
    assert unpacked_cells[8] = 0
    assert unpacked_cells[9] = 0
    assert unpacked_cells[10] = 0
    assert unpacked_cells[11] = 0
    assert unpacked_cells[12] = 0
    assert unpacked_cells[13] = 0
    assert unpacked_cells[14] = 0
    assert unpacked_cells[15] = 0
    assert unpacked_cells[16] = 0
    assert unpacked_cells[17] = 0
    assert unpacked_cells[18] = 0
    assert unpacked_cells[19] = 0
    assert unpacked_cells[20] = 0
    assert unpacked_cells[21] = 0
    assert unpacked_cells[22] = 0
    assert unpacked_cells[23] = 0
    assert unpacked_cells[24] = 0
    assert unpacked_cells[25] = 0
    assert unpacked_cells[26] = 0
    assert unpacked_cells[27] = 0
    assert unpacked_cells[28] = 0
    assert unpacked_cells[29] = 0
    assert unpacked_cells[30] = 0
    assert unpacked_cells[31] = 0
    assert unpacked_cells[32] = 0
    assert unpacked_cells[33] = 0
    assert unpacked_cells[34] = 0
    assert unpacked_cells[35] = 0
    assert unpacked_cells[36] = 0
    assert unpacked_cells[37] = 0
    assert unpacked_cells[38] = 0
    assert unpacked_cells[39] = 0
    assert unpacked_cells[40] = 0
    assert unpacked_cells[41] = 0
    assert unpacked_cells[42] = 0
    assert unpacked_cells[43] = 0
    assert unpacked_cells[44] = 0
    assert unpacked_cells[45] = 0
    assert unpacked_cells[46] = 0
    assert unpacked_cells[47] = 0
    assert unpacked_cells[48] = 0
    assert unpacked_cells[49] = 0
    assert unpacked_cells[50] = 0
    assert unpacked_cells[51] = 0
    assert unpacked_cells[52] = 0
    assert unpacked_cells[53] = 0
    assert unpacked_cells[54] = 0
    assert unpacked_cells[55] = 0
    assert unpacked_cells[56] = 0
    assert unpacked_cells[57] = 0
    assert unpacked_cells[58] = 0
    assert unpacked_cells[59] = 0
    assert unpacked_cells[60] = 0
    assert unpacked_cells[61] = 0
    assert unpacked_cells[62] = 0
    assert unpacked_cells[63] = 0
    assert unpacked_cells[64] = 0
    assert unpacked_cells[65] = 0
    assert unpacked_cells[66] = 0
    assert unpacked_cells[67] = 0
    assert unpacked_cells[68] = 0
    assert unpacked_cells[69] = 0
    assert unpacked_cells[70] = 0
    assert unpacked_cells[71] = 0
    assert unpacked_cells[72] = 0
    assert unpacked_cells[73] = 0
    assert unpacked_cells[74] = 0
    assert unpacked_cells[75] = 0
    assert unpacked_cells[76] = 0
    assert unpacked_cells[77] = 0
    assert unpacked_cells[78] = 0
    assert unpacked_cells[79] = 0
    assert unpacked_cells[80] = 0
    assert unpacked_cells[81] = 0
    assert unpacked_cells[82] = 0
    assert unpacked_cells[83] = 0
    assert unpacked_cells[84] = 0
    assert unpacked_cells[85] = 0
    assert unpacked_cells[86] = 0
    assert unpacked_cells[87] = 0
    assert unpacked_cells[88] = 0
    assert unpacked_cells[89] = 0
    assert unpacked_cells[90] = 0
    assert unpacked_cells[91] = 0
    assert unpacked_cells[92] = 0
    assert unpacked_cells[93] = 0
    assert unpacked_cells[94] = 0
    assert unpacked_cells[95] = 0
    assert unpacked_cells[96] = 0
    assert unpacked_cells[97] = 0
    assert unpacked_cells[98] = 0
    assert unpacked_cells[99] = 0
    assert unpacked_cells[100] = 0
    assert unpacked_cells[101] = 0
    assert unpacked_cells[102] = 0
    assert unpacked_cells[103] = 0
    assert unpacked_cells[104] = 0
    assert unpacked_cells[105] = 0
    assert unpacked_cells[106] = 0
    assert unpacked_cells[107] = 0
    assert unpacked_cells[108] = 0
    assert unpacked_cells[109] = 0
    assert unpacked_cells[110] = 0
    assert unpacked_cells[111] = 0
    assert unpacked_cells[112] = 0
    assert unpacked_cells[113] = 0
    assert unpacked_cells[114] = 0
    assert unpacked_cells[115] = 0
    assert unpacked_cells[116] = 1
    assert unpacked_cells[117] = 0
    assert unpacked_cells[118] = 0
    assert unpacked_cells[119] = 0
    assert unpacked_cells[120] = 0
    assert unpacked_cells[121] = 0
    assert unpacked_cells[122] = 0
    assert unpacked_cells[123] = 0
    assert unpacked_cells[124] = 0
    assert unpacked_cells[125] = 0
    assert unpacked_cells[126] = 0
    assert unpacked_cells[127] = 0
    assert unpacked_cells[128] = 0
    assert unpacked_cells[129] = 0
    assert unpacked_cells[130] = 0
    assert unpacked_cells[131] = 0
    assert unpacked_cells[132] = 0
    assert unpacked_cells[133] = 0
    assert unpacked_cells[134] = 0
    assert unpacked_cells[135] = 0
    assert unpacked_cells[136] = 0
    assert unpacked_cells[137] = 0
    assert unpacked_cells[138] = 0
    assert unpacked_cells[139] = 0
    assert unpacked_cells[140] = 0
    assert unpacked_cells[141] = 0
    assert unpacked_cells[142] = 0
    assert unpacked_cells[143] = 0
    assert unpacked_cells[144] = 0
    assert unpacked_cells[145] = 0
    assert unpacked_cells[146] = 0
    assert unpacked_cells[147] = 0
    assert unpacked_cells[148] = 0
    assert unpacked_cells[149] = 0
    assert unpacked_cells[150] = 0
    assert unpacked_cells[151] = 0
    assert unpacked_cells[152] = 0
    assert unpacked_cells[153] = 0
    assert unpacked_cells[154] = 0
    assert unpacked_cells[155] = 0
    assert unpacked_cells[156] = 0
    assert unpacked_cells[157] = 0
    assert unpacked_cells[158] = 0
    assert unpacked_cells[159] = 0
    assert unpacked_cells[160] = 0
    assert unpacked_cells[161] = 0
    assert unpacked_cells[162] = 0
    assert unpacked_cells[163] = 0
    assert unpacked_cells[164] = 0
    assert unpacked_cells[165] = 0
    assert unpacked_cells[166] = 0
    assert unpacked_cells[167] = 0
    assert unpacked_cells[168] = 0
    assert unpacked_cells[169] = 0
    assert unpacked_cells[170] = 0
    assert unpacked_cells[171] = 0
    assert unpacked_cells[172] = 0
    assert unpacked_cells[173] = 0
    assert unpacked_cells[174] = 0
    assert unpacked_cells[175] = 0
    assert unpacked_cells[176] = 0
    assert unpacked_cells[177] = 0
    assert unpacked_cells[178] = 0
    assert unpacked_cells[179] = 0
    assert unpacked_cells[180] = 0
    assert unpacked_cells[181] = 0
    assert unpacked_cells[182] = 0
    assert unpacked_cells[183] = 0
    assert unpacked_cells[184] = 0
    assert unpacked_cells[185] = 0
    assert unpacked_cells[186] = 0
    assert unpacked_cells[187] = 0
    assert unpacked_cells[188] = 0
    assert unpacked_cells[189] = 0
    assert unpacked_cells[190] = 0
    assert unpacked_cells[191] = 0
    assert unpacked_cells[192] = 0
    assert unpacked_cells[193] = 0
    assert unpacked_cells[194] = 0
    assert unpacked_cells[195] = 0
    assert unpacked_cells[196] = 0
    assert unpacked_cells[197] = 0
    assert unpacked_cells[198] = 0
    assert unpacked_cells[199] = 0
    assert unpacked_cells[200] = 0
    assert unpacked_cells[201] = 0
    assert unpacked_cells[202] = 0
    assert unpacked_cells[203] = 0
    assert unpacked_cells[204] = 0
    assert unpacked_cells[205] = 0
    assert unpacked_cells[206] = 0
    assert unpacked_cells[207] = 0
    assert unpacked_cells[208] = 0
    assert unpacked_cells[209] = 0
    assert unpacked_cells[210] = 0
    assert unpacked_cells[211] = 0
    assert unpacked_cells[212] = 0
    assert unpacked_cells[213] = 0
    assert unpacked_cells[214] = 0
    assert unpacked_cells[215] = 0
    assert unpacked_cells[216] = 0
    assert unpacked_cells[217] = 0
    assert unpacked_cells[218] = 0
    assert unpacked_cells[219] = 0
    assert unpacked_cells[220] = 0
    assert unpacked_cells[221] = 0
    assert unpacked_cells[222] = 0
    assert unpacked_cells[223] = 0
    assert unpacked_cells[224] = 0
    
    return ()
end

@external
func test_pack_game{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    let (packed_game) = pack_game(16, 16)
    let (high, low) = split_felt(packed_game)
    assert packed_game = 5444517870735015415413993718908291383312
    assert high = 16
    assert low = 16
    return ()
end

@external
func test_pack_game_acorn{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    alloc_locals
    let (local cells : felt*) = alloc()

    assert cells[0] = 0
    assert cells[1] = 0
    assert cells[2] = 0
    assert cells[3] = 0
    assert cells[4] = 0
    assert cells[5] = 0
    assert cells[6] = 0
    assert cells[7] = 0
    assert cells[8] = 0
    assert cells[9] = 0
    assert cells[10] = 0
    assert cells[11] = 0
    assert cells[12] = 0
    assert cells[13] = 0
    assert cells[14] = 0
    assert cells[15] = 0
    assert cells[16] = 0
    assert cells[17] = 0
    assert cells[18] = 0
    assert cells[19] = 0
    assert cells[20] = 0
    assert cells[21] = 0
    assert cells[22] = 0
    assert cells[23] = 0
    assert cells[24] = 0
    assert cells[25] = 0
    assert cells[26] = 0
    assert cells[27] = 0
    assert cells[28] = 0
    assert cells[29] = 0
    assert cells[30] = 0
    assert cells[31] = 0
    assert cells[32] = 0
    assert cells[33] = 0
    assert cells[34] = 0
    assert cells[35] = 0
    assert cells[36] = 0
    assert cells[37] = 0
    assert cells[38] = 0
    assert cells[39] = 0
    assert cells[40] = 0
    assert cells[41] = 0
    assert cells[42] = 0
    assert cells[43] = 0
    assert cells[44] = 0
    assert cells[45] = 0
    assert cells[46] = 0
    assert cells[47] = 0
    assert cells[48] = 0
    assert cells[49] = 0
    assert cells[50] = 0
    assert cells[51] = 0
    assert cells[52] = 0
    assert cells[53] = 0
    assert cells[54] = 0
    assert cells[55] = 0
    assert cells[56] = 0
    assert cells[57] = 0
    assert cells[58] = 0
    assert cells[59] = 0
    assert cells[60] = 0
    assert cells[61] = 0
    assert cells[62] = 0
    assert cells[63] = 0
    assert cells[64] = 0
    assert cells[65] = 0
    assert cells[66] = 0
    assert cells[67] = 0
    assert cells[68] = 0
    assert cells[69] = 0
    assert cells[70] = 0
    assert cells[71] = 0
    assert cells[72] = 0
    assert cells[73] = 0
    assert cells[74] = 0
    assert cells[75] = 0
    assert cells[76] = 0
    assert cells[77] = 0
    assert cells[78] = 0
    assert cells[79] = 0
    assert cells[80] = 0
    assert cells[81] = 0
    assert cells[82] = 0
    assert cells[83] = 0
    assert cells[84] = 0
    assert cells[85] = 0
    assert cells[86] = 0
    assert cells[87] = 0
    assert cells[88] = 0
    assert cells[89] = 0
    assert cells[90] = 0
    assert cells[91] = 0
    assert cells[92] = 0
    assert cells[93] = 0
    assert cells[94] = 0
    assert cells[95] = 0
    assert cells[96] = 0
    assert cells[97] = 0
    assert cells[98] = 0
    assert cells[99] = 1
    assert cells[100] = 0
    assert cells[101] = 0
    assert cells[102] = 0
    assert cells[103] = 0
    assert cells[104] = 0
    assert cells[105] = 0
    assert cells[106] = 0
    assert cells[107] = 0
    assert cells[108] = 0
    assert cells[109] = 0
    assert cells[110] = 0
    assert cells[111] = 0
    assert cells[112] = 0
    assert cells[113] = 0
    assert cells[114] = 0
    assert cells[115] = 0
    assert cells[116] = 1
    assert cells[117] = 0
    assert cells[118] = 0
    assert cells[119] = 0
    assert cells[120] = 0
    assert cells[121] = 0
    assert cells[122] = 0
    assert cells[123] = 0
    assert cells[124] = 0
    assert cells[125] = 0
    assert cells[126] = 0
    assert cells[127] = 0
    assert cells[128] = 1
    assert cells[129] = 1
    assert cells[130] = 0
    assert cells[131] = 0
    assert cells[132] = 1
    assert cells[133] = 1
    assert cells[134] = 1
    assert cells[135] = 0
    assert cells[136] = 0
    assert cells[137] = 0
    assert cells[138] = 0
    assert cells[139] = 0
    assert cells[140] = 0
    assert cells[141] = 0
    assert cells[142] = 0
    assert cells[143] = 0
    assert cells[144] = 0
    assert cells[145] = 0
    assert cells[146] = 0
    assert cells[147] = 0
    assert cells[148] = 0
    assert cells[149] = 0
    assert cells[150] = 0
    assert cells[151] = 0
    assert cells[152] = 0
    assert cells[153] = 0
    assert cells[154] = 0
    assert cells[155] = 0
    assert cells[156] = 0
    assert cells[157] = 0
    assert cells[158] = 0
    assert cells[159] = 0
    assert cells[160] = 0
    assert cells[161] = 0
    assert cells[162] = 0
    assert cells[163] = 0
    assert cells[164] = 0
    assert cells[165] = 0
    assert cells[166] = 0
    assert cells[167] = 0
    assert cells[168] = 0
    assert cells[169] = 0
    assert cells[170] = 0
    assert cells[171] = 0
    assert cells[172] = 0
    assert cells[173] = 0
    assert cells[174] = 0
    assert cells[175] = 0
    assert cells[176] = 0
    assert cells[177] = 0
    assert cells[178] = 0
    assert cells[179] = 0
    assert cells[180] = 0
    assert cells[181] = 0
    assert cells[182] = 0
    assert cells[183] = 0
    assert cells[184] = 0
    assert cells[185] = 0
    assert cells[186] = 0
    assert cells[187] = 0
    assert cells[188] = 0
    assert cells[189] = 0
    assert cells[190] = 0
    assert cells[191] = 0
    assert cells[192] = 0
    assert cells[193] = 0
    assert cells[194] = 0
    assert cells[195] = 0
    assert cells[196] = 0
    assert cells[197] = 0
    assert cells[198] = 0
    assert cells[199] = 0
    assert cells[200] = 0
    assert cells[201] = 0
    assert cells[202] = 0
    assert cells[203] = 0
    assert cells[204] = 0
    assert cells[205] = 0
    assert cells[206] = 0
    assert cells[207] = 0
    assert cells[208] = 0
    assert cells[209] = 0
    assert cells[210] = 0
    assert cells[211] = 0
    assert cells[212] = 0
    assert cells[213] = 0
    assert cells[214] = 0
    assert cells[215] = 0
    assert cells[216] = 0
    assert cells[217] = 0
    assert cells[218] = 0
    assert cells[219] = 0
    assert cells[220] = 0
    assert cells[221] = 0
    assert cells[222] = 0
    assert cells[223] = 0
    assert cells[224] = 0

    let (high_acorn) = pack_cells(112, cells, packed_cells=0)
    let (low_acorn) = pack_cells(113, cells + 112, packed_cells=0)

    assert high_acorn = 633825300114114700748351602688
    assert low_acorn = 7536656

    let (packed_game) = pack_game(high_acorn, low_acorn)
    assert packed_game = 215679573337205118357336120696157045389097155380324579848828889530384

    let (high_unpacked, low_unpacked) = split_felt(packed_game)
    assert high_unpacked = high_acorn
    assert low_unpacked = low_acorn

    let (local unpacked_cells : felt*) = alloc()
    let (unpacked_cells_len, unpacked_cells) = unpack_cells(high_unpacked, low_unpacked)

    assert unpacked_cells_len = 225
    assert cells[0] = unpacked_cells[0]
    assert cells[1] = unpacked_cells[1]
    assert cells[2] = unpacked_cells[2]
    assert cells[3] = unpacked_cells[3]
    assert cells[4] = unpacked_cells[4]
    assert cells[5] = unpacked_cells[5]
    assert cells[6] = unpacked_cells[6]
    assert cells[7] = unpacked_cells[7]
    assert cells[8] = unpacked_cells[8]
    assert cells[9] = unpacked_cells[9]
    assert cells[10] = unpacked_cells[10]
    assert cells[11] = unpacked_cells[11]
    assert cells[12] = unpacked_cells[12]
    assert cells[13] = unpacked_cells[13]
    assert cells[14] = unpacked_cells[14]
    assert cells[15] = unpacked_cells[15]
    assert cells[16] = unpacked_cells[16]
    assert cells[17] = unpacked_cells[17]
    assert cells[18] = unpacked_cells[18]
    assert cells[19] = unpacked_cells[19]
    assert cells[20] = unpacked_cells[20]
    assert cells[21] = unpacked_cells[21]
    assert cells[22] = unpacked_cells[22]
    assert cells[23] = unpacked_cells[23]
    assert cells[24] = unpacked_cells[24]
    assert cells[25] = unpacked_cells[25]
    assert cells[26] = unpacked_cells[26]
    assert cells[27] = unpacked_cells[27]
    assert cells[28] = unpacked_cells[28]
    assert cells[29] = unpacked_cells[29]
    assert cells[30] = unpacked_cells[30]
    assert cells[31] = unpacked_cells[31]
    assert cells[32] = unpacked_cells[32]
    assert cells[33] = unpacked_cells[33]
    assert cells[34] = unpacked_cells[34]
    assert cells[35] = unpacked_cells[35]
    assert cells[36] = unpacked_cells[36]
    assert cells[37] = unpacked_cells[37]
    assert cells[38] = unpacked_cells[38]
    assert cells[39] = unpacked_cells[39]
    assert cells[40] = unpacked_cells[40]
    assert cells[41] = unpacked_cells[41]
    assert cells[42] = unpacked_cells[42]
    assert cells[43] = unpacked_cells[43]
    assert cells[44] = unpacked_cells[44]
    assert cells[45] = unpacked_cells[45]
    assert cells[46] = unpacked_cells[46]
    assert cells[47] = unpacked_cells[47]
    assert cells[48] = unpacked_cells[48]
    assert cells[49] = unpacked_cells[49]
    assert cells[50] = unpacked_cells[50]
    assert cells[51] = unpacked_cells[51]
    assert cells[52] = unpacked_cells[52]
    assert cells[53] = unpacked_cells[53]
    assert cells[54] = unpacked_cells[54]
    assert cells[55] = unpacked_cells[55]
    assert cells[56] = unpacked_cells[56]
    assert cells[57] = unpacked_cells[57]
    assert cells[58] = unpacked_cells[58]
    assert cells[59] = unpacked_cells[59]
    assert cells[60] = unpacked_cells[60]
    assert cells[61] = unpacked_cells[61]
    assert cells[62] = unpacked_cells[62]
    assert cells[63] = unpacked_cells[63]
    assert cells[64] = unpacked_cells[64]
    assert cells[65] = unpacked_cells[65]
    assert cells[66] = unpacked_cells[66]
    assert cells[67] = unpacked_cells[67]
    assert cells[68] = unpacked_cells[68]
    assert cells[69] = unpacked_cells[69]
    assert cells[70] = unpacked_cells[70]
    assert cells[71] = unpacked_cells[71]
    assert cells[72] = unpacked_cells[72]
    assert cells[73] = unpacked_cells[73]
    assert cells[74] = unpacked_cells[74]
    assert cells[75] = unpacked_cells[75]
    assert cells[76] = unpacked_cells[76]
    assert cells[77] = unpacked_cells[77]
    assert cells[78] = unpacked_cells[78]
    assert cells[79] = unpacked_cells[79]
    assert cells[80] = unpacked_cells[80]
    assert cells[81] = unpacked_cells[81]
    assert cells[82] = unpacked_cells[82]
    assert cells[83] = unpacked_cells[83]
    assert cells[84] = unpacked_cells[84]
    assert cells[85] = unpacked_cells[85]
    assert cells[86] = unpacked_cells[86]
    assert cells[87] = unpacked_cells[87]
    assert cells[88] = unpacked_cells[88]
    assert cells[89] = unpacked_cells[89]
    assert cells[90] = unpacked_cells[90]
    assert cells[91] = unpacked_cells[91]
    assert cells[92] = unpacked_cells[92]
    assert cells[93] = unpacked_cells[93]
    assert cells[94] = unpacked_cells[94]
    assert cells[95] = unpacked_cells[95]
    assert cells[96] = unpacked_cells[96]
    assert cells[97] = unpacked_cells[97]
    assert cells[98] = unpacked_cells[98]
    assert cells[99] = unpacked_cells[99]
    assert cells[100] = unpacked_cells[100]
    assert cells[101] = unpacked_cells[101]
    assert cells[102] = unpacked_cells[102]
    assert cells[103] = unpacked_cells[103]
    assert cells[104] = unpacked_cells[104]
    assert cells[105] = unpacked_cells[105]
    assert cells[106] = unpacked_cells[106]
    assert cells[107] = unpacked_cells[107]
    assert cells[108] = unpacked_cells[108]
    assert cells[109] = unpacked_cells[109]
    assert cells[110] = unpacked_cells[110]
    assert cells[111] = unpacked_cells[111]
    assert cells[112] = unpacked_cells[112]
    assert cells[113] = unpacked_cells[113]
    assert cells[114] = unpacked_cells[114]
    assert cells[115] = unpacked_cells[115]
    assert cells[116] = unpacked_cells[116]
    assert cells[117] = unpacked_cells[117]
    assert cells[118] = unpacked_cells[118]
    assert cells[119] = unpacked_cells[119]
    assert cells[120] = unpacked_cells[120]
    assert cells[121] = unpacked_cells[121]
    assert cells[122] = unpacked_cells[122]
    assert cells[123] = unpacked_cells[123]
    assert cells[124] = unpacked_cells[124]
    assert cells[125] = unpacked_cells[125]
    assert cells[126] = unpacked_cells[126]
    assert cells[127] = unpacked_cells[127]
    assert cells[128] = unpacked_cells[128]
    assert cells[129] = unpacked_cells[129]
    assert cells[130] = unpacked_cells[130]
    assert cells[131] = unpacked_cells[131]
    assert cells[132] = unpacked_cells[132]
    assert cells[133] = unpacked_cells[133]
    assert cells[134] = unpacked_cells[134]
    assert cells[135] = unpacked_cells[135]
    assert cells[136] = unpacked_cells[136]
    assert cells[137] = unpacked_cells[137]
    assert cells[138] = unpacked_cells[138]
    assert cells[139] = unpacked_cells[139]
    assert cells[140] = unpacked_cells[140]
    assert cells[141] = unpacked_cells[141]
    assert cells[142] = unpacked_cells[142]
    assert cells[143] = unpacked_cells[143]
    assert cells[144] = unpacked_cells[144]
    assert cells[145] = unpacked_cells[145]
    assert cells[146] = unpacked_cells[146]
    assert cells[147] = unpacked_cells[147]
    assert cells[148] = unpacked_cells[148]
    assert cells[149] = unpacked_cells[149]
    assert cells[150] = unpacked_cells[150]
    assert cells[151] = unpacked_cells[151]
    assert cells[152] = unpacked_cells[152]
    assert cells[153] = unpacked_cells[153]
    assert cells[154] = unpacked_cells[154]
    assert cells[155] = unpacked_cells[155]
    assert cells[156] = unpacked_cells[156]
    assert cells[157] = unpacked_cells[157]
    assert cells[158] = unpacked_cells[158]
    assert cells[159] = unpacked_cells[159]
    assert cells[160] = unpacked_cells[160]
    assert cells[161] = unpacked_cells[161]
    assert cells[162] = unpacked_cells[162]
    assert cells[163] = unpacked_cells[163]
    assert cells[164] = unpacked_cells[164]
    assert cells[165] = unpacked_cells[165]
    assert cells[166] = unpacked_cells[166]
    assert cells[167] = unpacked_cells[167]
    assert cells[168] = unpacked_cells[168]
    assert cells[169] = unpacked_cells[169]
    assert cells[170] = unpacked_cells[170]
    assert cells[171] = unpacked_cells[171]
    assert cells[172] = unpacked_cells[172]
    assert cells[173] = unpacked_cells[173]
    assert cells[174] = unpacked_cells[174]
    assert cells[175] = unpacked_cells[175]
    assert cells[176] = unpacked_cells[176]
    assert cells[177] = unpacked_cells[177]
    assert cells[178] = unpacked_cells[178]
    assert cells[179] = unpacked_cells[179]
    assert cells[180] = unpacked_cells[180]
    assert cells[181] = unpacked_cells[181]
    assert cells[182] = unpacked_cells[182]
    assert cells[183] = unpacked_cells[183]
    assert cells[184] = unpacked_cells[184]
    assert cells[185] = unpacked_cells[185]
    assert cells[186] = unpacked_cells[186]
    assert cells[187] = unpacked_cells[187]
    assert cells[188] = unpacked_cells[188]
    assert cells[189] = unpacked_cells[189]
    assert cells[190] = unpacked_cells[190]
    assert cells[191] = unpacked_cells[191]
    assert cells[192] = unpacked_cells[192]
    assert cells[193] = unpacked_cells[193]
    assert cells[194] = unpacked_cells[194]
    assert cells[195] = unpacked_cells[195]
    assert cells[196] = unpacked_cells[196]
    assert cells[197] = unpacked_cells[197]
    assert cells[198] = unpacked_cells[198]
    assert cells[199] = unpacked_cells[199]
    assert cells[200] = unpacked_cells[200]
    assert cells[201] = unpacked_cells[201]
    assert cells[202] = unpacked_cells[202]
    assert cells[203] = unpacked_cells[203]
    assert cells[204] = unpacked_cells[204]
    assert cells[205] = unpacked_cells[205]
    assert cells[206] = unpacked_cells[206]
    assert cells[207] = unpacked_cells[207]
    assert cells[208] = unpacked_cells[208]
    assert cells[209] = unpacked_cells[209]
    assert cells[210] = unpacked_cells[210]
    assert cells[211] = unpacked_cells[211]
    assert cells[212] = unpacked_cells[212]
    assert cells[213] = unpacked_cells[213]
    assert cells[214] = unpacked_cells[214]
    assert cells[215] = unpacked_cells[215]
    assert cells[216] = unpacked_cells[216]
    assert cells[217] = unpacked_cells[217]
    assert cells[218] = unpacked_cells[218]
    assert cells[219] = unpacked_cells[219]
    assert cells[220] = unpacked_cells[220]
    assert cells[221] = unpacked_cells[221]
    assert cells[222] = unpacked_cells[222]
    assert cells[223] = unpacked_cells[223]
    assert cells[224] = unpacked_cells[224]

    return ()
end

@external
func test_maximum_packed_game{
        syscall_ptr : felt*,
        bitwise_ptr : BitwiseBuiltin*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }():
    # if whole baord is filled with live cells
    # we should still be able to pack the game into one felt
    # the board is 15*15, so max we have 225 cells divided
    # into high and low part
    alloc_locals

    # high is one houndred and twelve ones
    local high = 5192296858534827628530496329220095
    # low is one houndred and thirteen ones
    local low = 10384593717069655257060992658440191

    let (packed_game) = pack_game(high, low)
    assert packed_game = 1766847064778384329583297500742918175555501569654225150004059762182848511

    let (new_high, new_low) = split_felt(packed_game)
    assert new_high = high
    assert new_low = low
    return ()
end
