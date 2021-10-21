# Frontend specification for StarkNet-based Game of Life

### Project title

GoL2

Game of Life, a Game on L2.

## Project description

A website for viewing and interacting with a blockchain-based
implementation of Conway's Game of Life.

Background (inspiration) material: https://playgameoflife.com/lexicon/acorn

## Game outline

There are two modes: Infinite and Creator.

## Game mechanics outline

The game mechanics follow the standard rules of
[Conways' Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life).
The game progresses deterministically, which allows for the frond end
to compute game states for past and future generations based on
simple rules.

There are two additional factors that differ from most standard
implementations:

- The game grid is not infinite, a cell at the left of the grid is
has a left-hand neighbour that is a cell on the right hand side of
the gride along the same row. The same applies to top-bottom edges.
- Players may perform a manual intervention to make one cell in the
become alive.

## Visual style:

Elements of the website should include:

- A 32x32 grid containing two types of cells (alive/dead).
- Buttons for navigation and interaction.
- A less prominent text description containing information about the
game.

## Data source

Data can be called from a frontend using a javascript SDK that
talks to a StarkNet provider (similar to ethers.js. Implementation
pending). StarkNet contracts can be called to retrieve game state
which is stored in the game contract and exposed via helper functions.
See the frontend spec for the functions available for each game mode.

The main structure for the data query is to have game state be
retrievable by indices. Fetching the current index allows the current
state to be queried, as well as previous states by working backward
does the indices.


The data query functions are idendified in the contract by the
`@View` decorator.

To alter the state of a contract, functions with the `@External`
decorator are called. This does not return any values immediately
because the transaction must be included in a StarkNet block.

The account model of StarkNet is such that each user will have a
personal account contract. The account contract is sent the payload
for the transaction, and it will verify the signature before
calling the game contract.

More about accounts van be seen [here](https://perama-v.github.io/cairo/examples/test_accounts/).

## Game grid data format

The game is emitted with a binary encoding, with one number per
row in the game. Each bit (starting with the least significant bit)
represents a columns (e.g. the first bit represents column zero).

The 32x32 cell grid may be constructed from the presence of a `1`
(alive cell in blue) or a `0` (dead cell in grey).


## Animation

The game visual style aims to mimic a simple organism that is
breeding/spreading/dying. The game state may be displayed as
a sequence of recent states in order to create this effect.

One possibility is that on arrival to the game, the first image is
a state 5-10 generations old. The frames might progress at a rate
of 0.5-1 frames per second until the current state is reached. That
image may then persist for some time (e.g., 5-10 seconds), showing
the visitor that this is the most recent state. Then the sequence
may be repeated until the user takes some action.

The contract will arrive at new states by computing the new states
using the rules of the game.

The state update is allowed to progress
multiple generations in a single player turn.

Therefore, when the contract emits an Event containing the new state
and the `generation_id`, the front-end may progress the interface
in an animation, stepping through the intermediate steps of the game
Until the final state is reached.


## Branding and theme:

StarkNet colour scheme may be applied to the

- Alive cell colour: StarkNet Blue (Hex code "#28286E")
- Dead cell colour: A pale grey.
- Single cell manually given life: StarkNet Orange (Hex code "F6643C")

Logos indicating the underlying technologies should be displayed
at the bottom of the page.

- StarkNet logos are available in this
[media package](https://drive.google.com/drive/folders/101RtufQ_DwE1F2skbmyaywDJ1po80QCk)
- Ethereum logos e.g., "ETH logo landscape (gray)" are available in
this [media package](https://ethereum.org/en/assets/)



