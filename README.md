# Social Automata

Cellular automata on replicated state machine.
An implementation of Conway's Game of Life as a contract on StarkNet, written
in Cairo, with an interactive element.

Players can alter the state of the game, affecting the future of the simulation.
People may create interesting states or coordinate with others to achieve some
outcome of interest.

This implementation is novel in that the game state shared (agreed by all) and permissionless
(anyone may participate). The game rules are enforced by a validity proof, which means that
no one can evolve the game using different rules.

There are three rules in this implementation:

- The normal rules of Conways' Game of Life (3 to revive, 2 or 3 to stay alive).
- The boundaries wrap - a glider may travel infinitely within the confines of the grid.
- A user who plays gains a special power - to revive a single cell at their discretion.

The game may flourish and produce a myriad of diverse game states, or it may fall to ruin and
become a barren wasteland. It will be up to the participants to decide if and when to use
their life-giving power. What will become of the

|Acorn generation 0|Acorn generation 1|
|:--: | :--:|
| ![acorn-0](img/acorn_0.png)| ![acorn-0](img/acorn_1.png) |

# Architecture

A contract that holds the state of Conway's Game of Life. Players may call the contract,
with an `alter_cell` command. This causes the simulation to progress and for the new state to
be stored.

- Square with side length `dim`, (E.g., dim = 16) containing `dim**2` cells. Cells wrap around
edges.
- Every cell is in storage as alive or dead.
    - Storage is the costly bottleneck.
    - A row of cells will be stored as a binary number of length `dim` (max `dim` is
    limited to 250 bit due to field size).
    - Each row is stored as a felt in storage. (`dim` storage updates per interaction)
- When the contract is called with `evolve_generations(number_of_generations)`, it
    1. Runs the simulation for `number_of_generations`.
    2. Saves the new state to storage.
    3. Saves the generation.
    4. Issues an `Warden` NFT to the player.
- Anyone can call the contract with the `view_game` call which will display the current
saved state of the game.
- Anyone with a `Warden` token may call `give_life_to_cell` once per token to
revive a chosen cell.

## Operation

- A user calls `run()`.
- Initialization: A `cell_states` array is created to hold the state of all the cells
(length `dim**2`):
    1. Iterate over `dim` to access rows by index indices)
    2. Call `saved_cells.read(row)` to get binary representation of state (for each row).
    3. For each bit, save it as a felt to the array.
        - Use a mask for each column: `state[dim*row + column] = bitwise_and(row, 2**column)`)
        - At the end of the contract call the state will be converted back to binary
        representation for storage.
- Simulation: A `next_state` array is made to hold the values during evaluation.
    1. Iterate over all cells (``dim**2``).
    2. For each cell check and sum all 8 neighbours, apply life rule and save alive/dead (`0/1`).
    3. Save result to `next_state` array.
    4. After final cell is read, change the array to point at the new neighbour array
    `cell_states=next_state`.
- Repeat simulation for `number_of_generations`.
- Recreate the binary representation of each row and save with `saved_cells.write(row)`.
- Issue a `warden` token to the user. The token has a generation ID that is tied
to the history of the game. The events emitted by the game contract will contain
the generation ID and the image of the game at the end of that turn. In this way,
the token bears the image that they helped create during the current turn
(as an artistic memento).
- An event is emitted, containing the tokenID of the user and the number of steps progressed. Listening to this event will allow the offchain animation of the game
for a UI (e.,g the intervening steps may be inferred from the rules of the game
and any known `give_life()` events).

In another operation, the user may use their token:

- A user calls  `give_life(row_index, col_index)`.
- The current row is read from storage.
- The column is applied with a bitwise AND mask to the row.
- The row is saved to storage.
- An event is emitted containing the altered cell and the users tokenID.

## Token contract ownership model

The game contract is the `only_owner` of the token contract - the mint
function can only be called by the game contract.

When the game contract `spawn` function is called, the address of the
token contract is passed as an argument. The `spawn` function calls
`initialize` on the token contract. This causes the token contract
to store the address of the calling contract (the game contract) as
the owner. From then onwards, the game contract may mint a token
for a player at will.

When the game contract mints a token for a player it will pass the
account address of the player to the token contract. The token
contract records their address as the owner for that token.

## Example storage

Storage: store `DIM` rows as binary alive/dead
```
row[0] = 01001100101001010100110010100101   (as a felt: 1285901477).
row[1]
...
row[dim] = 10001100010101001001010100110010   (as a felt: 2354353458).
```
Calling `view_game()` will produce `dim` numbers in decimal representation, which
can be rendered as binary (e.g., in the console).

## Parameters

```
dim = 32 (max 250)
cell_count = dim**2 (e.g., 1024 cells if DIM=32)
```

## Dev

    pip install cairo-nile

Install Cairo-lang (e.g., 0.4.1)

    nile install 0.4.1

### Compile

    nile compile

Or:
```
starknet-compile contracts/GoL2.cairo \
    --output contracts/GoL2_compiled.json \
    --abi artifacts/abis/GoL2_contract_abi.json
```

### Test

(not currently set up with `nile test`)
```
pytest -s test/GoL2_test.py
```

### Deploy

```
starknet deploy --contract contracts/GoL2_compiled.json \
    --network=alpha
```
Upon deployment, the CLI will return an address, which can be used
to interact with.

### Interact

Spawn the game (on-off operation).
```
starknet invoke \
    --network=alpha \
    --address 0x03f22c2e44761c7b690acf81db6c46b781bf0de7fb9fc0b2ae4c2367183093b4 \
    --abi artifacts/abis/GoL2_contract_abi.json \
    --function spawn
```
View the game state (as a list of 32 binary-encoded values).
```
starknet call \
    --network=alpha \
    --address 0x03f22c2e44761c7b690acf81db6c46b781bf0de7fb9fc0b2ae4c2367183093b4 \
    --abi artifacts/abis/GoL2_contract_abi.json \
    --function view_game

Returns the spawned Acorn, situated mid-right):
0 0 0 0 0 0 0 0 0 0 0 0 32 8 103 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Which decoded as bin(32), bin(8) and bin(103) take the acorn form:
   100000
     1000
  1100111
```
Run for one generation.
```
starknet invoke \
    --network=alpha \
    --address 0x03f22c2e44761c7b690acf81db6c46b781bf0de7fb9fc0b2ae4c2367183093b4 \
    --abi artifacts/abis/GoL2_contract_abi.json \
    --function run \
    --inputs 1
```
Calling `view_game` again yields the correct next generation:
```
0 0 0 0 0 0 0 0 0 0 0 0 0 118 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Or:
  1110110
      110
       10
```

Make a particular cell (row index `9` and column index `9`) become alive
(not yet metered by token-authority).
```
starknet invoke \
    --network=alpha \
    --address 0x03f22c2e44761c7b690acf81db6c46b781bf0de7fb9fc0b2ae4c2367183093b4 \
    --abi artifacts/abis/GoL2_contract_abi.json \
    --function give_life_to_cell \
    --inputs 9 9

Returns the addion of a single cell at the tenth row/col:
0 0 0 0 0 0 0 0 0 4194304 0 0 0 118 6 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

Tenth row: 00000000010000000000000000000000
```
This single cell would die out in the next generation, and so would not be a
wise placement, unless other cells are placed in adjacent locations.

## Voyager

Interact using the Voyager browser [here](https://voyager.online/contract/0x03f22c2e44761c7b690acf81db6c46b781bf0de7fb9fc0b2ae4c2367183093b4).

---

# Notes

- Todo
    - Think about how the game will be rendered. Could have a basic python
    script to draw the grid in the command line as a start. Currently have the grid-based representation implemented in `pytest`.
    - Think about which/where events are best utilized.
    - Connect to user authentification
    - Implement ERC-721 to hold the unique 'receipt of participation'
    - Restrict the `give_life_to_cell` function to token holders only and
    restrict quantity of this action per person.
