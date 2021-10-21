# Creator mode

GoL2 Creator mode is a separate contract to GoL2 Infinite mode.

A user may mint a genesis state of their own, but must first participate
in the game and interact with the tokens that other users have created.

## Game mechanics outline

The user selects a game. They evolve that game and gain a credit. When
they have enough credits, they can create a game of their own.

## Game progression

A user may browse the current collection of and select one to
progress. This game can be any existing game, including their own
(it is completely separate from the Infinite game, which lives
in a separate contract). They click to progress the game and sign a transaction.
The game increments forward one generation. They receive one credit
as a reward for helping move the game forward.

A user may create a new game by spending ten credits.
When they choose to do this they are
presented with a blank ganvas. They can fill in the grid by
clicking individual cells (32x32 grid). When they are finished
designing the game, they finalise by signing a transaction.
This registers the game (the contrct makes sure it is unique,
rejecting the transaction otherwise). The contract also rejects the
transaction if the user has less than 10 credits.


## Social media:

A button to tweet (or copy-to-tweet) a preformatted message with an image,
some text and a link to the site.

Option 1:

- Image
    - The current game state of a game a user owns.
- Text
    - "This is a game I evolved in GoL2 Creator. A collaborative Game of Life as a Cairo contract on StarkNet."
- Site link (url)

Option 2:

- Image
    - The genesis state of a game a user owns.
- Text
    - "This is a game I designed in GoL2 Creator. the Game of Life on StarkNet. Help me evolve it!"
- Site link (url)


