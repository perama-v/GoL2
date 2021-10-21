# Creator

A collection of user-created games with different starting points.

Evolve an existing game to earn a creator credit.

Redeem 10 credits and design a new game.

## Data fetching flow: General Data

This version of game indexes all the games. Each game has a
current generation, which can be used to view the currnent (or
any historical) game state.

1. See how many games there are by getting the latest index, then
selecte a game index.
2. Select a generation id to view, or use `current_generation_id()`
to retrieve the current generation.
3. Get the current game state with `view_game(id)`

This returns the stored 32 rows for that generation.

User data can be fetched to see credit count and any games owned.


### Compilation

Or:
```
starknet-compile contracts/GoL2_creator.cairo \
    --output artifacts/GoL2_creator_compiled.json \
    --abi artifacts/abis/GoL2_creator_contract_abi.json

starknet-compile contracts/account.cairo \
    --output artifacts/account_compiled.json \
    --abi artifacts/abis/account_contract_abi.json
```

### Test


```
pytest -s test/test_GoL2_creator.py

# or individual tests

pytest -s test/test_GoL2_creator.py::test_function_name
```

### Deploy

```
starknet deploy --contract artifacts/GoL2_creator_compiled.json \
    --network=alpha

Deploy transaction was sent.
Contract address: 0x07dd3c84222f069581d928d9a25ad506be696920e1268a957a0ff568ec0930f5
Transaction ID: 295422

starknet tx_status --network=alpha --id=295422

starknet deploy --contract artifacts/account_compiled.json \
    --network=alpha

Contract address: ACCOUNT_ADDRESS
```


## Interact (WIP)

Spawn the game (one-off operation).
```
starknet invoke \
    --network=alpha \
    --address 0x07dd3c84222f069581d928d9a25ad506be696920e1268a957a0ff568ec0930f5 \
    --abi artifacts/abis/GoL2_creator_contract_abi.json \
    --function spawn

Invoke transaction was sent.
Contract address: 0x07dd3c84222f069581d928d9a25ad506be696920e1268a957a0ff568ec0930f5
Transaction ID: 295426
```
View the game state (as a list of 32 binary-encoded values).
```
starknet call \
    --network=alpha \
    --address 0x07dd3c84222f069581d928d9a25ad506be696920e1268a957a0ff568ec0930f5 \
    --abi artifacts/abis/GoL2_creator_contract_abi.json \
    --function view_game \
    --inputs 0 0

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
Make the zero-address (testing pre-accounts) evolve one generation:
```
starknet invoke \
    --network=alpha \
    --address 0x07dd3c84222f069581d928d9a25ad506be696920e1268a957a0ff568ec0930f5 \
    --abi artifacts/abis/GoL2_creator_contract_abi.json \
    --function contribute \
    --inputs 0

Invoke transaction was sent.
Contract address: 0x07dd3c84222f069581d928d9a25ad506be696920e1268a957a0ff568ec0930f5
Transaction ID: 295433
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
starknet call \
    --network=alpha \
    --address 0x07dd3c84222f069581d928d9a25ad506be696920e1268a957a0ff568ec0930f5 \
    --abi artifacts/abis/GoL2_creator_contract_abi.json \
    --function user_counts \
    --inputs 0

0 1
```
Pull data the zero-th game of the zero-address. This is for testing. This
is the address that is attributed when an account is not used). The
result should be zero.

```
starknet call \
    --network=alpha \
    --address 0x07dd3c84222f069581d928d9a25ad506be696920e1268a957a0ff568ec0930f5 \
    --abi artifacts/abis/GoL2_creator_contract_abi.json \
    --function specific_game_of_user \
    --inputs 0 0

0
```
After collecting ten tokens, a user can create as follows. This is
a sparsely populated canvas.

```
starknet invoke \
    --network=alpha \
    --address 0x07dd3c84222f069581d928d9a25ad506be696920e1268a957a0ff568ec0930f5 \
    --abi artifacts/abis/GoL2_creator_contract_abi.json \
    --function create \
    --inputs 32 0 0 0 0 0 0 0 4194304 4194304 0 0 0 118 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Invoke transaction was sent.
Contract address: 0x07dd3c84222f069581d928d9a25ad506be696920e1268a957a0ff568ec0930f5
Transaction ID: 295448
```


## Voyager

Interact using the Voyager browser [here](https://voyager.online/contract/0x07dd3c84222f069581d928d9a25ad506be696920e1268a957a0ff568ec0930f5).



