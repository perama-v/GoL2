# Frontend specification for StarkNet-based Game of Life

### Project title

GoL2

Game of Life, a Game on L2.

## Project description

A website for viewing and interacting with a blockchain-based
implementation of Conway's Game of Life.

Background (inspiration) material: https://playgameoflife.com/lexicon/acorn

## Game outline

There are two modes:


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

## Game progression

To 'play' a user sends a transaction to evolve the game of life.
They may choose to evolve it one generation, or multiple generations,
with a cap at some number (e.g., maximum 5 or 10 generations).

Several players might sequentially create the following scenario from
the starting generation (gen_1):

- Game_spawn: gen_1 (the acorn)
- Alice: gen_2 (acorn +1)
- Bob: gen_3 (acorn +2)
- Carol: gen_7 (acorn +6)
- Dave: gen_8 (acorn +7)

The action of Carol was to evolve by 4 generations, bringing the state
to generation 7. She mints a single token (ID 7) just like the other players.

The second aspect of 'play' is to manually alter one cell. This does not
increase the generation, and can only be performed by redeeming an
existing game token. In the example below, Alice and Bob revive adjacent
cells before Elle's turn. Elle evolves 1 then Fred evolves 6.

- Game_spawn: gen_1 (the acorn)
- Alice: gen_2 (acorn +1)
- Bob: gen_3 (acorn +2)
- Carol: gen_7 (acorn +6)
- Dave: gen_8 (acorn +7)
- Bob: revive (row=4, col=5) gen_8 (acorn +7 with one revived cell)
- Alice: revive (row=3, col=5) gen_8 (acorn +7 with two revived cells)
- Elle: gen_9 (two-cells-revived state above +1)
- Fred: gen_15 (gen_9 +6)

The game has now diverged from the generic Acorn state through the actions
of Alice and Bob.

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

The contract will be sent transactions that change the state.
The plan for the final architecture is to have a system that is very
close to the Event-listener model that Ethereum contracts have.

At the moment, Events are not available. The frontend can currently
access the contract state by calling a `@View` function to retrieve state
from storage.

The user sends their transaction as an `@External` function.
This does not return any values immediately because the transaction
must be mined.

A server looking to build up the state of the game could look
at the transactions that have been included in blocks and independently
recreate the game state by replaying the same actions.

The current game state is stored in the contract and can be fetched
with the `@View` function `view_game()`, which returns 32 numbers,
each representing the 32 column states for one row. This can be used to
corroborate with the independently-generated game state.

```
TBC: Specifics of web-server and node-server architecture.

Currently the StarkNet node is being built.
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

This allows the website to know the account address of the user. The
address is used to find the game tokens they own and display them.
```
TBC - supported wallet list. E.g., Wallet-Connect, Metamask.

While wallet integration is pending a 'connect_address' button can be
used where the user manually pastes their address.
```
### Button: `view_game`

This displays the main game at the most up to date state.

### Button: `view_tokens`

This shows a collection of tokens that the user created by previously
participating in evolving the game.

### Button: `evolve_game`

This allows the user to progress the game a chosen number of steps.
It will involved the creation of a transaction that is then passed
to the wallet. The user will sign the transaction and the wallet
will submit the transaction to StarkNet via that connected StarkNet
node.
```
TBC: Creation of correctly formatted transaction for signing by wallet.

Fallback: While wallet integration is pending, the interface could produce some
text that the user could submit, such as through the StarkNet CLI or Voyager
explorer.
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

Fallback: Same as for 'evolve_game' button.
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

## Token

A token represents a static snapshot in the history of the game. It has
multiple purposes:

    - An record of evolution participation.
    - A ticket to manually alter one cell in the future.
    - A way to associated a user to a generation, so that the front end
    can show the user the generation they participated in.
    - A way to associate a user to a manual cell alteration, so that the front end
    can show the user the generation they revived a cell in.

The NFT URI will likely be a simple record of the generation_ID, rather than a pointer to an IPFS JPG/AVI. Any interface for the game (such as the website) can be used to display the image for the NFT by supplying the token_ID/generation_ID.

A game front end can use the token in different ways, either:

- Either the static image of the game at that point in time
- A short looping animation of a few frames leading up to that point in time,
pausing at their generation for a bit, then restarting the loop.

When can tokens be minted: They can only be minted moving forward from the tip
of the game. They cannot be minted for historical states.

## Example token minting sequence


If the current generation is 543 and the user evolves the game by 7, then they will receive the token with ID corresponding to 560. A third party passively watching the game on the website will see the game tick forward 7 times.

```
gen_543 ------> alice_adds_7 ------> gen_550
                             ------> token_550_to_alice

The fronted receives the emitted event and updates to display.
    GenerationEvent(user_id_of_alice, new_state_550)

Third party view:
gen_543_1_sec -> gen_544_1_sec -> (etc.) -> gen_549_1_sec ->
gen_550_5_sec -> Back to 543
```
From Alice's view, she also sees that she owns `token_550`.

Bob is a user who minted an older generation and holds `token_245`.
He now chooses to make a cell alive at row 5, column 17. The generation
does not increase.

```
gen_550 ------> bob_alive_5_17 ------> gen_550

The fronted receives the emitted event and updates to display.
    AliveEvent(user_id_of_bob, row_5, col_17)

Third party view, now the revived cell is added to the loop:
gen_543_1_sec -> gen_544_1_sec -> (etc.) -> gen_549_1_sec ->
gen_550_1_sec -> gen_550_with_orange_5_sec -> Back to 543
```


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

E.g., Carol progresses the game from generation 340 to 350.

The current plan is to emit the state at 350. States 341, 342, etc.
can be calculated off-chain for display.

The game could potentially emit intermediate states 341, 342, etc.
This depends on how the Events feature works (cost etc.).
```

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

## Social media:

A button to tweet (or copy-to-tweet) a preformatted message with an image,
some text and a link to the site.

Option 1:

- Image
    - The current game state
- Text
    - "This is GoL2, live. A collaborative Game of Life as a Cairo contract on StarkNet."
- Site link (url)

Option 2:

- Image
    - The state associated with one of the tokens of the user.
- Text
    - "I helped evolve the GoL2, the Game of Life on StarkNet. Join us and shape the future!"
- Site link (url)


