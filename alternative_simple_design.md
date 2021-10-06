# Simplified low-storage alternate version

To experiment with a different model `GoL2_regenerating.cairo` was made.
It does not store the game state. All users choose a generation and mint from
the same spawn point. The contract produces the image and stores their address.

Later a token could be minted from the recorded addresses.

There is no manual intervention and the game can be thought of as
'pick a special number and claim the image associated with that generation'.

Upon trying to evolve 100 generations of the 32x32 grid, an `OUT_OF_RESOURCES`
error was returned. This intuitively feels correct: if each of the 1024 cells involved
10 steps in the program, 100 generations would be 1,000,000 steps. As I understand it, this approaches the upper bound of the proving system. Perhaps there is a much more efficient game evolution algorithm that would enable this low-storage game mode.

A better approach would be to require the input of a known state and to verify the hash
before progressing a global state, storing only the hash upon turn completion, but
emitting the full game state as an event.

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