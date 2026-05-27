import { encodeErrorResult } from "viem";
import { describe, expect, it } from "vitest";

import { hookAbi, infrastructure, wrappedErrorAbi } from "./contracts";
import { isMovementCapError } from "./launchShield";

describe("LaunchShield revert decoding", () => {
  it("recognizes a PoolManager-wrapped movement cap rejection", () => {
    const reason = encodeErrorResult({
      abi: hookAbi,
      errorName: "MovementCapExceeded",
      args: [296, 295],
    });
    const wrapped = encodeErrorResult({
      abi: wrappedErrorAbi,
      errorName: "WrappedError",
      args: [infrastructure.poolManager, "0xfa340e56", reason, "0x"],
    });

    expect(isMovementCapError({ data: wrapped })).toBe(true);
    expect(isMovementCapError({ data: "0xdeadbeef" })).toBe(false);
  });
});
