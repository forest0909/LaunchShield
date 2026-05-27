import type { Address, Hex } from "viem";

import deploymentRecord from "./deployments/196.json";

export const X_LAYER_CHAIN_ID = 196;
export const X_LAYER_RPC_URL = "https://rpc.xlayer.tech";
export const EXPLORER_URL = "https://www.oklink.com/xlayer";

export const infrastructure = {
  poolManager: deploymentRecord.poolManager as Address,
  positionManager: deploymentRecord.positionManager as Address,
  stateView: deploymentRecord.stateView as Address,
  universalRouter: deploymentRecord.universalRouter as Address,
  permit2: deploymentRecord.permit2 as Address,
  demoRouter: deploymentRecord.demoRouter as Address,
} as const;

export interface LaunchShieldDeployment {
  hook: Address;
  poolId: Hex;
  launchToken: Address;
  quoteToken: Address;
  currency0: Address;
  currency1: Address;
}

export const deployment: LaunchShieldDeployment | null =
  deploymentRecord.hook &&
  deploymentRecord.poolId &&
  deploymentRecord.launchToken &&
  deploymentRecord.quoteToken &&
  deploymentRecord.currency0 &&
  deploymentRecord.currency1
    ? {
        hook: deploymentRecord.hook as Address,
        poolId: deploymentRecord.poolId as Hex,
        launchToken: deploymentRecord.launchToken as Address,
        quoteToken: deploymentRecord.quoteToken as Address,
        currency0: deploymentRecord.currency0 as Address,
        currency1: deploymentRecord.currency1 as Address,
      }
    : null;

export const DYNAMIC_FEE_FLAG = 8_388_608;
export const TICK_SPACING = 60;

export const hookAbi = [
  {
    type: "function",
    name: "effectiveFee",
    stateMutability: "view",
    inputs: [{ name: "poolId", type: "bytes32" }],
    outputs: [{ name: "fee", type: "uint24" }],
  },
  {
    type: "function",
    name: "effectiveMovementCap",
    stateMutability: "view",
    inputs: [{ name: "poolId", type: "bytes32" }],
    outputs: [{ name: "cap", type: "int24" }],
  },
  {
    type: "function",
    name: "launchProtectionActive",
    stateMutability: "view",
    inputs: [{ name: "poolId", type: "bytes32" }],
    outputs: [{ name: "active", type: "bool" }],
  },
  {
    type: "function",
    name: "protection",
    stateMutability: "view",
    inputs: [{ name: "poolId", type: "bytes32" }],
    outputs: [
      { name: "launchTime", type: "uint64" },
      { name: "guardedUntil", type: "uint64" },
      { name: "preSwapTick", type: "int24" },
      { name: "initialized", type: "bool" },
    ],
  },
  {
    type: "function",
    name: "LAUNCH_DURATION",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    type: "function",
    name: "GUARDED_COOLDOWN",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    type: "error",
    name: "MovementCapExceeded",
    inputs: [
      { name: "observedTickMove", type: "int24" },
      { name: "allowedTickMove", type: "int24" },
    ],
  },
] as const;

export const wrappedErrorAbi = [
  {
    type: "error",
    name: "WrappedError",
    inputs: [
      { name: "target", type: "address" },
      { name: "selector", type: "bytes4" },
      { name: "reason", type: "bytes" },
      { name: "details", type: "bytes" },
    ],
  },
] as const;

export const erc20Abi = [
  {
    type: "function",
    name: "approve",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "value", type: "uint256" },
    ],
    outputs: [{ name: "", type: "bool" }],
  },
] as const;

export const demoRouterAbi = [
  {
    type: "function",
    name: "swapExactTokensForTokens",
    stateMutability: "payable",
    inputs: [
      { name: "amountIn", type: "uint256" },
      { name: "amountOutMin", type: "uint256" },
      { name: "zeroForOne", type: "bool" },
      {
        name: "poolKey",
        type: "tuple",
        components: [
          { name: "currency0", type: "address" },
          { name: "currency1", type: "address" },
          { name: "fee", type: "uint24" },
          { name: "tickSpacing", type: "int24" },
          { name: "hooks", type: "address" },
        ],
      },
      { name: "hookData", type: "bytes" },
      { name: "receiver", type: "address" },
      { name: "deadline", type: "uint256" },
    ],
    outputs: [{ name: "delta", type: "int256" }],
  },
] as const;

export function addressLink(address: Address) {
  return `${EXPLORER_URL}/address/${address}`;
}

export function transactionLink(hash: Hex) {
  return `${EXPLORER_URL}/tx/${hash}`;
}
