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
async def check_neighbour_calc():
    # Compile the contract.
    contract_definition = compile_starknet_files(
        [CONTRACT_FILE], debug_info=True)

    # Create a new Starknet class that simulates StarkNet
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract_address = await starknet.deploy(
        contract_definition=contract_definition)
    contract = StarknetContract(
        starknet=starknet,
        abi=contract_definition.abi,
        contract_address=contract_address,
    )
    DIM = 16
    top_left = 0
    (TL) = await contract.get_adjacent(
        top_left).invoke()
    print('TL',TL)
    assert TL.R == 1
    assert TL.L == DIM

    top_right = DIM
    (TR) = await contract.get_adjacent(
        top_left).invoke()
    print('TR',TR)
    assert TR.R == 0
    assert TR.L == DIM - 1

    # TODO add more tests here.


@pytest.mark.asyncio
async def test_record_items():
    # Compile the contract.
    contract_definition = compile_starknet_files(
        [CONTRACT_FILE], debug_info=True)

    # Create a new Starknet class that simulates StarkNet
    starknet = await Starknet.empty()

    # Deploy the contract.
    contract_address = await starknet.deploy(
        contract_definition=contract_definition)
    contract = StarknetContract(
        starknet=starknet,
        abi=contract_definition.abi,
        contract_address=contract_address,
    )
    n_steps = 1
    alter_row = 0
    alter_col = 3
    await contract.spawn().invoke()
    image_0 = await contract.view_game().invoke()
    test = await contract.run(n_steps, alter_row, alter_col).invoke()
    print('test',test)
    image_1 = await contract.view_game().invoke()

    # For an even grid appearance:
    # .replace('1','■ ').replace('0','. ')
    print("image_0:")
    [
        print(format(image_0[row], '#018b').replace('0b',''))
        for row in range(16)
    ]

    print("image_1:")
    [
        print(format(image_1[row], '#018b').replace('0b',''))
        for row in range(16)
    ]
    [
        print(format(image_1[row]))
        for row in range(16)
    ]
    '''
    0111111001001101
    1101010011001000
    0000010000010011
    0100101110011111
    1100111111000010
    1000101111101010
    1101100010000101
    0001000001010111
    1111101011010101
    1000000001101101
    0100100001000101
    1100011000010010
    1011000000100101
    0000010100001101
    1110111000000001
    1010100011101110
    '''
    assert image_0 != image_1
