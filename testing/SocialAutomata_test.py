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
    DIM = 32
    top_left = 0
    top_right = DIM - 1
    bottom_right = DIM * DIM - 1
    bottom_left = DIM * DIM - DIM
    print('Wrapping tests:')
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
    # How many player turns.
    turns = 1
    # How many generations pass per turn (capped using modulo).
    n_steps_within_turn = 1

    await contract.spawn().invoke()
    image_0 = await contract.view_game().invoke()
    images = []
    images.append(image_0)
    # Run some turns and save the output after each turn.
    for i in range(turns):
        await contract.run(n_steps_within_turn).invoke()
        im = await contract.view_game().invoke()
        images.append(im)


    # For an even grid appearance:
    # .replace('1','■ ').replace('0','. ')
    for index, image in enumerate(images):
        print(f"image_{index}:")
        [
            print(format(image[row], '#034b').replace('0b','')
            .replace('1','■ ').replace('0','. '))
            for row in range(DIM)
        ]

    # Pytest times: (16x16) 3 turns, with 10 generations each ~= 376s
    # Pytest times: (32x32) 3 turns, with 1 generation each ~= 153s

    ##### Manual cell flip test #####
    alter_row = 5
    alter_col = 5
    await contract.give_life_to_cell(alter_row, alter_col).invoke()
    (altered) = await contract.view_game().invoke()
    assert altered[alter_row] == 2**(DIM - 1 - alter_col)

