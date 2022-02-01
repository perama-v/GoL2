# Creator

A collection of user-created games with different starting points.

Evolve an existing game to earn a creator credit.

Redeem 10 credits and design a new game.

## Data fetching flow: General Data

Game index: The number used to reference a game (allocated sequentially)
Game generation: The evolutionary stage of a particular game.
Game id: A game hash used internally to check new games are not duplicates.

This version of game indexes all the games. Each game has a
current generation, which can be used to view the current (or
any historical) game state. The game_id is a unique game hash of
the spawn state and is just used for uniqueness checks.

For a given user, one way to get information about games they have
created is with `get_recent_user_data`. A player may have started
multiple games, and these games might be at different generations.
The function allows specification of how many of these games
are desired, and how many states are of interest. E.g., it might be
good to ask for the 5 most recent games, and to get 6 states for each
game. If the player has fewer games or the games have fewer states,
then the result for these will be obvious: empty or unreasonable values (underflows).

```
get_recent_user_data(
    user_address : felt,
    n_games_to_fetch : felt,
    n_gens_to_fetch_per_game : felt
)
```
The function returns how many credits a player has, a array of the
index identifying the games, and an array of the states:
```
# An array of m games with n states per game:
        # game_a: sa sb sc sd
        # game_b: sa sb sc sd
        #. etc.
        # Length = m * n * 32
```

The values returned can be seen, along with descriptions, in the
function in `/contracts/GoL_creator.cairo`.

Another efficient function to get recently made games is:

```
get_recently_created(0)

Returns data about the 5 most recently created games (or nth game
if 0 is replaced by n):
- 1 game index of the latest game to be made (or the one specified).
- 5 current generations of the 5 most recent games.
- 5 owners of those games
- 5 x 32 rows, starting with the most recently created game.
```

A function to get the most recent states of a particular game is:
```
get_recent_generations_of_game(0)

Where 0 will collect the most recent game (or a particular game
if n replaces 0).

Returns:
- 1 The owner
- 5 x 32 rows, starting with the most recent generation for
the specified game.
- 32 rows for the initial state of the specified game.
```

A function to get data for a particular user is:
```
get_user_data(user_address, 0)

This fetches the latest 5 tokens a user owns. Replace 0 with n to
get a particular token at that inventory index (and the preceeding 4)

Returns:
- 1 The number of tokens owned
- 1 The number of credits owned
- 5 The game index for the specified game and preceeding games in
the inventory. Starts with most recent.
- 5 The current generations of those games
- 5 x 32 The rows of those games )
```

Smaller single purpose functions also exist e.g.,

1. See how many games there are by getting the latest index, then
selecting a game index.
2. Select a generation id to view, or use `current_generation_id()`
to retrieve the current generation.
3. Get the current game state with `view_game(id)`. This returns the stored 32 rows for that generation.

### Compilation

Or:
```
nile compile contracts/GoL2_creator.cairo

```

### Test


```
pytest -s test/test_GoL2_creator.py

# or individual tests

pytest -s test/test_GoL2_creator.py::test_function_name
```

### Deploy

```
nile deploy GoL2_creator --alias GoL2_creator --netowrk alpha-goerli
```


## Interact (WIP)

View the spawned game (one-off operation).
```
nile call GoL2_creator view_game 0 0

Returns the spawned Acorn, situated mid-right):
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
Make the zero-address (testing pre-accounts) evolve one generation.
This call can only be made from an account contract. The function
asserts that the calling address is not zero, which means all
calls must originate from an account contract.
```
nile invoke GoL2_creator contribute 0
```
Calling `view_game` again yields the correct next generation:
```
0 0 0 0 0 0 0 0 0 0 0 0 0 118 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Or:
  1110110
      110
       10
```

See how many credits the zero-address has now. This
will return `game_count` (will be zero) and `credit_count`.
```
nile call GoL2_creator user_counts 0

0 1
```
Pull data the zero-th game of the zero-address. This is for testing. This
is the address that is attributed when an account is not used). The
result should be zero.

```
nile call GoL2_creator specific_game_of_user 0 0

0
```
After collecting ten tokens, a user can create as follows. This is
a sparsely populated canvas.

The below call will fail until the user has enough credit.
```
nile call GoL2_creator create 32 0 0 0 0 0 0 0 4194304 4194304 0 0 0 118 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```

# Testnet deployment
```
nile deploy GoL2_creator --alias GoL2_creator --network mainnet
```

## Voyager

Interact using the Voyager browser [here](https://voyager.online/).



