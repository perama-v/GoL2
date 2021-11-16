
import os
import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet
from utils.Signer import Signer

NUM_SIGNING_ACCOUNTS = 2
DUMMY_PRIVATE = 12345678987654321
signers = []

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
    game = await starknet.deploy("contracts/GoL2_creator.cairo")

    return starknet, game, accounts


@pytest.mark.asyncio
async def test_create(game_factory):
    # Start with freshly spawned game
    _, game, accounts = game_factory

    # First generate 10 credits by progressing another game.
    response = await game.newest_game().call()
    (first_index, first_game_id, newest_gen) = response.result

    N_CONTRIB = 10
    for i in range(N_CONTRIB):
        print(f'Done with {i}')

        await signers[0].send_transaction(
            account=accounts[0],
            to=game.contract_address,
            selector_name='contribute',
            calldata=[first_game_id])

    # Make sure credits were given.
    response = await game.user_counts(
            accounts[0].contract_address).call()
    (game_count, credit_count) = response.result
    assert game_count == 0
    assert credit_count == N_CONTRIB

    # Redeem credits
    row_states = [ 2**(i) for i in range(32) ]

    await signers[0].send_transaction(
        account=accounts[0],
        to=game.contract_address,
        selector_name='create',
        calldata=[row_states])


    # Check that the user has a game.
    response = await game.specific_game_of_user(
        accounts[0].contract_address, 0).call()
    assert response.result.game_index == first_index + 1

    # Check that the game was recorded as the latest game.
    response = await game.newest_game().call()
    index = response.result.game_index
    assert index == first_index + 1

    im = await game.view_game(index, 0).call()
    view([im])
    print('Above is the newly created game')

    response = await game.generation_of_game(first_index).call()
    gen = response.result.generation
    im = await game.view_game(first_index, gen).call()
    view([im])
    print('Above is the first game after being progressed 10 times.')

    # Test harvesting functions
    recent_games = await game.get_recently_created(0).call()
    recent_generations = await game.get_recent_generations_of_game(0).call()
    user_data = await game.get_user_data(accounts[0].contract_address, 0).call()

    print(recent_games.result)
    print(recent_generations.result)
    print(user_data.result)


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
