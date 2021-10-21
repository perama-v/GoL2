# Infinite mode

GoL2 Infinite

## Mode description

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


## Game progression

To 'play' a user sends a transaction to evolve the game of life.
They may choose to evolve it one generation.

Several players might sequentially create the following scenario from
the starting generation (gen_1):

- Game_spawn: gen_1 (the acorn)
- Alice: gen_2 (acorn +1)
- Bob: gen_3 (acorn +2)
- Carol: gen_4 (acorn +3)
- Dave: gen_5 (acorn +4)

The action of Carol was to evolve by 1 generation, bringing the state
to generation 4. She mints a single token (ID 4) just like the other players.

The second aspect of 'play' is to manually alter one cell. This does not
increase the generation, and can only be performed by redeeming an
existing game token. In the example below, Alice and Bob revive adjacent
cells before Elle's turn. Elle evolves 1 then Fred evolves 6.

- Game_spawn: gen_1 (the acorn)
- Alice: gen_2 (acorn +1)
- Bob: gen_3 (acorn +2)
- Carol: gen_4 (acorn +3)
- Dave: gen_5 (acorn +4)
- Bob: revive (row=4, col=5) gen_5 (acorn +4 with one revived cell)
- Alice: revive (row=3, col=5) gen_5 (acorn +4 with two revived cells)
- Elle: gen_6 (acorn +5)
- Fred: gen_7 (acorn +6)

The game has now diverged from the generic Acorn state through the actions
of Alice and Bob.

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


