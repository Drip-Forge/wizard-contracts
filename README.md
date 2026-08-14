# wizard-contracts

Foundry contracts for **DripForge Wizard**. They encode Drips splits rules on-chain and apply a [wizard-api](https://github.com/Drip-Forge/wizard-api) analysis as a receivers list.

This repository is one of three. Read them together:

| Layer | Repository | What it does |
| --- | --- | --- |
| UI | [wizard-ui](https://github.com/Drip-Forge/wizard-ui) | Dashboard that uploads `package.json` and downloads `FUNDING.json` |
| API | [wizard-api](https://github.com/Drip-Forge/wizard-api) | Off-chain validation + splits proposal (weights out of 1,000,000) |
| Chain | **wizard-contracts** (this repo) | `SplitsLib` + `DependencySplits` → Drips `AddressDriver` |

**Docs in this repo**

- [Documentation index](docs/README.md)
- [Architecture](docs/architecture.md)
- [Contract reference](docs/contracts.md)
- [Integration with API / UI / Drips](docs/integration.md)
- [Contributing](CONTRIBUTING.md)

Sibling docs: [wizard-api Drips integration](https://github.com/Drip-Forge/wizard-api/blob/main/docs/drips-integration.md) · [wizard-ui getting started](https://github.com/Drip-Forge/wizard-ui/blob/main/docs/getting-started.md)

## What is on-chain vs off-chain

Parsing `package.json` happens in wizard-api. These contracts **never** JSON-decode npm manifests. They:

1. Validate a splits receivers list against the same rules as Drips (sorted unique IDs, non-zero weights, ≤ 200 receivers, total weight ≤ 1,000,000)
2. Optionally record a `sourceHash` of the analyzed file
3. Call `AddressDriver.setSplits`, which configures **this contract's** Drips account

GitHub repositories claimed via `FUNDING.json` are managed by Drips' RepoDriver in the [Drips app](https://docs.drips.network/get-support/claim-your-repository/). Use this repo when you want a **contract-owned** splitter (treasury, protocol fee sink) driven by Wizard's proposal.

## Contracts

| Contract | Path | Role |
| --- | --- | --- |
| `SplitsLib` | `src/libraries/SplitsLib.sol` | Pure validation + hash |
| `FundingParser` | `src/FundingParser.sol` | Abstract Ownable adapter |
| `DependencySplits` | `src/DependencySplits.sol` | Concrete parser for wizard-api output |
| `IAddressDriver` | `src/interfaces/IAddressDriver.sol` | Subset of canonical Drips AddressDriver |

## Quick start

Prerequisites: [Foundry](https://book.getfoundry.sh/) and Node (OpenZeppelin via npm).

```bash
npm install
forge test -vvv
forge build
```

Deploy against a canonical AddressDriver:

```bash
ADDRESS_DRIVER=0x... PRIVATE_KEY=0x... forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

## Claiming this repo on Drips

Replace the zero address in [`FUNDING.json`](FUNDING.json) with the maintainer wallet before claiming.

## License

[MIT](LICENSE) © Drip-Forge
