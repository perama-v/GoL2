# Game architectures

The game of life in the blockchain setting is different in three main
regards:

1. Shared state.
2. Finite dimensions.
3. Finite computation of steps.

The first property, shared state, is the most interesting in that it
provides participation, attribution, coordination and ownership.

The finite dimensions make the game different from the standard game,
which can be zoomed-out. Rather than have shapes move out of view,
wrapping allows the game to always containg all the alive tiles.
This also means that existing patterns (GoL Lexicon library)
become meaningless if they exceed the dimensions of the game (32x32).
E.g., A spaceship will interact with itself and lose its spaceship-ness.

The finite computation of steps means that the game can be progressed
in small increments. E.g., One turn evolves one generation. This makes
is infeasible to have a single turn evolve 50 generations into the
future for a given state.

Effect of these constrainst on different designs:

- Own a known pattern from GoL Lexicon. Possible for small patterns,
but becomes unpredictable for large/expanding patterns. Owning a
pattern only becomes interesting when it is played out. So in this
model a pattern could be owned and other people could join in to progress
the game forward.
- Own a snapshot of a generation in a long-running game. Possible
to create collaboration and coordination.
- Own a snapshot in someone elses spawned game. This could be the mechanism
for why someone would want to progress the state of another persons
game. Why would they not just claim their own state? Perhaps owning
a genesis state has a cost, but evolving another persons does not?
Perhaps by evolving other peoples state you get credits that can then
be saved up to own your own genesis state.

## Toolset for implementing the game

The game can be constructed in different ways by levering different
aspects of the StarkNet technology stack. While some architectures
may be ideal, they require features not currently available.

- Events and archive nodes to explore them.
- Volition for offchain state.

Effects of these factors on current game design:

- The game is currently storing all state as storage variables.
The game could instead emit all states as events that an archive
node could watch for, and then piece together the game variables
and ownerships from the events. This would make the game operation
cheaper for the user. At present, it is unclear if the game is
expensive to play.
- The game could potentially store to volition rather than to L1
via storage variables. The details of this architecture are less
clear.

## Game purpose

The purpose of the game in my mind is to have fun and get people
interested in learning about StarkNet and Cairo.

Elements that could increase enjoyment:

- Sense of purpose.
- Sense of clever use of technology.
- Collaboration.
- Visual enjoyment.
- Creative control.
- Ownership.
- Responsibility.
- Rarity and uniqueness.
- Open-endedness for the future.

## Versions

- Long running game that starts with Acorn and people join in
to progress and modify the game with a give-life ability. This is
compelling because it leverages most of the interest factors above.
    - `GoL2.cairo` is an implementation that keeps token storage
    in a separate contract.
    - `GoL2_stored_history.cairo` is an implementation that keeps
    all game state saved in the game contract, so that there is
    reduced dependency on other moving parts (implementation of
    the ERC721 token standard).
- Spawn a state and progress the game forward from there. No ability
to give-life. There is at first one main game. By
moving the main game forward you receive fungible tokens. When
you have enough tokens you are allowed to spawn you own game.
    - `GoL2_regenerating.cairo` is an implementation of a simple
    begin and evolve game. Can be modified to have:
        - A token model where evolving mints tokens and spawning
        consumes 10x number of the tokens you get from evolving.
        - A spawn function that accepts an initial state and saves
        it to the owner.
        - The main issue with this model is that:
            - To design and spawn a new game is exciting (what will
            it become in the new edge-wrapped paradigm?)
            - To progress a deterministic game one step is not as exciting
            (you know what it will become in one step and there is
            not as many of the interesting elements form the above list.
            You have to do it repeatedly because you cannot
            skip forward many generations). Without people progressing
            the game, it exists as a static spawned image, which
            doesn't showcase the ability of StarkNet.

