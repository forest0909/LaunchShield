import type { Hex } from "viem";

export interface ProtectionSnapshot {
  fee: number;
  movementCap: number;
  launchActive: boolean;
  launchTime: bigint;
  guardedUntil: bigint;
  launchDuration: bigint;
  cooldown: bigint;
  initialized: boolean;
}

export interface ActivityResult {
  tone: "idle" | "pending" | "success" | "prevented" | "error";
  title: string;
  detail: string;
  hash?: Hex;
}

export function formatFee(fee: number) {
  return `${(fee / 10_000).toFixed(2)}%`;
}

export function formatCap(cap: number) {
  const approximatePercent = (Math.expm1(cap * Math.log(1.0001)) * 100).toFixed(1);
  return `~${approximatePercent}% (${cap} ticks)`;
}

export function formatCountdown(until: bigint, now = Date.now()) {
  const seconds = Math.max(0, Number(until) - Math.floor(now / 1000));
  const minutes = Math.floor(seconds / 60).toString().padStart(2, "0");
  const remainder = (seconds % 60).toString().padStart(2, "0");
  return `${minutes}:${remainder}`;
}
