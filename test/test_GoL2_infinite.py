
import os
import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.Signer import Signer

signer = Signer(5858585858585858585)
L1_ADDRESS = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984

# Temporary user_ids to bypass account verification
USER_IDS = [76543, 23456, 12345, 78787, 94321, 36576]

# Game constants
DIM = 32

@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()


@pytest.fixture(scope='module')
async def game_factory():
    starknet = await Starknet.empty()
    # Deploy
    game = await starknet.deploy("contracts/GoL2_infinite.cairo")
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
    (first_id, ) = await game.current_generation_id().call()
    assert first_id == 1
    ##### Game progression tests #####
    gens_per_turn = 1
    turns = 4
    # How many generations pass per turn (capped using modulo).

    image_0 = await game.view_game(first_id).invoke()
    images = []
    images.append(image_0)
    # Run some turns and save the output after each turn.
    prev_id = first_id
    for turn in range(turns):
        await game.evolve_and_claim_next_generation(
            USER_IDS[turn]).invoke()

        (id, ) = await game.current_generation_id().call()

        im = await game.view_game(id).call()
        images.append(im)
        assert id == prev_id + gens_per_turn
        prev_id = id

    # For an even grid appearance:
    # .replace('1','■ ').replace('0','. ')
    for index, image in enumerate(images):
        print(f"image_{index}:")
        await display(image)


@pytest.mark.asyncio
async def test_give_life(game_factory):
    _, game, _  = game_factory
    # Starts at acorn (ID 1), gives life, checks state of modified cell.
    alter_row = 5
    alter_col = 5
    invalid_token_id = 1
    (id_pre, ) = await game.current_generation_id().call()
    (image_pre) = await game.view_game(id_pre).invoke()
    await display(image_pre)

    with pytest.raises(Exception) as e_info:
        await game.give_life_to_cell(USER_IDS[0], alter_row,
        alter_col, invalid_token_id).invoke()
    print(f"Passed: Correctly fails when the claimer is not the owner.")

    # First make the player have a turn
    await game.evolve_and_claim_next_generation(
            USER_IDS[0]).invoke()

    # Get the details of their new token.
    (user_token_id, _, _, _, _) = await game.get_user_data(
        USER_IDS[0], 0).invoke()
    # Then redeem token.
    assert user_token_id == 2
    await game.give_life_to_cell(USER_IDS[0], alter_row,
        alter_col, user_token_id).invoke()


    (id_post, ) = await game.current_generation_id().call()
    (image_post) = await game.view_game(id_post).invoke()
    await display(image_post)

    assert id_pre == id_post - 1 == 1
    # Check the cell is alive.
    assert image_post[alter_row] == 2**(DIM - 1 - alter_col)
    print('Passed: Correctly updates a single cell')

    with pytest.raises(Exception) as e_info:
        await game.give_life_to_cell(USER_IDS[0], 4,
            4, user_token_id).invoke()
    print('Passed: Token cannot be redeemed twice')


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

async def display(image):
    print('')
    [
        print(format(image[row], '#034b').replace('0b','')
        .replace('1','■ ').replace('0','. '))
        for row in range(DIM)
    ]
    return