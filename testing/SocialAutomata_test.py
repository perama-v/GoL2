import os
import pytest

from starkware.starknet.compiler.compile import (
    compile_starknet_files)
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract

# The path to the contract source code.
CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "../contracts/SocialAutomata.cairo")


@pytest.mark.asyncio
async def test_record_items():

    # Create a new Starknet class that simulates StarkNet
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract = await starknet.deploy(CONTRACT_FILE)

    ##### Wrapping tests #####
    DIM = 16
    top_left = 0
    top_right = DIM - 1
    bottom_right = DIM * DIM - 1
    bottom_left = DIM * DIM - DIM
    # Test wrapping at all four corners.
    (TL) = await contract.get_adjacent(top_left).invoke()
    print('TL',TL)
    assert TL.R == 1
    assert TL.L == top_right
    assert TL.LU == bottom_right
    assert TL.U == bottom_left

    (TR) = await contract.get_adjacent(top_right).invoke()
    print('TR',TR)
    assert TR.R == top_left
    assert TR.L == top_right - 1
    assert TR.U == bottom_right
    assert TR.RU == bottom_left

    (BR) = await contract.get_adjacent(bottom_right).invoke()
    print('BR',BR)
    assert BR.R == bottom_left
    assert BR.L == bottom_right - 1
    assert BR.D == top_right
    assert BR.RD == top_left

    (BL) = await contract.get_adjacent(bottom_left).invoke()
    print('BL',BL)
    assert BL.R == bottom_left + 1
    assert BL.L == bottom_right
    assert BL.D == top_left
    assert BL.LD == top_right

    ##### Game progression tests #####
    n_steps = 1
    alter_row = 5
    alter_col = 5
    await contract.spawn().invoke()
    image_0 = await contract.view_game().invoke()
    test = await contract.run(n_steps, alter_row, alter_col).invoke()
    print('test',test)
    image_1 = await contract.view_game().invoke()

    # For an even grid appearance:
    # .replace('1','■ ').replace('0','. ')
    print("image_0:")
    [
        print(format(image_0[row], '#018b').replace('0b','')
        .replace('1','■ ').replace('0','. '))
        for row in range(16)
    ]

    print("image_1:")
    [
        print(format(image_1[row], '#018b').replace('0b','')
        .replace('1','■ ').replace('0','. '))
        for row in range(16)
    ]
    [
        print(format(image_1[row]))
        for row in range(16)
    ]

    # Test the manually flipped bit
    assert image_1[alter_row] == 2**(16-alter_col)

    # Fails, shape should be left one.
    assert image_1[12] == 0
    assert image_1[13] == int('1110110',2)
    assert image_1[14] == int(    '110',2)
    assert image_1[15] == int(     '10',2)

