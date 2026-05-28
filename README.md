# LaunchShield

LaunchShield is a Uniswap v4 Hook-powered protected launch pool for new assets
on X Layer. Oversized early swaps are atomically rejected, while accepted
volatile swaps place subsequent trades into an elevated LP-fee cooldown.

LaunchShield limits single-swap pool spot-price movement and adjusts LP fees.
It does not promise bot prevention, Sybil resistance, MEV elimination, or
price stability.

## Status

The MVP code, tests, interface, and X Layer deployment scripts are complete.
The public Hook/pool addresses intentionally remain unset in
`web/src/deployments/1952.json` until transactions are signed from a
user-controlled X Layer Testnet wallet. A valid hackathon submission requires
that final public deployment.

## Demonstrated Rules

| Rule | Value | Implementation |
| --- | ---: | --- |
| Launch protection window | 30 minutes | Movement caps apply only during this window |
| Normal LP fee | 0.30% | Dynamic fee override before each normal swap |
| Guarded LP fee | 1.00% | Dynamic fee after accepted volatility |
| Normal movement cap | approximately 3.00% / 295 ticks | Larger protected swaps revert |
| Guarded movement cap | approximately 1.50% / 148 ticks | Tighter protected cap |
| Volatility trigger | approximately 2.00% / 199 ticks | Starts or extends Guarded mode |
| Guarded cooldown | 10 minutes | Elevated fee duration |

The rejected trade is a prevented attempt: its swap state, fee mode, and
cooldown changes are rolled back with the transaction.

## Architecture

- `src/LaunchShieldHook.sol`: v4 Hook with launch movement caps and dynamic
  guarded fees.
- `src/MockLaunchToken.sol`: two demo ERC-20 assets, `XSH` and `mUSDC`.
- `src/XLayerV4Addresses.sol`: X Layer chain IDs and verified mainnet v4
  references.
- `script/00_DeployTokens.s.sol` through `script/04_DemoSwap.s.sol`: guarded
  public deployment and demo flow.
- `script/00_DeployTestnetV4.s.sol`: self-deploys the v4 infrastructure needed
  on X Layer Testnet.
- `web/`: React/Vite interface with wallet switching, on-chain reads, three
  demo actions, and decoded prevented-attempt status.

## Verification

```bash
npm install --registry=https://registry.npmjs.org/
npm run fmt:contracts
npm run test:contracts
npm run build:contracts

cd web
npm install --no-audit --no-fund --registry=https://registry.npmjs.org/
npm test
npm run build
```

The contract suite verifies normal swaps, atomic movement-cap rejection,
Guarded activation, tighter Guarded caps, cooldown expiry, post-launch
behavior, demo tokens, and published X Layer addresses. The interface tests
verify the honest predeployment state and the nested v4 error decoding used to
label a prevented attempt.

## Public Demo Hosting

The static interface is published from GitHub Actions to GitHub Pages:

https://forest0909.github.io/LaunchShield/

The workflow in `.github/workflows/pages.yml` builds `web/` and deploys
`web/dist` whenever `main` is pushed. No wallet signature or contract
transaction is needed for frontend updates.

## X Layer Testnet Path

Target network: X Layer Testnet (`chainId 1952`).

The hackathon requirements allow deploying the v4 Pool and Hook on X Layer
mainnet or testnet. The official Uniswap v4 deployment listing publishes X
Layer Mainnet contracts but currently does not publish X Layer Testnet v4
contracts, so the testnet runbook first self-deploys:

| Contract | Source |
| --- | --- |
| Permit2 | Pre-existing Hookmate Permit2 bytecode at `0x3191Fc1E303EF4e12a7DE5f5d2e8d53A0660c5b9` |
| PoolManager | Hookmate artifact |
| PositionManager | Hookmate artifact |
| StateView | Uniswap v4 periphery lens |
| Demo router | Hookmate simple v4 router, not Universal Router |

Sources:

- [Uniswap v4 deployments](https://docs.uniswap.org/contracts/v4/deployments)
- [X Layer network information](https://web3.okx.com/xlayer/docs/developer/build-on-xlayer/network-information)
- [X Layer faucet](https://web3.okx.com/xlayer/faucet)
- [Hackathon page](https://web3.okx.com/zh-hans/xlayer/build-x-hackathon/hook)

## Wallet-Signed Deployment

Do not paste a private key into chat, `.env`, this repository, or a command
argument. Create an encrypted local Foundry keystore interactively:

```bash
node ./node_modules/@foundry-rs/cast/bin.mjs wallet import launchshield-deployer --interactive
cp .env.example .env
```

Fill only the public `DEPLOYER_ADDRESS` in `.env`, ensure the address has test
OKB for X Layer Testnet gas, then load the variables:

```bash
set -a
source .env
set +a
```

Broadcast in order. Each command will use the encrypted keystore and request
its password locally.

```bash
node ./node_modules/@foundry-rs/forge/bin.mjs script script/00_DeployTestnetV4.s.sol:DeployTestnetV4Script \
  --rpc-url "$X_LAYER_RPC_URL" --account launchshield-deployer --sender "$DEPLOYER_ADDRESS" --broadcast -vvv
```

The script reuses any non-zero infrastructure address already present in
`.env` and deploys the missing pieces. Copy the printed `POOL_MANAGER`,
`POSITION_MANAGER`, `STATE_VIEW`, and `DEMO_ROUTER` values into `.env` and
`web/src/deployments/1952.json`. Reload `.env`, then deploy the app contracts:

```bash
node ./node_modules/@foundry-rs/forge/bin.mjs script script/00_DeployTokens.s.sol:DeployTokensScript \
  --rpc-url "$X_LAYER_RPC_URL" --account launchshield-deployer --sender "$DEPLOYER_ADDRESS" --broadcast -vvv

node ./node_modules/@foundry-rs/forge/bin.mjs script script/01_DeployHook.s.sol:DeployHookScript \
  --rpc-url "$X_LAYER_RPC_URL" --account launchshield-deployer --sender "$DEPLOYER_ADDRESS" \
  --always-use-create-2-factory --broadcast -vvv
```

After step `00`, place the printed XSH/mUSDC addresses in `TOKEN_A` and
`TOKEN_B`. After step `01`, place the printed Hook address in `HOOK_ADDRESS`.

Create the protected pool and initial mock-token liquidity:

```bash
node ./node_modules/@foundry-rs/forge/bin.mjs script script/03_CreatePoolAndAddLiquidity.s.sol:CreatePoolAndAddLiquidityScript \
  --rpc-url "$X_LAYER_RPC_URL" --account launchshield-deployer --sender "$DEPLOYER_ADDRESS" --broadcast -vvv
```

This final deployment step prints sorted `Currency0`, `Currency1`, and the
`Pool ID`. Populate those values, the Hook, and both token addresses in
`web/src/deployments/1952.json`. Also populate the two token deployment
transaction hashes, Hook deployment transaction hash, and pool initialization
transaction hash under `transactions`; the app then reads live state, presents
explorer evidence, and unlocks the wallet actions.

## Demo Flow

The web app provides the intended judge path:

1. `Normal Buy`: spend a small amount of `mUSDC` to buy `XSH`; the swap
   succeeds in Normal mode.
2. `Trigger Large Swap`: approve the demo input token, then simulate a swap
   exceeding the active cap. The Hook error is decoded as a prevented attempt;
   no reverted swap is submitted as a transaction.
3. `Trigger Volatility`: submit an accepted volatile buy; the next read shows
   Guarded mode and the elevated fee.

Each action uses a fixed amount calibrated against the default
`INITIAL_LIQUIDITY=100e18`. Do not change initial liquidity without
recalibrating the demo amounts and tests.

After recording accepted `Normal Buy` and `Trigger Volatility` results, add
their transaction hashes as `transactions.normalSwap` and
`transactions.volatilityTrigger` in `web/src/deployments/1952.json` so judges
can verify the settled demonstrations without reconnecting a wallet.

For a command-line accepted small swap, set `INPUT_TOKEN` to the deployed
`mUSDC` token and run:

```bash
node ./node_modules/@foundry-rs/forge/bin.mjs script script/04_DemoSwap.s.sol:DemoSwapScript \
  --rpc-url "$X_LAYER_RPC_URL" --account launchshield-deployer --sender "$DEPLOYER_ADDRESS" --broadcast -vvv
```

Submission copy, proof fields, social requirements, and the video storyboard
are prepared in [docs/submission/checklist.md](docs/submission/checklist.md).
