
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
    # evolver = await starknet.deploy("contracts/Evolver.cairo")
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
    # From the zero address.
    '''
    for i in range(10):
        print(f'Done with {i}')
        await game.contribute(0).invoke()
    '''

    row_states = [ 2**(i) for i in range(32) ]
    nonce = 1
    create_game = signer.build_transaction(
        account, game.contract_address, 'create', row_states, nonce)
    await create_game.invoke()
    (index, id, gen) = await game.newest_game().call()
    im = await game.view_game(id, gen).call()
    view([im])


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
