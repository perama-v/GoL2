
import os
import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.Signer import Signer

signer = Signer(5858585858585858585)
L1_ADDRESS = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984

# Game constants
DIM = 32

@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope='module')
async def game_factory():
    starknet = await Starknet.empty()
    # Deploy
    game = await starknet.deploy("contracts/GoL2_stored_history.cairo")
    account = await starknet.deploy("contracts/Account.cairo")

    # Set up account
    await account.initialize(signer.public_key, L1_ADDRESS).invoke()
    # Initialize game (and token secondarily)
    spawn_game = signer.build_transaction(
        account, game.contract_address, 'spawn', [], 0)
    print('done')
    await spawn_game.invoke()
    return starknet, game, account


@pytest.mark.asyncio
async def test_game_flow(game_factory):
    # Start with freshly spawned game
    _, game, _ = game_factory

    ##### Game progression tests #####
    # How many player turns.
    turns = 1
    # How many generations pass per turn (capped using modulo).
    n_steps_within_turn = 1

    image_0 = await game.view_game().invoke()
    images = []
    images.append(image_0)
    # Run some turns and save the output after each turn.
    for i in range(turns):
        await game.evolve_generations(n_steps_within_turn).invoke()
        im = await game.view_game(
            turns * n_steps_within_turn).invoke()
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

@pytest.mark.asyncio
async def test_give_life(game_factory):
    _, game, _  = game_factory
    alter_row = 5
    alter_col = 5
    token_id_to_redeem = 1
    await game.give_life_to_cell(
        alter_row, alter_col, token_id_to_redeem).invoke()
    (altered) = await game.view_game(1).invoke()
    assert altered[alter_row] == 2**(DIM - 1 - alter_col)


@pytest.mark.asyncio
async def test_view_functions(game_factory):
    _, game, _  = game_factory
    alter_row = 5
    alter_col = 5
    token_id_to_redeem = 1
    res = await game.give_life_to_cell(
        alter_row, alter_col, token_id_to_redeem).invoke()
    (altered) = await game.view_game().call()
    assert altered[alter_row] == 2**(DIM - 1 - alter_col)


@pytest.mark.asyncio
async def test_edge_wrapping(game_factory):
    # Start with freshly spawned game
    _, game, account = game_factory

    ##### Wrapping tests #####
    top_left = 0
    top_right = DIM - 1
    bottom_right = DIM * DIM - 1
    bottom_left = DIM * DIM - DIM
    print('Wrapping tests:')
    # Test wrapping at all four corners.
    (TL) = await game.get_adjacent(top_left).invoke()
    #print('TL',TL)
    assert TL.R == 1
    assert TL.L == top_right
    assert TL.LU == bottom_right
    assert TL.U == bottom_left

    (TR) = await game.get_adjacent(top_right).invoke()
    #print('TR',TR)
    assert TR.R == top_left
    assert TR.L == top_right - 1
    assert TR.U == bottom_right
    assert TR.RU == bottom_left

    (BR) = await game.get_adjacent(bottom_right).invoke()
    #print('BR',BR)
    assert BR.R == bottom_left
    assert BR.L == bottom_right - 1
    assert BR.D == top_right
    assert BR.RD == top_left

    (BL) = await game.get_adjacent(bottom_left).invoke()
    #print('BL',BL)
    assert BL.R == bottom_left + 1
    assert BL.L == bottom_right
    assert BL.D == top_left
    assert BL.LD == top_right

