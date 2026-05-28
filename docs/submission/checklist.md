# LaunchShield Submission Checklist

Event: X Layer Build X Hackathon - Hook the Future

Submission deadline: **2026-05-28 23:59 UTC / 2026-05-29 07:59 Asia/Shanghai**

## Ready In Repository

- LaunchShield Hook with deterministic behavior tests.
- Demo `XSH` and `mUSDC` tokens and X Layer deployment scripts.
- X Layer Testnet v4 infrastructure self-deployment script.
- React interface with wallet flow, state reads, demo actions, explorer links,
  and prevented-attempt error decoding.
- Cloudflare Pages Direct Upload configuration for a public demo URL after
  account authorization.
- Visual concept and browser-captured predeployment UI in `web/design/`.

## Must Be Completed With User-Controlled Accounts

- Use the public deployment address
  `0x740416EBA95b459cd20e7359EF21BeF9a837D9d4`, funded with X Layer Testnet
  OKB gas.
- Import that wallet into a local encrypted Foundry keystore; do not share its
  secret material.
- Sign the deployment and demo transactions from the README runbook.
- Fill real token, Hook, Pool ID, and transaction hashes into
  `web/src/deployments/1952.json`.
- Authorize a hosting account and publish the configured Pages interface; add
  the resulting public demo URL to the post and form.
- Create or use the project's independent X account and publish the required
  submission post mentioning `@XLayerOfficial @Uniswap @flapdotsh`.
- Record/upload the optional demo video and submit the official Google Form.

## Evidence To Capture After Broadcast

| Field | Value |
| --- | --- |
| Network | X Layer Testnet (`1952`) |
| Deployer | `0x740416EBA95b459cd20e7359EF21BeF9a837D9d4` |
| Public demo URL | `https://launchshield-demo.forest0909.workers.dev/` |
| Public source repository | `https://github.com/forest0909/LaunchShield` |
| Permit2 | `0x3191Fc1E303EF4e12a7DE5f5d2e8d53A0660c5b9` |
| PoolManager | `0x32222Ef5dbe193bcfb2F9B289CaA0381700961a8` |
| PositionManager | `0x8F83ea0aCaC8a5B6435a5c3606F9a3f36301f142` |
| StateView | `0x0350070c19f215bcBaD8B9562e0E8f2E801a4031` |
| Demo router | `0x32116B5C8242FF43eFdDEDA6D094097f7C155907` |
| XSH token | `0xD3641f39d9c51704cb3d7f77B5BC5d98FB15a548` |
| mUSDC token | `0xD49786798C6488f3D6e5A153fb5B77c072bb9c3C` |
| LaunchShield Hook | `0x894b5cc8625Db5250b0aB6AC4C74233066FD10C0` |
| Protected Pool ID | `0x2dd1723cd6c18fc354a90e5279aaa1d380397bfcfa9588717f36b75f4deba297` |
| XSH deployment tx | `0x24276f96de74efd2cecf3793ffd6bdf8fe4d0b08eff55ed53a427e71609742ec` |
| mUSDC deployment tx | `0x4e49a349b8ac5ce719073db9d5937e8817f0a993b58a14586ec5078947036a8a` |
| Hook deployment tx | `0xf0d9f466fff29fcd186029afa00e2ca59bc68cb52915f4980dbd4791e82fe046` |
| Pool/liquidity tx | `0x414bb5b84831dec18cc80da65ad322bfbb71b8798e591ff33f359a03b42140fe` |
| Normal swap tx | `0xb61a8e7d7f73779d90268589e6f468b7086fc32e1a5f6c5f4f6dc702a0c599bb` |
| Volatility trigger tx | `0xb110a6444493afad38e296fffd07b19fc204254c3937c05ea12850f9eb63ac27` |

For the rejected large-swap action, the interface intentionally performs
simulation after allowance approval and reports the Hook's decoded protection
reason without sending a knowingly reverting swap transaction.

Copy the confirmed hashes into `web/src/deployments/1952.json` as
`transactions.launchTokenDeployment`, `transactions.quoteTokenDeployment`,
`transactions.hookDeployment`, `transactions.poolInitialization`,
`transactions.normalSwap`, and `transactions.volatilityTrigger`; the page
will expose them as explorer evidence links.

## Form Copy

**Project name:** LaunchShield

**One-line description:**

LaunchShield is a Uniswap v4 Hook protected launch pool on X Layer Testnet that rejects
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
X Layer Testnet, React, Vite, and viem.

## Required Social Draft

Use the project's independent X account and replace the placeholders:

```text
We built LaunchShield for the Build X Hackathon: a Uniswap v4 Hook on X Layer Testnet
that rejects oversized early pool movements and raises LP fees after accepted
volatility.

Hook: 0x894b5cc8625Db5250b0aB6AC4C74233066FD10C0
Demo: https://launchshield-demo.forest0909.workers.dev/
Repo: https://github.com/forest0909/LaunchShield

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
