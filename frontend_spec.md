# Frontend specification for StarkNet-based Game of Life

### Project title

TBC

```
WIP Title ideas:
    - Something desert-based (GoL is life-or-death)
        - Eastern Deserts (Near Cairo: Eastern desert).
        - New Desert
        - People's Desert
    - Social Automata (perhaps not fun enough)
    - Shared Game of Life
    - CellNet
    - Cairows
    - GOL2 (Game of L2)
```
## Project description

A single-page website for viewing and interacting with a blockchain-based
implementation of Conway's Game of Life.

Background (inspiration) material: https://playgameoflife.com/lexicon/acorn

A user will be able to:

- Visit the site to view the current state of the game.
- Watch the game progress as the game contract is updated.
- Explore previous states of the game.
- Connect a wallet and send a transaction to StarkNet to influence
the future of the game state in one of two ways:
    - Progress the game by a chosen number of generations.
    - Manually affect one cell in the game.
- Connect a wallet and see any token-receipts of their participation.
    - Each token is a tied to a historical game state.
    - A token may be rendered in the same way as the main game state.
    - If a user has multiple tokens, each is viewable.

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

The website will be run on a server that maintains a connection
to a StarkNet node. The node maintains the
state of the StarkNet network and will monitor for changes to a
particular set of contracts specific to the game. The website server
will listen for messages from the node and use that information
to change the display.

```
TBC: Specifics of web-server and node-server architecture.
```

## Source of state updates

The website will listen for `Events` that are emitted by specific
contracts in StarkNet.
The events contain information that is used to update the
content of the page.

The state updates from `Events` fall into two categories:

- `global_events`, common to all visitors of the site.
    - Events from the game contract.
- `user_events`, unique to the address of the connected wallet.
    - Token-related events.

The `global_events` include:

- `new_state`. The game has been evolved by a user.
- `live_given`. A single cell has been altered by a user.

The `user_events` include:

- `token_owner`. The address of the connected wallet is used to
determine which token(s) the user owns.

## Game grid data format

The game is emitted with a binary encoding, with one number per
row in the game. Each bit (starting with the least significant bit)
represents a columns (e.g. the first bit represents column zero).

The 32x32 cell grid may be constructed from the presence of a `1`
(alive cell in blue) or a `0` (dead cell in grey).

## Interactive features

A minimum set of buttons must include:

- `connect_wallet`
- `view_game`
- `view_tokens`
- `evolve_game`
- `give_life`
- `explore_game`

The function of each button is as follows:

### Button: `connect_wallet`
```
TBC - supported wallet list. E.g., Wallet-Connect, Metamask.
```
### Button: `view_game`

This displays the main game at the most up to date state.

### Button: `view_tokens`

This shows a collection of tokens that the user created by previoulsy
participating in evolving the game.

### Button: `evolve_game`

This allows the user to progress the game a chosen number of steps.
It will involved the creation of a transaction that is then passed
to the wallet. The user will sign the transaction and the wallet
will submit the transaction to StarkNet via that connected StarkNet
node.
```
TBC: Creation of correctly formatted transaction for signing by wallet.
```

### Button: `give_life`

This allows the user to select a cell to give life to, which is
a specific cell of interest to the player.

Options include:

    - Allow the user to hover-and-click on the grid over the current
up-to-date game state.
    - Allow the user to type a row and column index, which then
    is visually confirmed by the display.

The user must select a cell in the grid, the page then creates
a transaction that is then passed to the wallet. The user will
sign the transaction and the wallet
will submit the transaction to StarkNet via that connected StarkNet
node.
```
TBC: Creation of correctly formatted transaction for signing by wallet.
```

### Button: `explore_game`

This button allows the navigation of preious game states.
This might include:

- A button to play game history from the start to the current state.
This could included a slider for altering the speed of the display.
- A left arrow for going to older states.
- A right arrow for going to newer states.
- Historical states have a `generation_id`, which can be displayed.
- A button to display a sequential list of cells that were manually
given life, or an on/off toggle to highlight these cells during
exploration of historical states.

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
```
TBC: To save the front-end from having to implement the game, the
contract could also emit the intermediate game states. Perhaps site
caches past states server-side for quick navigation.
```

## Branding and theme:

StarkNet colour scheme may be applied to the

- Alive cell colour: StarkNet Blue (Hex code "#28286E")
- Dead cell colour: A pale grey.
- Single cell manually given life: StarkNet Orange (Hex code "F6643C")

Logos indicating the underlying technologies should be displayed
at the bottom of the page.

- StarkNet logos are available in this [media package](https://drive.google.com/drive/folders/101RtufQ_DwE1F2skbmyaywDJ1po80QCk)
- Ethereum logos e.g., "ETH logo landscape (gray)" are available in
this [media package](https://ethereum.org/en/assets/)

## Social media:

A button to tweet (or copy-to-tweet) a preformatted message with an image,
some text and a link to the site.

Option 1:

- Image
    - The current game state
- Text
    - "A shared and collaborative Game of Life as a Cairo contract on StarkNet."
- Site link (url)

Option 2:

- Image
    - The state associated with one of the tokens of the user.
- Text
    - "I helped evolve the Game of Life on StarkNet. Join us and shape the future!"
- Site link (url)


