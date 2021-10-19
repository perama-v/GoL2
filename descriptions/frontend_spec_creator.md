# Frontend specification for StarkNet-based Game of Life

### Project title

GoL2 Creator

Game of Life, a Game on L2.

## Description

An accompanying module for the Infinite GoL2.

A user may mint a genesis state of their own, but must first participate
in the game and interact with the tokens that other users have created.

## Game mechanics outline

The user selects a game. They evolve that game and gain a credit. When
they have enough credits, they can create a game of their own.


## Game progression



## Visual style:

Elements of the website should include:

- A 32x32 grid containing two types of cells (alive/dead).
- Buttons for navigation and interaction.
- A less prominent text description containing information about the
game.


## Data source


## Source of state updates


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


