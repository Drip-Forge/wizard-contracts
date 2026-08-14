# Integration

## From wizard-api

[POST /analyze](https://github.com/Drip-Forge/wizard-api/blob/main/docs/api.md) returns `splitsProposal`:

```json
{
  "ownerWeight": 800000,
  "dependencies": [
    { "name": "lodash", "suggestedWeight": 200000 }
  ]
}
```

Off-chain steps before `applyAnalyzedSplits`:

1. Resolve the owner wallet (or this contract) to a Drips account ID via `AddressDriver.calcAccountId`
2. Resolve each dependency to a Drips project / address account ID (GitHub URL → RepoDriver, or a known EOA)
3. Build `SplitsReceiver[]`, **sort by `accountId` ascending**, drop zero weights
4. `sourceHash = keccak256(packageJsonBytes)`
5. Owner of `DependencySplits` submits the tx

[wizard-ui](https://github.com/Drip-Forge/wizard-ui) currently displays the proposal; it does not yet send the transaction. Wiring `writeContract` against `DependencySplits` is a natural Wave task.

## From wizard-ui

The dashboard's "Suggested Drips splits" table is this integration's human-readable view. In-app explanation: [Documentation](https://github.com/Drip-Forge/wizard-ui/blob/main/src/app/docs/page.tsx).

## From Drips (GitHub claim)

If the goal is only to **claim a GitHub repo**, you do not need to deploy these contracts. Commit `FUNDING.json` from wizard-api/ui and follow [Claim your repository](https://docs.drips.network/get-support/claim-your-repository/). Configure maintainer + dependency splits in the Drips UI (RepoDriver).

Use **this** repo when funds should hit a **contract** that then splits onward using Wizard's weights.

## Related docs

- [wizard-api Drips integration](https://github.com/Drip-Forge/wizard-api/blob/main/docs/drips-integration.md)
- [Contract reference](contracts.md)
