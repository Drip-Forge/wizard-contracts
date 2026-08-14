# Architecture

```
wizard-api splitsProposal
        │
        │  map package name → Drips accountId
        │  sort by accountId
        ▼
DependencySplits.applyAnalyzedSplits(sourceHash, receivers)
        │
        ├─ SplitsLib.validate
        ├─ emit FundingParsed(sourceHash, totalWeight)
        └─ AddressDriver.setSplits(receivers)
                │
                ▼
         Drips splits hash for *this contract's* account
```

## Design constraints (why the scaffold changed)

The original `FundingParser` called a fictional `IDripsHub.setSplits(receivers)` and returned a hash from the hub. Production Drips splits the work:

- **`AddressDriver.setSplits(SplitsReceiver[])`** — `msg.sender` is converted to an account ID; no hash is returned
- **`Drips.setSplits(accountId, receivers)`** — only callable by the driver that owns that account
- **`Drips.splitsHash(accountId)`** — view

A Solidity contract that calls AddressDriver therefore configures **its own** account, not the EOA that sent the outer transaction. That is documented and intentional: `DependencySplits` is a splitter contract. For a GitHub repo claim, maintainers still use `FUNDING.json` + the Drips app ([wizard-api Drips integration](https://github.com/Drip-Forge/wizard-api/blob/main/docs/drips-integration.md)).

`FundingParser` remains abstract so other ecosystems (Cargo, Go, Solidity remappings) can implement `parseFunding` without copying validation.

## Related docs

- [Contract reference](contracts.md)
- [Integration](integration.md)
- [wizard-api architecture](https://github.com/Drip-Forge/wizard-api/blob/main/docs/architecture.md)
