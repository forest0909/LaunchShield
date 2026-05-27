# LaunchShield Product Design

Date: 2026-05-27
Status: Approved for specification review
Event: X Layer Build X Hackathon - Hook the Future

## 1. Objective

LaunchShield is a Uniswap v4 Hook-powered launch pool for newly issued assets on
X Layer. It reduces extreme early pool price movement and compensates liquidity
providers during short periods of elevated volatility.

The hackathon objective is a deployed, verifiable, demonstrable MVP with a
clear market story rather than a broad launch platform.

### One-line pitch

LaunchShield gives new assets a transparent protected launch pool: oversized
early swaps are stopped, while volatile periods automatically pay LPs a higher
fee.

## 2. Hackathon Constraints

The product is designed around the following event requirements:

- Development must use the Uniswap v4 Hook mechanism and deploy on X Layer.
- Submission must include verifiable v4 Pool and Hook contract information.
- The project must have an independent X account and mention
  `@XLayerOfficial`, `@Uniswap`, and `@flapdotsh` during submission-related
  social activity.
- The submission deadline is 2026-05-28 23:59 UTC, which is
  2026-05-29 07:59 in Asia/Shanghai.
- Judges evaluate innovation, potential market value, and completion. A
  one-to-three-minute demo video is an optional scoring advantage.

The workspace was empty when this design was created, so the MVP is scoped for
new implementation with minimal integration dependencies.

## 3. Product Positioning

### Problem

New token pools begin with thin liquidity and high sensitivity to early swaps.
A single large trade or a rapid price move can make the launch appear broken,
increase LP risk, and discourage legitimate traders.

### Value proposition

LaunchShield makes launch-period risk visible and enforceable at the pool
level:

- Issuers receive a more orderly initial trading environment.
- LPs receive higher fees while accepted swaps indicate elevated volatility.
- Traders see the current rules and on-chain evidence rather than relying on
  undisclosed controls.

### Honest product claim

LaunchShield limits abnormal pool price movement and adjusts fees. It does not
promise bot prevention, Sybil resistance, MEV elimination, or price stability.

## 4. Users and Demo Journey

### Primary users

- Asset issuers launching an early liquidity pool.
- LPs accepting launch-period inventory and volatility risk.
- Traders deciding whether to trade under transparent protection rules.

### Demonstration journey

1. An issuer creates an `XSH / MockUSDC` Uniswap v4 pool with LaunchShield.
2. The page shows the pool, Hook address, launch protection status, base fee,
   and active price-movement limit.
3. A user submits a small `Normal Buy`; it settles successfully while the pool
   remains in `Normal` mode.
4. A user submits `Trigger Large Swap`; during launch protection the attempted
   swap exceeds the movement cap and the entire transaction reverts with a
   clear protection reason.
5. A user submits an accepted trade with sufficient price movement to cross the
   volatility trigger; it settles and places subsequent swaps into `Guarded`
   fee mode.
6. The page displays the elevated fee, the reason and expiry of `Guarded`
   mode, contract links, and transaction evidence.
7. When the cooldown or launch period has expired, the page shows the resulting
   relaxed state.

## 5. MVP Scope

### Included

- One LaunchShield Hook instance for one demonstration pool.
- Two mock ERC-20 demonstration assets.
- Pool initialization and initial liquidity scripts.
- A single-page interface with wallet connection, state reads, and three
  deterministic demo actions.
- Contract tests and a repeatable deployment/demo runbook.
- Submission README, address manifest, social post, and demo video.

### Excluded

- A multi-issuer token launch platform.
- Token sale, allocation, whitelist, vesting, or fundraising features.
- Wallet-level anti-bot restrictions.
- Analytics databases, indexed historical charts, or backend services.
- Integration that depends on external launchpad or aggregator APIs.
- Use of real project assets or claims of financial protection.

## 6. Hook Behavioral Requirements

### Terminology

The product may describe an oversized trade as excessive price impact. The
enforced on-chain metric is specifically the absolute pool spot-price movement
between the start and end of a single swap, expressed through the pool price or
equivalent tick movement. This distinction must be visible in technical
documentation.

### Deployment configuration

The MVP uses public, readable configuration values set at deployment:

| Parameter | Demo Value | Purpose |
| --- | ---: | --- |
| Launch protection duration | 30 minutes | Time when single-swap movement caps apply |
| Base dynamic LP fee | 0.30% | Default trade fee |
| Guarded dynamic LP fee | 1.00% | LP risk compensation after volatility trigger |
| Normal movement cap | 3.00% | Max accepted single-swap pool price movement in protected `Normal` mode |
| Guarded movement cap | 1.50% | Max accepted single-swap pool price movement in protected `Guarded` mode |
| Volatility trigger | 2.00% | Accepted single-swap movement that activates `Guarded` mode |
| Guarded cooldown | 10 minutes | Duration for the elevated fee after the latest trigger |

The implementation may encode percentage thresholds as tick or square-root
price bounds, but displayed values and tested behavior must match these public
rules.

### Impact Guard

- Impact Guard is active only during the launch protection duration.
- While mode is `Normal`, a swap that would move pool spot price by more than
  3.00% atomically reverts.
- While mode is `Guarded`, a swap that would move pool spot price by more than
  1.50% atomically reverts.
- The revert exposes a machine-readable custom error that the page maps to a
  clear user explanation.
- A rejected swap does not update observed price, volatility state, cooldown,
  or fee mode.
- After launch protection expires, LaunchShield no longer rejects swaps based
  on the movement cap.

The contract implementation must enforce this invariant atomically within the
swap transaction. The implementation plan must validate the precise v4
callback/state-reading mechanism before feature code is committed.

### Volatility Fee

- Volatility Fee remains active after launch protection expires.
- The fee charged to a swap is based on the mode established before that swap:
  `Normal` charges 0.30%; `Guarded` charges 1.00%.
- After an accepted swap, if its single-swap spot-price movement is at least
  2.00%, the pool enters `Guarded` mode for 10 minutes.
- A later accepted qualifying swap extends `guardedUntil` by resetting it to
  ten minutes after that swap.
- If `guardedUntil` has passed before a later swap begins, that swap is charged
  at the normal fee and the visible mode returns to `Normal`.

This sequencing is deliberate: the trade that demonstrates volatility succeeds
under its pre-existing fee, and elevated fees apply to subsequent trades.

## 7. Contract State and Data Flow

### Observable state

The Hook must expose enough information for the page and block explorer-based
verification:

- Pool association and Hook address.
- `launchTime` and calculated launch protection expiry.
- Current effective mode: `Normal` or `Guarded`.
- `guardedUntil`.
- Current effective fee.
- Deployment-configured thresholds and durations.
- Events for a volatility trigger and mode-affecting activity.

### Transaction flow

1. The interface reads Hook configuration and current effective state.
2. The trader submits a swap through the demonstration integration.
3. Before execution, the Hook selects the effective dynamic fee for that swap.
4. The pool executes the attempted swap.
5. The Hook determines the start-to-end pool price movement.
6. If launch-period cap rules are violated, the transaction reverts atomically.
7. If the accepted swap crosses the volatility trigger, the Hook records the
   new guarded expiry and emits evidence for the page.
8. The page refreshes state and links the accepted transaction or explains a
   reverted protection attempt.

No backend, keeper, off-chain oracle, AI service, or historical indexer is
required for core behavior.

## 8. Interface Design

### Single-page content

- Product title and one-sentence value proposition.
- Network and wallet connection status.
- Pool card: pair, Pool identifier, Hook address, and explorer links.
- Protection status card: launch status, time remaining, mode, fee, active
  movement cap, and guarded cooldown.
- Three demo controls:
  - `Normal Buy`: a preconfigured accepted small swap.
  - `Trigger Large Swap`: a preconfigured attempted swap expected to be
    rejected during launch protection.
  - `Trigger Volatility`: a preconfigured accepted swap expected to enter
    `Guarded` mode.
- Activity/result panel: pending status, success transaction hash or decoded
  protection error, refreshed state, and explorer verification links.
- Limitations statement that accurately narrows the product claim.

### UX acceptance requirements

- The page never displays a successful protection event for a reverted trade as
  if it had settled; it labels it as a prevented attempt.
- Fee and threshold values match contract configuration reads rather than
  duplicated UI constants.
- The demo path can be executed in sequence from a freshly initialized pool
  without manual parameter editing.

## 9. Deployment and Submission Strategy

### Deployment blocker to resolve first

The implementation phase must begin by verifying whether a usable Uniswap v4
`PoolManager` exists on X Layer Testnet. The currently confirmed official v4
deployment is on X Layer Mainnet. The product must not assume testnet support
without contract-address verification.

### Deployment paths

1. Preferred: use an official or event-confirmed v4 deployment on X Layer
   Testnet with faucet-funded assets.
2. Fallback: if testnet cannot satisfy event-verifiable v4 requirements, deploy
   a tightly scoped, low-value demonstration pool against the confirmed
   X Layer Mainnet v4 deployment after confirming wallet funding and transaction
   cost.

### Required submission evidence

- Hook contract address and verification link.
- Pool identifier and supporting on-chain initialization evidence.
- Mock asset addresses.
- Transactions demonstrating normal swap and volatility activation.
- Evidence of a reverted oversized-swap attempt, captured in the page/video and
  reproducible from provided steps.
- Source repository and README explaining configuration, limitations, and demo.
- Hosted page or runnable local demonstration instructions.
- One-to-three-minute demo video.
- Independent X account and event-compliant social post.

## 10. Validation and Testing

### Contract tests

- Pool initializes with the configured launch time and `Normal` fee.
- Small accepted swap uses 0.30% fee and retains `Normal` mode.
- During launch protection, a swap above the 3.00% normal cap reverts without
  modifying state.
- During launch protection, an accepted 2.00%-to-3.00% movement swap activates
  `Guarded` mode.
- Subsequent swap during cooldown uses the 1.00% fee.
- During protected `Guarded` mode, a swap above the 1.50% cap reverts.
- Accepted trigger transactions extend the guarded cooldown when applicable.
- Once cooldown has expired, the next swap uses the base fee and state reads as
  `Normal`.
- After launch protection expires, movement-cap rejection is disabled while a
  qualifying accepted movement can still activate guarded fees.

### Page and integration tests

- Contract-derived configuration and effective mode render correctly.
- Wallet/network errors are explicit.
- Each demo control produces its intended accepted or rejected behavior from a
  clean initialized pool.
- Custom revert reasons display in human-readable text.
- Successful activity renders transaction and contract explorer links.

### Demo acceptance test

In under three minutes, the video must show the problem, deployed pool and
Hook, successful normal trade, prevented oversized attempt, dynamic-fee
transition, and on-chain verification links.

## 11. Delivery Priority and Risks

### Priority order

1. Verify v4 deployment availability on X Layer and deployable wallet path.
2. Implement and test verifiable Hook behavior.
3. Deploy Pool and produce deterministic on-chain evidence.
4. Build the minimal page and record the demo.
5. Complete README, X post, and form submission.
6. Add visual polish only if all evidence is complete.

### Principal risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| No usable v4 PoolManager on testnet | Demo cannot satisfy submission deployment requirement | Resolve first; switch to low-value mainnet pool if required |
| Atomic movement-cap enforcement is not feasible through selected callback design | Core product promise fails | Validate exact v4 mechanism before implementation; do not ship a misleading UI |
| Demo liquidity and trade sizing do not reliably hit thresholds | Video and judging evidence become weak | Use fixed initial liquidity and deterministic scripted/button trade amounts |
| Time is spent on platform features or visual polish | Verifiable completion suffers | Enforce excluded scope and priority order |
| Users overinterpret product as anti-bot/security guarantee | Credibility and judging risk | Display explicit limitation wording in README and page |

## 12. Sources

- Event page: <https://web3.okx.com/zh-hans/xlayer/build-x-hackathon/hook>
- Uniswap v4 deployment reference:
  <https://developers.uniswap.org/docs/protocols/v4/deployments>
- X Layer developer documentation:
  <https://web3.okx.com/xlayer/docs/developer/rpc-endpoints/rpc-endpoints>
- X Layer testnet faucet documentation:
  <https://web3.okx.com/xlayer/docs/developer/bridge/get-testnet-okb-from-faucet>

