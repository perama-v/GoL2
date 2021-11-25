# Infinite

A long running game of collaboration.

Evolve the game to claim a state and earn a credit to give-life.

Redeem a give-life credit and make a cell become alive.

## Data fetching flow: General Data Method 1

This function is the most flexible for collecting data:

```
get_arbitrary_state_arrays(
    gen_ids_array_len : felt,
    gen_ids_array : felt*,
    n_latest_states : felt,
    give_life_array_len : felt,
    give_life_array : felt*,
    n_latest_give_life : felt
)
```

The values returned can be seen, along with descriptions, in the
function in `/contracts/GoL_infinite.cairo`.

The use case is to be able to specify known gaps in knowledge, as
well as harvest recent data going back some specified distance from
the most recent state.

For example, if the front end currently has game states up to
generation 70 and knows about give life actions up to index 30.

The frontend knows that the game generation should be more than 80,
but is not sure how much beyond that.

```
nile call GoL2_infinite get_arbitrary_state_arrays \
    10 \  # Get ten specific missing gens.
    71 72 73 74 75 76 77 78 79 80 \  # Specify them.
    15 \  # Get the fifteen latest generations.
    5  \  # Get five specific give_live events.
    31 32 33 34 35  \ # Specify them.
    12 \  # Get the 12 latest give_life events.

Or as one line:
nile call GoL2_infinite get_arbitrary_state_arrays 10 71 72 73 74 75 76 77 78 79 80 15 5 31 32 33 34 35 12 --network mainnet
```
Keep in mind that the return function also passes the lengths
of arrays (see the actual function). Game states are returned
as 32-length arrays. Skipping those details,
this will return:

- Current generation the game is up to.
- Array of states specifically requested.
- Array of their owners.
- Array of n recent states.
- Array of their owners.
- Index of the latest give_life credit redemption event.
- Array of give life results specifically requested. Includes:
    - `[redemption_index, id_minted, id_used, row, col, owner]`
- Array of n recent give life results. (Same format as above)


## Data fetching flow: General Data Method 2

This version of game has generation ids that progress continuously.
A user may play the game which always progresses the generations by
one. The player is then recorded as owning that generation, which
is represented by a 'token' inside the contract, whose ID matches
the generation it was minted in.

The simplest way to get the current game data is with:

```
latest_useful_state(0)

Returns:
- 1 Current (or specified) generation ID.
- 1 The latest index of redeemed give life actions.
- 1 The owner of the current (or specified) generation 'A'.
- 1 The owner of preceeding generation 'B'.
- 1 The owner of generation 'C'.
- 50 The details of ten most recently redeemed tokens.
    - Token id, redemption generation, row index, col index, owner.
- 32 The rows of generation 'A'.
- 32 The rows of generation 'B'.
- 32 The rows of generation 'C'.
```
The above result includes the game generation, ten most recent claimed
tokens, and the three most recent game states. The `0` will cause
the function to return the most recent generation. A specific game
generation can be specified instead and it will work backward from that
point (that generation and the preceeding two, redeemed tokens from
that generation and earlier).

Alternatively, individual game states can be inspected.

1. Select a generation id to view, or use `current_generation_id()`
to retrieve the current generation.
2. Get the current game state with `view_game(id)`

This returns the stored 32 rows for that generation.

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
starknet-compile contracts/GoL2_infinite.cairo \
    --output artifacts/GoL2_infinite_compiled.json \
    --abi artifacts/abis/GoL2_infinite_contract_abi.json

starknet-compile contracts/account.cairo \
    --output artifacts/account_compiled.json \
    --abi artifacts/abis/account_contract_abi.json
```

### Test


```
pytest -s test/test_GoL2_infinite.py

# or individual tests

pytest -s test/test_GoL2_infinite.py::test_game_flow
```

### Deploy

```
nile deploy GoL2_infinite --alias GoL2_infinite

```
TODO - Integrate account

## Interact

View the spawned game.
```
nile call GoL2_infinite view_game 1
```

Returns the spawned Acorn, situated mid-right):
```
0 0 0 0 0 0 0 0 0 0 0 0 32 8 103 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Which decoded as bin(32), bin(8) and bin(103) take the acorn form:
   100000
     1000
  1100111

This can be rendered in different styles, for example:

. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . ■ . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . ■ . . .
. . . . . . . . . . . . . . . . . . . . . . . . . ■ ■ . . ■ ■ ■
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .


```
Make user 1 (testing pre-accounts) evolve one generation:
```
nile invoke GoL2_infinite evolve_and_claim_next_generation 1
```
Calling `view_game` again yields the correct next generation:
```
nile call GoL2_infinite view_game 2

0 0 0 0 0 0 0 0 0 0 0 0 0 118 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Or:
  1110110
      110
       10
```

See how many tokens user 1 has now:
```
nile call GoL2_infinite user_token_count 1
```
Pull data about their token(s) using the index of each token. E.g., index 0 will access
the first token for this user. The data returned is: `(token_id, has_used_give_life, generation_during_give_life, alive_cell_row, alive_cell_col)`.

```
nile call GoL2_infinite get_user_data 1 0

2 0 0 0 0
```
So this user has token_id 2, indicating that it represents generation 2, the
very next step after the acorn (generaion 1). The other fields indicate it
has not yet been used to give life.

Make, for user 1, a particular cell (row index `9` and column index `9`) become alive,
specifying that token id 2 is being redeemed.


This invoke call (and all invoke calls) can only be made from an account
contract. The function
asserts that the calling address is not zero, which means all
calls must originate from an account contract.
```
nile invoke GoL2_infinite give_life_to_cell 1 9 9 2

```
We can check the current game generation:
```
nile call GoL2_infinite current_generation_id

2
```
Thus, there has been one turn and the current generation is 2, as expected.
The generation can be used to view the game:
```
nile call GoL2_infinite view_game 2

Returns the addion of a single cell at the tenth row/col:
0 0 0 0 0 0 0 0 0 4194304 0 0 0 118 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Tenth row: 00000000010000000000000000000000
```
This single cell would die out in the next generation, and so would not be a
wise placement, unless other cells are placed in adjacent locations.

Confirm this by having user 23 have a turn, evolving 1 generation:
```
nile invoke GoL2_infinite evolve_and_claim_next_generation 23

```
Then check that the isolated cell has died, first we can check that
the game is correctly at generation 3. Expected: generation 3
(spawn=1, then +1 got to 2, then +1 makes 3).
```
nile call GoL2_infinite latest_useful_state 0

2 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 118 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 32 8 103 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```
The above result includes the game generation, ten most recent claimed
tokens, and the three most recent game states.

Fetch the image of multiple generations
```
nile call GoL2_infinite get_arbitrary_state_arrays 3 1 2 3

3 96 0 0 0 0 0 0 0 0 0 0 0 0 32 8 103 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 4194304 0 0 0 118 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 32 46 41 6 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```
TODO add user data to the multi-generation getter above if needed.

# Testnet deployment
```
nile deploy GoL2_infinite --alias GoL2_infinite --network mainnet
```

## Voyager

Interact using the Voyager browser [here](https://voyager.online/).



