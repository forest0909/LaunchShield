# LaunchShield Submission Checklist

Event: X Layer Build X Hackathon - Hook the Future

Submission deadline: **2026-05-28 23:59 UTC / 2026-05-29 07:59 Asia/Shanghai**

## Ready In Repository

- LaunchShield Hook with deterministic behavior tests.
- Demo `XSH` and `mUSDC` tokens and X Layer deployment scripts.
- Verified X Layer Mainnet v4 infrastructure configuration.
- React interface with wallet flow, state reads, demo actions, explorer links,
  and prevented-attempt error decoding.
- Cloudflare Pages Direct Upload configuration for a public demo URL after
  account authorization.
- Visual concept and browser-captured predeployment UI in `web/design/`.

## Must Be Completed With User-Controlled Accounts

- Select a public EVM wallet address and fund it with minimal X Layer Mainnet
  OKB gas.
- Import that wallet into a local encrypted Foundry keystore; do not share its
  secret material.
- Sign the deployment and demo transactions from the README runbook.
- Fill real token, Hook, Pool ID, and transaction hashes into
  `web/src/deployments/196.json`.
- Authorize a hosting account and publish the configured Pages interface; add
  the resulting public demo URL to the post and form.
- Create or use the project's independent X account and publish the required
  submission post mentioning `@XLayerOfficial @Uniswap @flapdotsh`.
- Record/upload the optional demo video and submit the official Google Form.

## Evidence To Capture After Broadcast

| Field | Value |
| --- | --- |
| Network | X Layer Mainnet (`196`) |
| Public demo URL | `TBD after hosting account authorization` |
| Public source repository | `TBD after repository publication` |
| PoolManager | `0x360E68faCcca8cA495c1B759Fd9EEe466db9FB32` |
| PositionManager | `0xcF1EAFC6928dC385A342E7C6491d371d2871458b` |
| Demo router | `0xE4e6CAdE3E2a67F16A5d867C44e1e7Df02f0fc03` |
| XSH token | `TBD after user-signed deployment` |
| mUSDC token | `TBD after user-signed deployment` |
| LaunchShield Hook | `TBD after user-signed deployment` |
| Protected Pool ID | `TBD after pool initialization` |
| XSH deployment tx | `TBD` |
| mUSDC deployment tx | `TBD` |
| Hook deployment tx | `TBD` |
| Pool/liquidity tx | `TBD` |
| Normal swap tx | `TBD` |
| Volatility trigger tx | `TBD` |

For the rejected large-swap action, the interface intentionally performs
simulation after allowance approval and reports the Hook's decoded protection
reason without sending a knowingly reverting swap transaction.

Copy the confirmed hashes into `web/src/deployments/196.json` as
`transactions.launchTokenDeployment`, `transactions.quoteTokenDeployment`,
`transactions.hookDeployment`, `transactions.poolInitialization`,
`transactions.normalSwap`, and `transactions.volatilityTrigger`; the page
will expose them as explorer evidence links.

## Form Copy

**Project name:** LaunchShield

**One-line description:**

LaunchShield is a Uniswap v4 Hook protected launch pool on X Layer that rejects
excessive early single-swap price movement and automatically raises LP fees
after accepted volatility.

**Problem:**

New token pools begin with thin liquidity, so one extreme early swap can
distort price discovery and increase LP risk. Existing launches often expose
rules only through UI promises instead of enforceable pool behavior.

**Solution and Hook mechanism:**

LaunchShield makes the rule enforceable inside the v4 pool. For the first
30 minutes, its Hook atomically rejects a swap if that single swap would move
the pool tick beyond the active cap. An accepted volatile swap activates
Guarded mode for ten minutes, raising the dynamic LP fee from 0.30% to 1.00%
and applying a tighter protected-period cap to subsequent trades.

**Innovation and market value:**

The product combines a transparent launch-period circuit breaker with
automatic fee compensation for LPs, directly at the pool layer. Issuers can
launch under published rules, traders can independently verify them, and LPs
are compensated when accepted trading indicates greater volatility.

**Honest limitation:**

LaunchShield limits single-swap pool price movement and adjusts LP fees. It
does not prevent bots, MEV, Sybil behavior, or financial loss.

**Tech stack:**

Solidity, Uniswap v4 Hook callbacks, OpenZeppelin Hooks base, Foundry,
X Layer Mainnet, React, Vite, and viem.

## Required Social Draft

Use the project's independent X account and replace the placeholders:

```text
We built LaunchShield for the Build X Hackathon: a Uniswap v4 Hook on X Layer
that rejects oversized early pool movements and raises LP fees after accepted
volatility.

Hook: [HOOK_ADDRESS]
Demo: [DEMO_URL]
Repo: [REPOSITORY_URL]

@XLayerOfficial @Uniswap @flapdotsh
```

## Demo Video Storyboard (90 Seconds)

| Time | Shot | Narration |
| --- | --- | --- |
| 0:00-0:12 | Title and problem | Thin launch pools can be distorted by one excessive early trade. |
| 0:12-0:27 | Explorer evidence and UI | LaunchShield is deployed as a v4 Hook on X Layer; show Hook and Pool links. |
| 0:27-0:42 | `Normal Buy` | A small mUSDC-to-XSH buy settles at the normal 0.30% fee. |
| 0:42-0:58 | `Trigger Large Swap` | The attempted large trade is prevented by the active movement cap; no swap settles. |
| 0:58-1:15 | `Trigger Volatility` | An accepted volatile trade activates Guarded mode and future fee reads show 1.00%. |
| 1:15-1:30 | Limitation and close | This is transparent pool-level protection, not bot or MEV elimination. |

## Final Form Submission

Official submission form from the event page:
[Google Form](https://docs.google.com/forms/d/e/1FAIpQLSdH_ZfkA7qREpVciUrTVBy9zZHssvBgbvATVzkt0Sog_usq2Q/viewform?usp=dialog)

Before pressing submit, confirm:

- Contract and pool addresses resolve on an X Layer explorer.
- Repository and hosted demo links are public.
- The X post is live and includes all three required mentions.
- Demo video URL is accessible without requesting permission, if provided.
- All claims match actual transaction behavior and the limitation statement.
