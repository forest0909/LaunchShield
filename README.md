# LaunchShield

LaunchShield is a Uniswap v4 Hook-powered protected launch pool for new assets
on X Layer. During the launch window it blocks swaps that move the pool spot
price beyond a published limit; after accepted volatile swaps it increases LP
fees for a cooldown period.

LaunchShield does not promise bot prevention, Sybil resistance, MEV
elimination, or price stability. It enforces transparent pool-level rules.

## Local contract verification

```bash
npm install
npm run test:contracts
```

The repository uses the official Uniswap v4 interfaces and OpenZeppelin Hook
base packages with Foundry binaries installed from locked npm dependencies.

## Deployment status

The confirmed public v4 path is X Layer Mainnet (`chainId 196`), where the
official Uniswap deployment lists:

| Contract | Address |
| --- | --- |
| PoolManager | `0x360e68faccca8ca495c1b759fd9eee466db9fb32` |
| PositionManager | `0xcf1eafc6928dc385a342e7c6491d371d2871458b` |
| StateView | `0x76fd297e2d437cd7f76d50f01afe6160f86e9990` |
| Universal Router | `0xda00ae15d3a71466517129255255db7c0c0956d3` |
| Permit2 | `0x000000000022D473030F116dDEE9F6B43aC78BA3` |

The official deployment listing does not currently provide an X Layer Testnet
v4 deployment. Public transactions will be prepared for a minimal-value
mainnet demo and broadcast only through a user-controlled wallet signing flow.

Never place wallet private keys in this repository or in shell command
arguments.
