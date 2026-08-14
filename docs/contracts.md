# Contract reference

## `SplitsLib`

Pure library. Constants match Drips:

- `TOTAL_SPLITS_WEIGHT = 1_000_000`
- `MAX_SPLITS_RECEIVERS = 200`

`validate(receivers)` reverts with:

| Error | Cause |
| --- | --- |
| `TooManyReceivers` | length > 200 |
| `ZeroWeight` | any `weight == 0` |
| `ReceiversNotSorted` | `accountId` not strictly increasing |
| `WeightsSumTooHigh` | sum > 1,000,000 |

A sum **less** than 1,000,000 is valid: leftover accrues to the account as collectable funds (Drips behaviour).

`hashReceivers` is `keccak256(abi.encode(receivers))` for events and tests. It is **not** the protocol `splitsHash` storage slot.

## `IAddressDriver`

Subset used by Wizard:

```solidity
struct SplitsReceiver { uint256 accountId; uint32 weight; }
function setSplits(SplitsReceiver[] calldata receivers) external;
function calcAccountId(address addr) external view returns (uint256);
```

Point production deployments at the canonical AddressDriver for the chain. See [Drips contracts](https://github.com/drips-network/contracts).

## `IDrips`

Read-only `splitsHash(uint256 accountId)` for integrators who want to verify the protocol storage after a tx.

## `FundingParser`

Abstract `Ownable` adapter.

- Constructor takes AddressDriver; rejects `address(0)`
- `parseFunding(string metadataHash)` — virtual; implement per ecosystem
- `applySplits(SplitsReceiver[])` — `onlyOwner`, validates, calls the driver
- Events: `FundingParsed(bytes32 sourceHash, uint32 totalWeight)`, `SplitsUpdated(bytes32 splitsHash, uint32 totalWeight)`

## `DependencySplits`

Concrete parser for [wizard-api](https://github.com/Drip-Forge/wizard-api/blob/main/docs/api.md).

- `parseFunding` always reverts (`UseApplyAnalyzedSplits`) — npm JSON is not decoded on-chain
- `applyAnalyzedSplits(bytes32 sourceHash, SplitsReceiver[] receivers)` — stores `lastSourceHash`, emits `FundingParsed`, then `_applySplits`
- `sourceHash` should be `keccak256` of the canonical `package.json` bytes (or an IPFS CID hashed to `bytes32`) so reviewers can audit which analysis was applied

## Tests

`test/FundingParser.t.sol` covers library reverts, the mock `parseFunding` path, `DependencySplits`, and `onlyOwner`.

```bash
forge test -vvv
```

## Related docs

- [Architecture](architecture.md)
- [Integration](integration.md)
