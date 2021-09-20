# Social Automata
Cellular automata on replicated state machine.
An implementation of Conway's Game of Life as a contract on StarkNet, written
in Cairo.

Players can alter the state of the game, affecting the future of the simulation.
People may create interesting states or coordinate with others to achieve some
outcome of interest.

# Architecture

A contract that holds the state of Conway's Game of life. Players may call the contract,
with an `alter_cell` command. This causes the simulation to progress and for the new state to
be stored.

- Square with side length `dim`, (E.g., dim = 16) containing `dim**2` cells.
- Every cell is in storage as alive or dead.
    - Storage is the costly bottleneck.
    - A row of cells will be stored as a binary number of length `dim` (max `dim` is
    limited to 250 bit due to field size).
    - Each row is stored as a felt in storage. (`dim` storage updates per interaction)
- When the contract is called with `run(rounds, alter_cell)`, it
    1. Runs the simulation for `rounds`.
    2. Applies `alter_cell`, manually giving live to the specified cell(s).
    3. Saves the new state to storage.
- Anyone can call the contract with the `view_game` call which will display the current
saved state of the game.
- Cells wrap around.

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
- Repeat simulation for `rounds`.
- Apply `alter_cell`.
- Recreate the binary representation of each row and save with saved_cells.write(row)


## Example storage

Storage: store 16 rows as binary alive/dead
```
row[0] = 0100110010100101
row[1]
...
row[dim] = 1000110001010100
```
Calling `view_game()` will produce 8 numbers in decimal representation, which
can be rendered as binary (e.g., in the console).

## Parameters

```
dim = 16 (max 250)
cell_count = dim**2 (256)
```

## Dev

### Compile

```
starknet-compile contracts/SocialAutomata.cairo \
    --output contracts/SocialAutomata_compiled.json \
    --abi abi/SocialAutomata_contract_abi.json
```

### Test

```
pytest testing/SocialAutomata_test.py
```

### Deploy

```
starknet deploy --contract SocialAutomata_compiled.json \
    --network=alpha
```
Upon deployment, the CLI will return an address, which can be used
to interact with.

### Interact

CLI - Write
```
starknet invoke \
    --network=alpha \
    --address CONTRACT_ADDRESS \
    --abi SocialAutomata_contract_abi.json \
    --function run \
    --inputs 1 0
```
CLI - Read
```
starknet call \
    --network=alpha \
    --address CONTRACT_ADDRESS \
    --abi SocialAutomata_contract_abi.json \
    --function view_game
```
Or with the Voyager browser [here](https://voyager.online/contract/CONTRACT_ADDRESS#writeContract).

## Notes


