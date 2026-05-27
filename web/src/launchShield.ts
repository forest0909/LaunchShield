import {
  createPublicClient,
  createWalletClient,
  custom,
  decodeErrorResult,
  http,
  type Address,
  type EIP1193Provider,
  type Hex,
} from "viem";

import {
  DYNAMIC_FEE_FLAG,
  EXPLORER_URL,
  TICK_SPACING,
  X_LAYER_CHAIN_ID,
  X_LAYER_RPC_URL,
  demoRouterAbi,
  deployment,
  erc20Abi,
  hookAbi,
  infrastructure,
  wrappedErrorAbi,
  type LaunchShieldDeployment,
} from "./contracts";
import type { ProtectionSnapshot } from "./presentation";

export type DemoAction = "normal" | "oversized" | "volatility";

const ACTION_AMOUNTS: Record<DemoAction, bigint> = {
  normal: 100_000_000_000_000_000n,
  oversized: 2_000_000_000_000_000_000n,
  volatility: 1_200_000_000_000_000_000n,
};

const xLayer = {
  id: X_LAYER_CHAIN_ID,
  name: "X Layer Mainnet",
  nativeCurrency: { name: "OKB", symbol: "OKB", decimals: 18 },
  rpcUrls: {
    default: { http: [X_LAYER_RPC_URL] },
  },
  blockExplorers: {
    default: { name: "OKLink", url: EXPLORER_URL },
  },
} as const;

const publicClient = createPublicClient({
  chain: xLayer,
  transport: http(),
});

function injectedProvider() {
  return (window as Window & { ethereum?: EIP1193Provider }).ethereum;
}

function walletClient() {
  const provider = injectedProvider();
  if (!provider) throw new Error("No injected wallet was found.");
  return createWalletClient({ chain: xLayer, transport: custom(provider) });
}

export async function connectWallet() {
  const accounts = await walletClient().requestAddresses();
  return accounts[0];
}

export async function currentChainId() {
  const provider = injectedProvider();
  if (!provider) return null;
  const value = await provider.request({ method: "eth_chainId" });
  return Number.parseInt(value as string, 16);
}

export async function switchToXLayer() {
  const wallet = walletClient();
  try {
    await wallet.switchChain({ id: xLayer.id });
  } catch {
    await wallet.addChain({ chain: xLayer });
    await wallet.switchChain({ id: xLayer.id });
  }
}

export async function readProtectionSnapshot(target: LaunchShieldDeployment) {
  const [fee, movementCap, launchActive, state, launchDuration, cooldown] = await Promise.all([
    publicClient.readContract({
      address: target.hook,
      abi: hookAbi,
      functionName: "effectiveFee",
      args: [target.poolId],
    }),
    publicClient.readContract({
      address: target.hook,
      abi: hookAbi,
      functionName: "effectiveMovementCap",
      args: [target.poolId],
    }),
    publicClient.readContract({
      address: target.hook,
      abi: hookAbi,
      functionName: "launchProtectionActive",
      args: [target.poolId],
    }),
    publicClient.readContract({
      address: target.hook,
      abi: hookAbi,
      functionName: "protection",
      args: [target.poolId],
    }),
    publicClient.readContract({ address: target.hook, abi: hookAbi, functionName: "LAUNCH_DURATION" }),
    publicClient.readContract({ address: target.hook, abi: hookAbi, functionName: "GUARDED_COOLDOWN" }),
  ]);

  return {
    fee,
    movementCap,
    launchActive,
    launchTime: state[0],
    guardedUntil: state[1],
    initialized: state[3],
    launchDuration,
    cooldown,
  } satisfies ProtectionSnapshot;
}

export async function submitDemoAction(action: DemoAction, account: Address) {
  if (!deployment) throw new Error("The public pool has not been deployed.");

  const amountIn = ACTION_AMOUNTS[action];
  const inputToken = demoInputToken(deployment);
  const wallet = walletClient();
  const approvalHash = await wallet.writeContract({
    account,
    chain: xLayer,
    address: inputToken,
    abi: erc20Abi,
    functionName: "approve",
    args: [infrastructure.demoRouter, amountIn],
  });
  await publicClient.waitForTransactionReceipt({ hash: approvalHash });

  const zeroForOne = inputToken.toLowerCase() === deployment.currency0.toLowerCase();
  const poolKey = {
    currency0: deployment.currency0,
    currency1: deployment.currency1,
    fee: DYNAMIC_FEE_FLAG,
    tickSpacing: TICK_SPACING,
    hooks: deployment.hook,
  } as const;

  try {
    const { request } = await publicClient.simulateContract({
      account,
      address: infrastructure.demoRouter,
      abi: demoRouterAbi,
      functionName: "swapExactTokensForTokens",
      args: [amountIn, 0n, zeroForOne, poolKey, "0x", account, BigInt(Math.floor(Date.now() / 1000) + 300)],
    });
    const hash = await wallet.writeContract(request);
    const receipt = await publicClient.waitForTransactionReceipt({ hash });
    if (receipt.status !== "success") throw new Error("Swap transaction reverted.");
    return { status: "success" as const, hash };
  } catch (error) {
    if (isMovementCapError(error)) return { status: "prevented" as const };
    throw error;
  }
}

export function demoInputToken(target: LaunchShieldDeployment) {
  return target.quoteToken;
}

export function isMovementCapError(error: unknown) {
  for (const data of collectHexValues(error)) {
    try {
      const decoded = decodeErrorResult({ abi: wrappedErrorAbi, data });
      if (decoded.errorName !== "WrappedError") continue;
      const reason = decoded.args[2];
      const nested = decodeErrorResult({ abi: hookAbi, data: reason });
      if (nested.errorName === "MovementCapExceeded") return true;
    } catch {
      // Keep looking through nested viem errors for encoded revert data.
    }
  }
  return false;
}

function collectHexValues(value: unknown, depth = 0, seen = new Set<unknown>()): Hex[] {
  if (depth > 5 || seen.has(value)) return [];
  seen.add(value);

  if (typeof value === "string") {
    const matches = value.match(/0x[0-9a-fA-F]{8,}/g) ?? [];
    return matches as Hex[];
  }
  if (!value || typeof value !== "object") return [];

  const error = value as Record<string, unknown>;
  const keys = ["data", "cause", "details", "message", "shortMessage", "metaMessages"];
  return keys.flatMap((key) => collectHexValues(error[key], depth + 1, seen));
}
