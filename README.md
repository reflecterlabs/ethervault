# EtherVault

EtherVault is a liquid on-chain market for future AI inference capacity.

This repository combines:
- On-chain protocol primitives for capacity tokenization, treasury reserves, dynamic market fees, and provider settlement.
- A Cloudflare Worker gateway for edge routing and x402-based payment-gated API access.

## What EtherVault Solves

- Enterprises need predictable access to AI inference capacity.
- Providers need better monetization of idle capacity.
- Markets need transparent price discovery and liquidity.

EtherVault addresses this with treasury-backed capacity tokens and Uniswap v4 hook-based market mechanics.

## Product Architecture

```text
Enterprise Demand -> Treasury Deposit (USDC/DAI/USDT)
                 -> Capacity Token Minting (EVCAP)
                 -> Uniswap v4 Trading (dynamic fee hook)
                 -> Settlement Router (Treasury + Providers)
                 -> Redeem / consume future inference capacity
```

## Repository Layout

```text
.
├── contracts/
│   ├── src/
│   │   ├── EtherVaultCapacityToken.sol
│   │   ├── EtherVaultTreasury.sol
│   │   ├── EtherVaultSettlementRouter.sol
│   │   ├── hooks/
│   │   │   └── EtherVaultMarketHook.sol
│   │   ├── interfaces/
│   │   └── libraries/
│   │       └── FeePolicy.sol
│   ├── test/
│   ├── foundry.toml
│   └── remappings.txt
├── src/
│   ├── index.ts
│   ├── auth.ts
│   └── jwt.ts
├── public/
│   ├── index.html
│   ├── EtherVault_01.png
│   └── favicon.svg
├── wrangler.jsonc
└── README.md
```

## Core Protocol Components

### 1. EtherVaultCapacityToken
- ERC20 token representing future AI inference capacity units.
- Minted/burned by treasury-controlled flows.

### 2. EtherVaultTreasury
- Manages supported stablecoin reserves.
- Handles deposit -> mint and redeem -> payout flows.
- Tracks utilization and reserve coverage inputs for fee policy.

### 3. EtherVaultMarketHook (Uniswap v4)
- Applies utilization-aware dynamic fee logic via hook callbacks.
- Captures configured treasury fee component on swaps.

### 4. EtherVaultSettlementRouter
- Routes value between treasury and provider payout legs.
- Supports treasury share basis-point configuration.

### 5. FeePolicy Library
- Deterministic fee calculations based on utilization and reserves.
- Shared policy primitive for market fee behavior.

## Worker Gateway (Edge Layer)

The Worker layer (`src/`) provides:
- x402 payment verification for protected endpoints.
- Stateless JWT cookie sessions.
- Proxy/gateway behavior for API surfaces.

This is useful for:
- paid API endpoints,
- controlled premium access,
- monetized edge distribution.

## Quick Start (Local)

### Prerequisites
- Node.js 18+
- npm

### Install

```bash
npm install
```

### Configure local secret

```bash
cp .dev.vars.example .dev.vars
node -e "console.log('JWT_SECRET=' + require('crypto').randomBytes(32).toString('hex'))" >> .dev.vars
```

### Run locally

```bash
npm run dev
```

Open:
- `http://localhost:8787` (EtherVault landing page)
- `http://localhost:8787/__x402/health` (public health endpoint)
- `http://localhost:8787/__x402/protected` (payment-gated test endpoint)

## Configuration

Primary runtime variables live in `wrangler.jsonc`.

| Variable | Required | Purpose |
| --- | --- | --- |
| `PAY_TO` | Yes | Wallet that receives payments |
| `NETWORK` | Yes | Payment network (`base-sepolia` or `base`) |
| `JWT_SECRET` | Yes | Secret used to sign auth cookies |
| `PROTECTED_PATTERNS` | Yes | Payment-gated route definitions |
| `FACILITATOR_URL` | No | x402 facilitator endpoint |
| `ORIGIN_URL` | No | External upstream origin |

### Example `PROTECTED_PATTERNS`

```jsonc
"PROTECTED_PATTERNS": [
  {
    "pattern": "/premium/*",
    "price": "$0.10",
    "description": "Premium EtherVault API access"
  }
]
```

## Development Commands

| Command | Description |
| --- | --- |
| `npm run dev` | Start local Worker + frontend |
| `npm run typecheck` | TypeScript checks |
| `npm run lint` | Full lint + format checks |
| `npm run deploy:pages` | Deploy basic static site to Cloudflare Pages |
| `npm run deploy` | Deploy to Cloudflare Workers |

## Deploy (Basic - Cloudflare Pages)

Use this path if you only need the landing site and want fewer moving parts than a Worker deployment.

```bash
npm run pages:project:init   # one time
npm run deploy:pages
```

The repository now includes a GitHub Actions workflow that deploys `public/` to Pages on every push to `main`.

## Deploy (Worker/API - Optional)

```bash
npx wrangler secret put JWT_SECRET
npm run deploy
```

For production:
- set `NETWORK` to `base` in `wrangler.jsonc`,
- use a production wallet in `PAY_TO`,
- verify protected patterns and route ownership.

## Testing Notes

- Worker/API flow can be validated via `test-client.ts`.
- Smart contracts are located in `contracts/` with Foundry config scaffolded.
- Add/expand protocol tests under `contracts/test/` for treasury, fee policy, and hook behavior.
- React UI integration notes (shadcn + Tailwind + TypeScript) are in `docs/react-ui-setup.md`.

## Resources

- Uniswap v4 docs: https://docs.uniswap.org/contracts/v4/overview
- Cloudflare Workers docs: https://developers.cloudflare.com/workers/
- x402 protocol: https://x402.org
- Base network docs: https://docs.base.org

## License

This project is provided as-is for experimentation and product development.
