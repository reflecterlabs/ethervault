# EtherVap On-Chain Module

This folder contains the first-pass Solidity architecture for EtherVap, the liquid market for future AI inference capacity.

## What this module covers

- `EtherVaultCapacityToken`: ERC20 capacity asset minted against treasury deposits.
- `EtherVaultTreasury`: reserve management, mint/redeem flows, multi-stablecoin support, and provider payouts.
- `EtherVaultMarketHook`: Uniswap v4 hook for dynamic LP fee policy and treasury fee capture.
- `EtherVaultSettlementRouter`: routing layer for stablecoin settlement across treasury and model providers.
- `FeePolicy`: deterministic fee logic used by the hook.

## Uniswap v4 pattern alignment

The hook follows the official v4 patterns documented by Uniswap:

- `beforeSwap` is used for dynamic LP fee overrides.
- `afterSwap` is used for treasury capture on the unspecified side of the swap.
- `afterInitialize` seeds the initial dynamic fee for the pool.
- Add/remove liquidity callbacks are wired as observability points for liquidity planning.

Reference sources used while designing this module:

- Uniswap v4 `IHooks` and `Hooks` docs.
- Uniswap v4 `DynamicFeesTestHook`, `DynamicReturnFeeTestHook`, and `FeeTakingHook` examples.
- Uniswap v4 periphery `PositionManager` patterns for liquidity lifecycle and settlement.

## Local setup

This folder is intentionally isolated so it can be turned into a Foundry project independently of the existing Cloudflare Worker app.
When you are ready to compile it locally, install Foundry and add the official Uniswap packages into `contracts/lib/`.
