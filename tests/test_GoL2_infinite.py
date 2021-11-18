
import os
import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.Signer import Signer

NUM_SIGNING_ACCOUNTS = 2
DUMMY_PRIVATE = 12345678987654321
signers = []

# Temporary user_ids to bypass account verification
USER_IDS = [76543, 23456, 12345, 78787, 94321, 36576]

# Game constants
DIM = 32

@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope='module')
async def account_factory():
    # Initialize network
    starknet = await Starknet.empty()
    accounts = []
    print(f'Deploying {NUM_SIGNING_ACCOUNTS} accounts...')
    for i in range(NUM_SIGNING_ACCOUNTS):
        signer = Signer(DUMMY_PRIVATE + i)
        signers.append(signer)
        account = await starknet.deploy(
            "contracts/Account.cairo",
            constructor_calldata=[signer.public_key]
        )
        await account.initialize(account.contract_address).invoke()
        accounts.append(account)

        print(f'Account {i} is: {hex(account.contract_address)}')

    # Admin is usually accounts[0], user_1 = accounts[1].
    # To build a transaction to call func_xyz(arg_1, arg_2)
    # on a TargetContract:

    # await Signer.send_transaction(
    #   account=accounts[1],
    #   to=TargetContract,
    #   selector_name='func_xyz',
    #   calldata=[arg_1, arg_2],
    #   nonce=current_nonce)

    # Note that nonce is an optional argument.
    return starknet, accounts


@pytest.fixture(scope='module')
async def game_factory(account_factory):
    starknet, accounts = account_factory
    # Deploy
    game = await starknet.deploy("contracts/GoL2_infinite.cairo")
    return starknet, game, accounts

@pytest.mark.asyncio
async def test_game_flow(game_factory):
    # Start with freshly spawned game
    _, game, _ = game_factory
    response = await game.current_generation_id().call()
    (first_id, ) = response.result
    assert first_id == 1
    ##### Game progression tests #####
    gens_per_turn = 1
    turns = 4
    # How many generations pass per turn (capped using modulo).

    response = await game.view_game(first_id).call()
    (image_0) = response.result
    images = []
    images.append(image_0)
    # Run some turns and save the output after each turn.
    prev_id = first_id
    for turn in range(turns):
        await game.evolve_and_claim_next_generation(
            USER_IDS[turn]).invoke()

        response = await game.current_generation_id().call()
        id = response.result.gen_id
        response = await game.view_game(id).call()
        (im) = response.result
        images.append(im)
        assert id == prev_id + gens_per_turn
        prev_id = id

    # For an even grid appearance:
    # .replace('1','■ ').replace('0','. ')
    for index, image in enumerate(images):
        print(f"image_{index}:")
        await display(image)

    (info) = await game.latest_useful_state(0).call()
    # TODO - add some checks on the two elements below (images, info)
    #print('images', images)
    #print('info', info)

    # Get arbitrary number of states
    ids = [0, 1, 2, 3, 4]
    n_most_recent = 3
    give_life_indices = []
    n_recent_give_life = 0
    response = await game.get_arbitrary_state_arrays(
        ids, n_most_recent, give_life_indices, n_recent_give_life).call()
    a = response.result.current_generation_id
    b = response.result.gen_ids_array_result
    c = response.result.specific_state_owners
    d = response.result.n_latest_states_result
    e = response.result.latest_state_owners
    f = response.result.latest_redemption_index
    g = response.result.give_life_array_result
    h = response.result.n_latest_give_life_result
    # The games are returned in one continuous array.
    requested_states = b
    states = []
    print('a',a)
    print('b', b)
    print('c', c)
    print('d', d)
    print('e', e)
    print('f', f)
    print('g', g)
    print('h', h)
    for i in range(0, len(ids), 32):
        game = requested_states[i:i + 32]
        states.append(game)
    await display(states)


@pytest.mark.asyncio
async def test_give_life(game_factory):
    _, game, _  = game_factory
    # Starts at acorn (ID 1), gives life, checks state of modified cell.
    alter_row = 5
    alter_col = 5
    invalid_token_id = 1

    game_pre = await game.current_generation_id().call()
    (id_pre, ) = game_pre.result
    response = await game.view_game(id_pre).call()
    (image_pre) = response.result
    await display(image_pre)

    with pytest.raises(Exception) as e_info:
        await game.give_life_to_cell(USER_IDS[0], alter_row,
        alter_col, invalid_token_id).invoke()
    print(f"Passed: Correctly fails when the claimer is not the owner.")

    # First make the player have a turn
    await game.evolve_and_claim_next_generation(
            USER_IDS[0]).invoke()

    already_alive_row=13
    already_alive_col=30
    # Get the details of their new token.
    response = await game.get_user_data(
        USER_IDS[0], 0).invoke()
    (user_token_id, _, _, _, _) = response.result
    # Then redeem token.
    assert user_token_id == 2

    with pytest.raises(Exception) as e_info:
        await game.give_life_to_cell(USER_IDS[0], already_alive_row,
        already_alive_col, user_token_id).invoke()
    print(f"Passed: Correctly fails when cell is already alive.")



    await game.give_life_to_cell(USER_IDS[0], alter_row,
        alter_col, user_token_id).invoke()


    response = await game.current_generation_id().call()
    (id_post, ) = response.result
    response = await game.view_game(id_post).call()
    (image_post) = response.result
    await display(image_post)

    assert id_pre == id_post - 1 == 1
    # Check the cell is alive.
    assert image_post[alter_row] == 2**(DIM - 1 - alter_col)
    print('Passed: Correctly updates a single cell')

    with pytest.raises(Exception) as e_info:
        await game.give_life_to_cell(USER_IDS[0], 4,
            4, user_token_id).invoke()
    print('Passed: Token cannot be redeemed twice')

async def display(image):
    print('')
    [
        print(format(image[row], '#034b').replace('0b','')
        .replace('1','■ ').replace('0','. '))
        for row in range(DIM)
    ]
    return

'''
Not for active testing - can activate by making get_adjacent @external.
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
'''