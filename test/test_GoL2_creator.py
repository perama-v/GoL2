
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
    game = await starknet.deploy("contracts/GoL2_creator.cairo")
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
async def test_create(game_factory):
    # Start with freshly spawned game
    _, game, account = game_factory

    # First generate 10 credits by progressing another game.
    (first_index, first_game_id, newest_gen) = await game.newest_game().call()
    nonce = 1
    for i in range(10):
        print(f'Done with {i}')

        contribute = signer.build_transaction(account,
            game.contract_address, 'contribute', [first_game_id],
            nonce)
        await contribute.invoke()
        nonce = nonce + 1

    # Make sure credits were given.
    (game_count, credit_count) = await game.user_counts(
            account.contract_address).call()
    assert game_count == 0
    assert credit_count == 10

    # Redeem credits
    row_states = [ 2**(i) for i in range(32) ]
    create_game = signer.build_transaction(
        account, game.contract_address, 'create', row_states, nonce)
    await create_game.invoke()

    # Check that the user has a game.
    (game_index, ) = await game.specific_game_of_user(
        account.contract_address, 0).call()
    assert game_index == first_index + 1

    # Check that the game was recorded as the latest game.
    (index, id, gen) = await game.newest_game().call()
    assert index == first_index + 1

    im = await game.view_game(index, 0).call()
    view([im])
    print('Above is the newly created game')

    (gen,) = await game.generation_of_game(first_index).call()
    im = await game.view_game(first_index, gen).call()
    view([im])
    print('Above is the first game after being progressed 10 times.')


def view(images):
    # For an even grid appearance:
    # .replace('1','■ ').replace('0','. ')
    for index, image in enumerate(images):
        print(f"image_{index}:")
        [
            print(format(image[row], '#034b').replace('0b','')
            .replace('1','■ ').replace('0','. '))
            for row in range(DIM)
        ]
