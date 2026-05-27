# LaunchShield Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and demonstrate a verifiable LaunchShield Uniswap v4 Hook on X Layer that blocks excessive launch-period pool price movement and raises LP fees after accepted volatile swaps.

**Architecture:** The contract package starts from the Uniswap Foundation `v4-template`, with a single-pool `LaunchShieldHook` and deterministic Foundry tests/scripts. A lightweight Vite/React page reads Hook state and provides three signed demonstration swap actions. Local v4 tests establish behavior first; public deployment targets the confirmed X Layer Mainnet v4 contracts unless an event-confirmed X Layer Testnet `PoolManager` becomes available.

**Tech Stack:** Solidity 0.8.26/0.8.30, Foundry, OpenZeppelin Uniswap Hooks `BaseHook`, Uniswap v4 core/periphery, React + TypeScript + Vite, viem, Vitest.

---

## File Map

### Contract package

- `foundry.toml`, `remappings.txt`, `.gitmodules`, `lib/`: official
  `uniswapfoundation/v4-template` base and dependencies.
- `src/LaunchShieldHook.sol`: Hook configuration, state reads, dynamic fee
  override, launch-period price-movement enforcement, guarded-mode events.
- `src/MockLaunchToken.sol`: mintable demo ERC-20s for local and submission
  pool setup.
- `test/LaunchShieldHook.t.sol`: local v4 integration tests against actual
  PoolManager/router test artifacts.
- `test/utils/*`: official template test support, retained with minimal
  changes.
- `script/base/LaunchShieldConfig.sol`: chain-specific v4 addresses, mock
  token/hook configuration, and environment reads.
- `script/00_DeployTokens.s.sol`: deploy and mint demo assets.
- `script/01_DeployHook.s.sol`: salt-mined Hook deployment with exact
  permissions.
- `script/02_CreatePoolAndAddLiquidity.s.sol`: dynamic-fee pool initialization
  and initial liquidity.
- `script/03_DemoSwaps.s.sol`: normal, rejected, and volatility-triggering
  transaction routines.
- `deployments/196.json`: committed deployment manifest after a successful
  public deployment; absent until deployed.

### Web page

- `web/package.json`, `web/vite.config.ts`, `web/src/main.tsx`: frontend
  bootstrap.
- `web/src/contracts.ts`: manifest-derived addresses and minimal ABIs.
- `web/src/lib/launchShield.ts`: viem reads, wallet connection, swap action
  calls, revert decoding, explorer URLs.
- `web/src/App.tsx`: product status and three-operation demo interface.
- `web/src/App.test.tsx`, `web/src/lib/launchShield.test.ts`: state/action UI
  and decoding tests.

### Evidence

- `README.md`: pitch, limitations, setup, deployed links, demo runbook.
- `docs/submission/checklist.md`: human-required social/form/video/deployment
  evidence list with the exact addresses and links once available.

## Non-Negotiable Technical Decisions

- The protected metric is a single accepted swap's start-to-end spot-price
  movement, not trader identity, oracle price, or general MEV detection.
- The pool uses the v4 dynamic fee flag. `beforeSwap` selects either `3000`
  (0.30%) or `10000` (1.00%) with an LP-fee override; `afterSwap` may revert
  the entire swap during launch protection and records guarded mode only for
  accepted swaps.
- A reverted oversized attempt cannot emit durable evidence on chain because
  all logs revert with the transaction. Evidence is a reproducible reverted
  transaction/result in the page and video; successful normal/trigger swaps
  provide on-chain logs.
- The first public deployment check is whether an official/event-confirmed v4
  `PoolManager` exists on X Layer Testnet. Since the current Uniswap deployment
  reference confirms X Layer Mainnet (`chainId 196`,
  `PoolManager=0x360e68faccca8ca495c1b759fd9eee466db9fb32`) and does not list
  X Layer Testnet, the executable fallback is an intentionally low-value
  X Layer Mainnet demo pool.

### Task 1: Establish the v4 Contract Workspace and Tooling

**Files:**
- Create from template: `foundry.toml`, `remappings.txt`, `.gitmodules`,
  `script/base/*`, `test/utils/*`, `lib/*`
- Create: `.gitignore`
- Create: `README.md`

- [ ] **Step 1: Install or locate Foundry stable**

Run:

```bash
command -v forge || (curl -L https://foundry.paradigm.xyz | bash && ~/.foundry/bin/foundryup)
~/.foundry/bin/forge --version || forge --version
```

Expected: a stable `forge` version is printed; never add a private key to the
repository or shell command history.

- [ ] **Step 2: Import the official v4 Hook template baseline**

Run:

```bash
git remote add v4-template https://github.com/uniswapfoundation/v4-template.git
git fetch --depth=1 v4-template main
git restore --source=v4-template/main --staged --worktree -- \
  .gitmodules foundry.toml remappings.txt lib script src/Counter.sol test
git submodule update --init --recursive
```

Expected: `forge test` can resolve `@uniswap/v4-core`,
`@uniswap/v4-periphery`, and `@openzeppelin/uniswap-hooks`.

- [ ] **Step 3: Add repository hygiene and initial run instructions**

Create `.gitignore` with:

```gitignore
cache/
out/
broadcast/
.env
web/node_modules/
web/dist/
coverage/
```

Create `README.md` with the approved product pitch, the explicit non-claim
about bots/price guarantees, and:

```markdown
## Local contract verification

```bash
forge install
forge test -vvv
```

Do not commit private keys. Public deployment will use a Foundry keystore and
requires an explicit signing step.
```

- [ ] **Step 4: Prove the imported baseline builds**

Run:

```bash
forge test -vvv
```

Expected: the template `CounterTest` tests pass before replacing example
behavior.

- [ ] **Step 5: Commit workspace bootstrap**

Run:

```bash
git add .gitignore README.md foundry.toml remappings.txt .gitmodules lib script test
git commit -m "chore: bootstrap Uniswap v4 hook workspace"
```

### Task 2: Write Failing Hook Configuration and Fee Tests

**Files:**
- Create: `src/LaunchShieldHook.sol`
- Create: `test/LaunchShieldHook.t.sol`
- Remove after replacement: `src/Counter.sol`, `test/Counter.t.sol`

- [ ] **Step 1: Create a minimal Hook interface shell used by tests**

Create `src/LaunchShieldHook.sol` with contract declarations that compile but
deliberately return default state until behavior is implemented:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {BaseHook} from "@openzeppelin/uniswap-hooks/src/base/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager, SwapParams} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

contract LaunchShieldHook is BaseHook {
    uint24 public constant BASE_FEE = 3000;
    uint24 public constant GUARDED_FEE = 10000;
    uint256 public constant LAUNCH_DURATION = 30 minutes;
    uint256 public constant GUARDED_COOLDOWN = 10 minutes;
    int24 public constant NORMAL_MAX_TICK_MOVE = 295;
    int24 public constant GUARDED_MAX_TICK_MOVE = 148;
    int24 public constant VOLATILITY_TRIGGER_TICK_MOVE = 199;

    struct PoolProtection {
        uint64 launchTime;
        uint64 guardedUntil;
        int24 preSwapTick;
        bool initialized;
    }

    mapping(PoolId => PoolProtection) public protection;

    constructor(IPoolManager manager) BaseHook(manager) {}

    function getHookPermissions() public pure override returns (Hooks.Permissions memory permissions) {
        permissions.beforeSwap = true;
        permissions.afterSwap = true;
    }

    function effectiveFee(PoolId) public pure returns (uint24) {
        return BASE_FEE;
    }

    function _beforeSwap(address, PoolKey calldata, SwapParams calldata, bytes calldata)
        internal override returns (bytes4, BeforeSwapDelta, uint24)
    {
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function _afterSwap(address, PoolKey calldata, SwapParams calldata, BalanceDelta, bytes calldata)
        internal override returns (bytes4, int128)
    {
        return (BaseHook.afterSwap.selector, 0);
    }
}
```

The cap tick constants round down so the allowed tick movement does not exceed
the public percentage threshold; the trigger tick constant rounds up so a
trigger cannot occur below its stated threshold. Tests must validate all three
values against `TickMath`.

- [ ] **Step 2: Write failing tests for initialization and dynamic fees**

Copy the official template fixture approach into `test/LaunchShieldHook.t.sol`,
deploy the Hook to an address containing
`Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG`, and initialize the Pool with
`LPFeeLibrary.DYNAMIC_FEE_FLAG`. Add these assertions:

```solidity
function testPoolInitializationStartsLaunchProtection() public view {
    (uint64 launchTime,, , bool initialized) = hook.protection(poolId);
    assertTrue(initialized);
    assertEq(launchTime, block.timestamp);
    assertEq(hook.effectiveFee(poolId), hook.BASE_FEE());
}

function testVolatileAcceptedSwapElevatesFeeForNextSwap() public {
    executeSwap(amountThatMovesAtLeastTwoPercent);
    assertEq(hook.effectiveFee(poolId), hook.GUARDED_FEE());
}
```

Add helper functions `executeSwap(uint256 amountIn)` and
`absoluteTickMove(int24 beforeTick, int24 afterTick)` so test sizing can be
calibrated against the local pool rather than guessed.

- [ ] **Step 3: Run tests to confirm missing behavior**

Run:

```bash
forge test --match-contract LaunchShieldHookTest -vvv
```

Expected: FAIL because pool initialization is not recorded and volatile swaps
do not activate guarded fees.

- [ ] **Step 4: Commit failing tests**

Run:

```bash
git add src/LaunchShieldHook.sol test/LaunchShieldHook.t.sol
git commit -m "test: specify LaunchShield fee state behavior"
```

### Task 3: Implement Hook State and Dynamic Fee Mode

**Files:**
- Modify: `src/LaunchShieldHook.sol`
- Modify: `test/LaunchShieldHook.t.sol`

- [ ] **Step 1: Add initialization permission and observable state**

Extend `getHookPermissions()` with `afterInitialize = true`, update the
salt-mined/test Hook address permissions to include
`Hooks.AFTER_INITIALIZE_FLAG`, import `PoolIdLibrary` and `StateLibrary`, and
implement:

```solidity
event GuardedModeActivated(PoolId indexed poolId, int24 tickMove, uint64 guardedUntil);

function _afterInitialize(address, PoolKey calldata key, uint160, int24)
    internal override returns (bytes4)
{
    PoolProtection storage state = protection[key.toId()];
    state.launchTime = uint64(block.timestamp);
    state.initialized = true;
    return BaseHook.afterInitialize.selector;
}

function isGuarded(PoolId poolId) public view returns (bool) {
    return protection[poolId].guardedUntil > block.timestamp;
}

function effectiveFee(PoolId poolId) public view returns (uint24) {
    return isGuarded(poolId) ? GUARDED_FEE : BASE_FEE;
}
```

- [ ] **Step 2: Implement fee override and accepted volatility activation**

Use `StateLibrary.getSlot0()` to store the start tick in `_beforeSwap`, return
`effectiveFee(poolId) | LPFeeLibrary.OVERRIDE_FEE_FLAG`, then read the
post-swap tick in `_afterSwap`. If the absolute tick delta is at least
`VOLATILITY_TRIGGER_TICK_MOVE`, set `guardedUntil` and emit the event:

```solidity
function _absoluteTickMove(int24 fromTick, int24 toTick) internal pure returns (int24) {
    int24 delta = toTick - fromTick;
    return delta < 0 ? -delta : delta;
}
```

- [ ] **Step 3: Run fee state tests**

Run:

```bash
forge test --match-contract LaunchShieldHookTest -vvv
```

Expected: initialization and fee-mode tests pass; any price-cap tests added in
the next task are not yet present.

- [ ] **Step 4: Commit dynamic fee behavior**

Run:

```bash
git add src/LaunchShieldHook.sol test/LaunchShieldHook.t.sol
git commit -m "feat: activate guarded fees after volatile swaps"
```

### Task 4: Enforce Launch-Period Movement Caps Atomically

**Files:**
- Modify: `src/LaunchShieldHook.sol`
- Modify: `test/LaunchShieldHook.t.sol`

- [ ] **Step 1: Write cap and expiry tests**

Add explicit tests:

```solidity
function testNormalLaunchModeRejectsMoveAboveCapWithoutStateChange() public;
function testProtectedGuardedModeUsesTighterCap() public;
function testRejectedSwapCannotActivateOrExtendGuardedMode() public;
function testAfterLaunchExpiryMovementCapIsDisabled() public;
function testCooldownExpiryRestoresBaseFeeOnNextSwap() public;
```

Each test must snapshot `slot0` tick and `guardedUntil` before an expected
revert and assert both are unchanged after it. Use `vm.warp` for duration
tests and calibrated amounts from setup for cap boundaries.

- [ ] **Step 2: Run tests to observe missing cap enforcement**

Run:

```bash
forge test --match-contract LaunchShieldHookTest -vvv
```

Expected: the cap-related tests FAIL because oversized swaps currently settle.

- [ ] **Step 3: Implement the invariant and readable state getters**

Add:

```solidity
error MovementCapExceeded(int24 observedTickMove, int24 allowedTickMove);

function launchProtectionActive(PoolId poolId) public view returns (bool) {
    PoolProtection storage state = protection[poolId];
    return state.initialized && block.timestamp < state.launchTime + LAUNCH_DURATION;
}

function effectiveMovementCap(PoolId poolId) public view returns (int24) {
    return isGuarded(poolId) ? GUARDED_MAX_TICK_MOVE : NORMAL_MAX_TICK_MOVE;
}
```

In `_afterSwap`, compute movement before writing guarded state. When launch
protection is active and movement exceeds `effectiveMovementCap(poolId)`,
revert with `MovementCapExceeded`. Only afterward update `guardedUntil`.

- [ ] **Step 4: Verify all Hook tests**

Run:

```bash
forge test --match-contract LaunchShieldHookTest -vvv
forge test -vvv
```

Expected: PASS, demonstrating normal trade, blocked attempt, guarded fee,
cooldown restoration, and post-launch behavior.

- [ ] **Step 5: Remove counter sample and commit behavior**

Run:

```bash
git rm src/Counter.sol test/Counter.t.sol
git add src/LaunchShieldHook.sol test/LaunchShieldHook.t.sol
git commit -m "feat: enforce launch period movement protection"
```

### Task 5: Build Deterministic Demo Deployment and Swap Scripts

**Files:**
- Create: `src/MockLaunchToken.sol`
- Create: `script/base/LaunchShieldConfig.sol`
- Create: `script/00_DeployTokens.s.sol`
- Replace: `script/01_DeployHook.s.sol`
- Replace: `script/02_CreatePoolAndAddLiquidity.s.sol`
- Replace: `script/03_DemoSwaps.s.sol`
- Test: `test/LaunchShieldScripts.t.sol`

- [ ] **Step 1: Write tests for demo token setup and scripted amounts**

Create `test/LaunchShieldScripts.t.sol` asserting that two mock tokens can be
deployed/minted, the deterministic initial liquidity initializes a dynamic fee
pool, and configured swap sizes reproduce:

```solidity
assertEq(hook.effectiveFee(poolId), hook.BASE_FEE());
normalBuy();
triggerVolatility();
assertEq(hook.effectiveFee(poolId), hook.GUARDED_FEE());
vm.expectRevert(LaunchShieldHook.MovementCapExceeded.selector);
triggerLargeSwap();
```

- [ ] **Step 2: Run script integration tests to confirm failure**

Run:

```bash
forge test --match-contract LaunchShieldScriptsTest -vvv
```

Expected: FAIL until demo assets and routines exist.

- [ ] **Step 3: Implement demo assets and script configuration**

Implement `MockLaunchToken` as a constructor-minted OpenZeppelin ERC-20:

```solidity
contract MockLaunchToken is ERC20 {
    constructor(string memory name_, string memory symbol_, address recipient, uint256 amount)
        ERC20(name_, symbol_)
    {
        _mint(recipient, amount);
    }
}
```

`LaunchShieldConfig.sol` must read deploy-time addresses from environment
variables and keep no key material:

```solidity
uint256 internal constant X_LAYER_CHAIN_ID = 196;
address internal constant X_LAYER_POOL_MANAGER = 0x360e68faccca8ca495c1b759fd9eee466db9fb32;
```

It must fail with an explicit message if a public-network position manager or
router address has not yet been confirmed from the v4 deployment reference.

- [ ] **Step 4: Implement deployment and demonstration scripts**

Adapt the official v4-template salt mining in `01_DeployHook.s.sol` to mine
the `AFTER_INITIALIZE`, `BEFORE_SWAP`, and `AFTER_SWAP` flags. Initialize a
pool using `LPFeeLibrary.DYNAMIC_FEE_FLAG`, add deterministic low-value demo
liquidity, and expose separate `normalBuy`, `triggerVolatility`, and
`triggerLargeSwap` script entry points.

- [ ] **Step 5: Test scripts locally and commit**

Run:

```bash
forge test -vvv
```

Expected: all contract and script tests pass using local v4 artifacts.

Run:

```bash
git add src/MockLaunchToken.sol script test/LaunchShieldScripts.t.sol
git commit -m "feat: add deterministic LaunchShield demo scripts"
```

### Task 6: Implement the Minimal Demo Page

**Files:**
- Create: `web/package.json`, `web/vite.config.ts`, `web/tsconfig*.json`,
  `web/index.html`
- Create: `web/src/main.tsx`, `web/src/App.tsx`, `web/src/styles.css`
- Create: `web/src/contracts.ts`, `web/src/lib/launchShield.ts`
- Create: `web/src/App.test.tsx`, `web/src/lib/launchShield.test.ts`

- [ ] **Step 1: Scaffold React/Vite with viem and tests**

Run:

```bash
pnpm create vite web --template react-ts
cd web && pnpm add viem && pnpm add -D vitest jsdom @testing-library/react @testing-library/jest-dom
```

Set `web/package.json` scripts to include:

```json
{"test":"vitest run","build":"tsc -b && vite build","dev":"vite"}
```

- [ ] **Step 2: Write failing contract-state and error-decoding tests**

In `web/src/lib/launchShield.test.ts`, mock a viem public client and assert
that Hook read results map to:

```ts
{
  mode: "Normal",
  feeLabel: "0.30%",
  capLabel: "3.00%",
  launchActive: true
}
```

and that a custom `MovementCapExceeded` revert maps to:

```ts
"Prevented: this swap would move the launch pool beyond its active limit."
```

In `web/src/App.test.tsx`, assert rendering of pool evidence links and the
three buttons `Normal Buy`, `Trigger Large Swap`, and `Trigger Volatility`.

- [ ] **Step 3: Run tests to confirm missing UI behavior**

Run:

```bash
cd web && pnpm test
```

Expected: FAIL because the LaunchShield page/state adapters do not exist.

- [ ] **Step 4: Implement frontend state, actions, and UI**

Implement `contracts.ts` with an intentionally unset pre-deployment
configuration that causes the UI to say `Awaiting public deployment` until
`deployments/196.json` is populated. Implement `launchShield.ts` using `createPublicClient`,
`createWalletClient(custom(window.ethereum))`, contract reads for
`effectiveFee`, `launchProtectionActive`, `effectiveMovementCap`, and
`protection`, and signed demo transaction calls using the confirmed router
contract interaction selected in Task 5.

`App.tsx` must show:

- Honest pitch and limitation text.
- Wallet/network status and an explicit X Layer network-switch action.
- Hook/Pool/explorer evidence once configured.
- Current `Normal`/`Guarded` state, fee, cap, and timer.
- Three operation buttons and a result panel that labels rejected swaps as
  prevented attempts, not completed transactions.

- [ ] **Step 5: Verify and commit frontend**

Run:

```bash
cd web && pnpm test && pnpm build
```

Expected: PASS and a production build in `web/dist`.

Run:

```bash
git add web
git commit -m "feat: add LaunchShield demo interface"
```

### Task 7: Verify X Layer Deployment Path and Publish Evidence Configuration

**Files:**
- Create after deployment: `deployments/196.json`
- Modify after deployment: `web/src/contracts.ts`
- Modify: `README.md`
- Create: `docs/submission/checklist.md`

- [ ] **Step 1: Confirm official public v4 contract addresses**

From the Uniswap v4 deployment reference, confirm for X Layer Mainnet the
`PoolManager`, Position Manager and supported swap router address needed by
the scripts/UI. Query bytecode through the X Layer RPC before sending a
transaction:

```bash
cast code --rpc-url "$X_LAYER_RPC_URL" 0x360e68faccca8ca495c1b759fd9eee466db9fb32
```

Expected: non-empty bytecode. If event support provides a verified testnet
deployment before this step, perform the same check there and document the
chosen chain; do not invent an unsupported testnet address.

- [ ] **Step 2: Run full local release checks**

Run:

```bash
forge fmt --check
forge test -vvv
cd web && pnpm test && pnpm build
```

Expected: all checks pass before public deployment.

- [ ] **Step 3: Pause only for user-controlled signing/funding**

Request from the user only what cannot be performed autonomously:

- An EVM wallet selected for X Layer and funded with minimal `OKB` gas if
  Mainnet is required.
- Import/signing through a secure Foundry keystore or user wallet; never ask
  the user to paste a raw private key in chat.
- Approval before spending real Mainnet gas/liquidity.

- [ ] **Step 4: Deploy, capture evidence, and wire the page**

Using the approved wallet signing flow, broadcast the token, Hook, pool, and
demo transaction scripts. Write `deployments/196.json` in this shape:

```json
{
  "chainId": 196,
  "network": "X Layer Mainnet",
  "poolManager": "0x360e68faccca8ca495c1b759fd9eee466db9fb32",
  "hook": "0x...",
  "poolId": "0x...",
  "token0": "0x...",
  "token1": "0x...",
  "normalSwapTx": "0x...",
  "volatilitySwapTx": "0x..."
}
```

Point the web configuration and README at the real manifest and explorer
links. Do not commit wallet files, `.env`, broadcast secrets, or raw keys.

- [ ] **Step 5: Commit deployment evidence**

Run:

```bash
git add deployments/196.json README.md web/src/contracts.ts docs/submission/checklist.md
git commit -m "docs: publish X Layer LaunchShield evidence"
```

### Task 8: Prepare Submission Assets and Final Verification

**Files:**
- Modify: `README.md`
- Modify: `docs/submission/checklist.md`

- [ ] **Step 1: Write the exact demo/video runbook**

Document a video script with this sequence:

```text
0:00-0:20 Problem and LaunchShield mechanism
0:20-0:40 Deployed Hook, pool, thresholds and explorer verification
0:40-1:10 Normal Buy succeeds under Normal / 0.30%
1:10-1:40 Trigger Large Swap is prevented by movement cap
1:40-2:10 Trigger Volatility settles and subsequent fee shows Guarded / 1.00%
2:10-2:40 Links, limitations and X Layer value
```

- [ ] **Step 2: Prepare user-owned submission actions**

Write a proposed X post in `docs/submission/checklist.md` that mentions
`@XLayerOfficial`, `@Uniswap`, and `@flapdotsh`, plus fields for the Google
Form submission. These actions remain with the user because they publish under
their identity/account.

- [ ] **Step 3: Run final evidence verification**

Run:

```bash
forge fmt --check
forge test -vvv
cd web && pnpm test && pnpm build
git status --short
```

Expected: tests/build pass and no unexpected secret or generated-file changes
are staged.

- [ ] **Step 4: Commit final submission documentation**

Run:

```bash
git add README.md docs/submission/checklist.md
git commit -m "docs: finalize LaunchShield submission package"
```

## Plan Self-Review

- Spec coverage: Hook behavior, deployment uncertainty, demonstration page,
  testing, honest limitations, demo video, social requirements, and on-chain
  evidence each map to a task above.
- Scope check: the implementation remains one Hook-enabled demonstration pool
  and one web page; no platform or backend is introduced.
- Type/state consistency: `PoolProtection`, `effectiveFee`,
  `launchProtectionActive`, `effectiveMovementCap`, `MovementCapExceeded`, and
  `GuardedModeActivated` are the shared names used across contract tests, UI,
  and README.
- Deployment safety: no public transaction is sent without verified bytecode,
  user-controlled signing, and user approval for real funds.
