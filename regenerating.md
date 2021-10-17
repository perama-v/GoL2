## Simplified low-storage alternate version

To experiment with a different model `GoL2_regenerating.cairo` was made.
It does not store the game state. All users choose a generation and mint from
the same spawn point. The contract produces the image and stores their address.

Later a token could be minted from the recorded addresses.

There is no manual intervention and the game can be thought of as
'pick a special number and claim the image associated with that generation'.

You can perhaps have the following modes:

- Mint from library. E.g., mint a specific well known shape (lexicon).
    - "I claim the acorn/glidergun/xyz"
    - Perhaps you have derivative tokens: You can license off tokens for
    generations of your special token. (join the glider gun team by claiming
    a generation).
- Invent. Submit a spawn state - the wrapping makes the project different
from the classic game. Anything that is large enough to wrap and contact
itself will diverge from known behaviour (with respect to non-wrapping)
    - Users can compete to see who can last the longest.
    - If it starts to die you could pay to add a cell?


---

## Limitations of implementation:

The game as a 32x32 grid can evolve two generations in one transaction.
Three generations or more returns an `OUT_OF_RESOURCES` error. I haven't
been able to identify a more efficient mechanism to evolve the game, so
at this resolution (32x32), game play mechanics are limited to 1-2 generations
per turn.

```
starknet-compile contracts/GoL2_regenerating.cairo \
    --output artifacts/GoL2_regenerating_compiled.json \
    --abi artifacts/abis/GoL2_regenerating_contract_abi.json

starknet deploy --contract artifacts/GoL2_regenerating_compiled.json \
    --network=alpha

Deploy transaction was sent.
Contract address: 0x024edd90cad683d43b39e99c4bb6712722ab1d2c85b39c6299683b6cee3f92ce
Transaction ID: 247625

starknet invoke \
    --network=alpha \
    --address 0x024edd90cad683d43b39e99c4bb6712722ab1d2c85b39c6299683b6cee3f92ce \
    --abi artifacts/abis/GoL2_regenerating_contract_abi.json \
    --function spawn

Invoke transaction was sent.
Contract address: 0x024edd90cad683d43b39e99c4bb6712722ab1d2c85b39c6299683b6cee3f92ce
Transaction ID: 247629

starknet invoke \
    --network=alpha \
    --address 0x024edd90cad683d43b39e99c4bb6712722ab1d2c85b39c6299683b6cee3f92ce \
    --abi artifacts/abis/GoL2_regenerating_contract_abi.json \
    --function evolve_generations \
    --inputs 1

Invoke transaction was sent.
Contract address: 0x024edd90cad683d43b39e99c4bb6712722ab1d2c85b39c6299683b6cee3f92ce
Transaction ID: 247682

starknet invoke \
    --network=alpha \
    --address 0x024edd90cad683d43b39e99c4bb6712722ab1d2c85b39c6299683b6cee3f92ce \
    --abi artifacts/abis/GoL2_regenerating_contract_abi.json \
    --function evolve_generations \
    --inputs 100

Invoke transaction was sent.
Contract address: 0x024edd90cad683d43b39e99c4bb6712722ab1d2c85b39c6299683b6cee3f92ce
Transaction ID: 247686

starknet tx_status --network=alpha --id=247686
{
    "tx_failure_reason": {
        "code": "OUT_OF_RESOURCES",
        "error_message": "Error at pc=0:58:\nError: End of program was not reached",
        "tx_id": 247686
    },
    "tx_status": "REJECTED"
}
```