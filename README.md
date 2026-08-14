# wizard-contracts

This repository houses the Solidity smart contract logic for the **Wizard** project under the **DripForge** organization. It interfaces directly with the **Drips Protocol** to manage automatic dependency-based token splits.

## Architecture

At the core of the contract design is the `FundingParser`:

1.  **`IDripsHub.sol`**: An interface describing the entry points for the Drips protocol, specifically the `setSplits` and `getSplitsHash` functions.
2.  **`FundingParser.sol`**: An abstract base contract. It mandates inheriting classes to implement custom parsing logic for various dependency files (e.g. `package.json`, `Cargo.toml`, `mix.exs`) which resolve to a set of split receiver configurations (Drips user IDs and weights out of 1,000,000). The base contract then updates these configurations directly on the `DripsHub` on-chain registrar.

## Integration in Drips Ecosystem

Drips uses a decentralized on-chain splits database. An address registry associates a code repository's ownership with an Ethereum account. The `FundingParser` automates updating the splits of this repository user's account whenever a verified dependency metadata file is updated.

This allows projects to declare dependencies on-chain and automatically stream a percentage of their incoming funding directly to their software dependencies, enabling a scalable open-source circular funding economy.

## Building and Testing

Prerequisites: [Foundry](https://github.com/foundry-rs/foundry) toolchain.

### Commands

*   **Compile contracts**:
    ```bash
    forge build
    ```
*   **Run unit tests**:
    ```bash
    forge test
    ```
