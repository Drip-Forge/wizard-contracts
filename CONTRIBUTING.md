# Contributing to wizard-contracts

This is the Solidity layer of DripForge Wizard. Pair changes with [wizard-api](https://github.com/Drip-Forge/wizard-api) if you touch weight math, and with [wizard-ui](https://github.com/Drip-Forge/wizard-ui) if you change events or function signatures the dashboard will call.

Read [docs/architecture.md](docs/architecture.md) first.

## Local setup

- [Foundry](https://book.getfoundry.sh/)
- Node 20+ (OpenZeppelin is an npm dependency)

```bash
npm install
forge test -vvv
forge fmt
```

## Drips Wave

Prepared for [Drips Wave](https://www.drips.network/solutions/wave):

1. Claim an issue in a comment before coding.
2. Keep design discussion on the issue / PR.
3. Branch from `main` (`feat/…`, `fix/…`, `docs/…`).
4. PRs must include `forge test` output. If you change `SplitsLib` rules, update [docs/contracts.md](docs/contracts.md) and mention the matching [wizard-api](https://github.com/Drip-Forge/wizard-api/blob/main/docs/api.md) behaviour.
5. Never commit private keys or `.env` files.

`FUNDING.json` uses a zero-address placeholder until a maintainer claims the repo on Drips.

## Invariants to preserve

- Receivers sorted by `accountId`, unique, `weight > 0`
- `sum(weight) <= 1_000_000`
- At most 200 receivers
- `AddressDriver.setSplits` is always called from the Wizard contract (contract-owned account)

## Good first contributions

- Fuzz tests for `SplitsLib.validate`
- A `RepoDriver` adapter (GitHub-claimed projects)
- A Foundry script that reads wizard-api JSON and broadcasts `applyAnalyzedSplits`
- Mapping helpers from npm name → GitHub URL

## License

MIT, see [LICENSE](LICENSE).
