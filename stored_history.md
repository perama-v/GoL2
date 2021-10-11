# State exposure

An experiment, playing with increased storage to reduce dependency
on other system components. The game could potentially launch and
later upgrade to a lower-storage model.

The final system is planned to make use of:

- account (pending implementation)
- Events

In the meantime, some helper storage has been added to the game
that can be accessed with `@view` functions. The entire game is
stored on chain. Any token can be minted later using the stored
historical state. Instead the game maps the historical states to
a user's account ID/address.

This could also perhaps later upgrade to use volition for state
availability?

## Data fetching flow: General Data

The game has generations. Each has an index and an id.
The index is based on turns while the id is evolution steps.
A player always increases the index by one, but the generation
may progress more than one. The id's can be found by walking
along the indices.

1. Select a generation id to view using the functions:

    - `current_generation_id()` to get the latest.
    - `generation_index_from_id(id)` to see what index an id has.
    - `generation_id_from_index(index)` to get any id by index.
2. Get the current game state with `view_game(id)`

This returns the stored 32 rows for that generation.
By calling for sequential indices the historical game state can
be reconstructed in a database.

This enables the steps within one turn to be animated using the rules
of life.

Any historical state automatically includes the cells that were manually
given life. To see which cells were manually altered, the give_life
actions are all indexed and can be fetched.

1. Get the most recent index `latest_give_life_index()`
2. Fetch the token_id for that index
`token_id_from_redemption_index(token_id)`
3. Fetch the data for that token to get the row/col `get_token_data()`
4. By fetching and saving all the redemptions, the give_live actions
can be used to display these cells as orange in the generation they
are given-life, and blue at other times they are alive.


## Data fetching flow: Specific User Data

The tokens are represented inside the contract and have a token_id
equal to the generation_id in which they were minted.

The contract stores if and when a token is redeemed in a give_life act.

1. Get the address of the Account contract of the user. (user_id)
2. Call the `user_token_count(user_id)` to see all the tokens owned by a user.
3. Fetch the details of each token using the
`get_user_data(user_id, nth_token_of_user)` method. This returns when
the token was minted (token_id), whether it has been redeemed, and if so, when/where.
The token_id can be used to get the redemption index with
`redemption_index_from_token_id(token_id)` if needed.


### Compilation

Or:
```
starknet-compile contracts/GoL2_stored_history.cairo \
    --output contracts/GoL2_stored_history_compiled.json \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json

starknet-compile contracts/account.cairo \
    --output contracts/account_compiled.json \
    --abi artifacts/abis/account_contract_abi.json
```

### Test


```
pytest -s test/test_GoL2_stored_history.py

# or individual tests

pytest -s test/test_GoL2_stored_history.py::test_game_flow
```

### Deploy

```
starknet deploy --contract contracts/GoL2_stored_history_compiled.json \
    --network=alpha

Deploy transaction was sent.
Contract address: 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db
Transaction ID: 262821

starknet tx_status --network=alpha --id=262821

starknet deploy --contract contracts/account_compiled.json \
    --network=alpha

TODO - Integrate account
```


## Interact

Spawn the game (one-off operation).
```
starknet invoke \
    --network=alpha \
    --address 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json \
    --function spawn

Invoke transaction was sent.
Contract address: 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db
Transaction ID: 262844
```
View the game state (as a list of 32 binary-encoded values).
```
starknet call \
    --network=alpha \
    --address 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json \
    --function view_game \
    --inputs 1

Returns the spawned Acorn, situated mid-right):
0 0 0 0 0 0 0 0 0 0 0 0 32 8 103 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Which decoded as bin(32), bin(8) and bin(103) take the acorn form:
   100000
     1000
  1100111
```
Make user 1 (testing pre-accounts) evolve one generation:
```
starknet invoke \
    --network=alpha \
    --address 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json \
    --function evolve_and_claim_next_generation \
    --inputs 1

Invoke transaction was sent.
Contract address: 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db
Transaction ID: 262846
```
Calling `view_game` again yields the correct next generation:
```
0 0 0 0 0 0 0 0 0 0 0 0 0 118 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Or:
  1110110
      110
       10
```

See how many tokens user 1 has now:
```
starknet call \
    --network=alpha \
    --address 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json \
    --function user_token_count \
    --inputs 1

1
```
Pull data about their token(s) using the index of each token. E.g., index 0 will access
the first token for this user. The data returned is: `(token_id, has_used_give_life, generation_during_give_life, alive_cell_row, alive_cell_col)`.

```
starknet call \
    --network=alpha \
    --address 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json \
    --function get_user_data \
    --inputs 1 0

2 0 0 0 0
```
So this user has token_id 2, indicating that it represents generation 2, the
very next step after the acorn (generaion 1). The other fields indicate it
has not yet been used to give life.

Make, for user 1, a particular cell (row index `9` and column index `9`) become alive,
specifying that token id 2 is being redeemed.

```
starknet invoke \
    --network=alpha \
    --address 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json \
    --function give_life_to_cell \
    --inputs 1 9 9 2

Invoke transaction was sent.
Contract address: 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db
Transaction ID: 262847
```

We can check the current game generation:
```
starknet call \
    --network=alpha \
    --address 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json \
    --function current_generation_id
2
```
Thus, there has been one turn and the current generation is 2, as expected.
The generation can be used to view the game:
```
starknet call \
    --network=alpha \
    --address 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json \
    --function view_game \
    --inputs 2

Returns the addion of a single cell at the tenth row/col:
0 0 0 0 0 0 0 0 0 4194304 0 0 0 118 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Tenth row: 00000000010000000000000000000000
```
This single cell would die out in the next generation, and so would not be a
wise placement, unless other cells are placed in adjacent locations.

Confirm this by having user 23 have a turn, evolving 1 generation:
```
starknet invoke \
    --network=alpha \
    --address 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json \
    --function evolve_and_claim_next_generation \
    --inputs 23

Invoke transaction was sent.
Contract address: 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db
Transaction ID: 262849
```
Then check that the isolated cell has died, first we can check that
the game is correctly at generation 3. Expected: generation 3
(spawn=1, then +1 got to 2, then +1 makes 3).
```
starknet call \
    --network=alpha \
    --address 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json \
    --function current_generation_id
3
```
Then call for the image:
```
starknet call \
    --network=alpha \
    --address 0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db \
    --abi artifacts/abis/GoL2_stored_history_contract_abi.json \
    --function view_game \
    --inputs 3
```


## Voyager

Interact using the Voyager browser [here](https://voyager.online/contract/0x06dd56f17fba09c62d9a1f3542f184de7b157eb178b13661d7d9ed44f977d1db).



