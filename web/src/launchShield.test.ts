import { encodeErrorResult } from "viem";
import { describe, expect, it } from "vitest";

import { hookAbi, infrastructure, wrappedErrorAbi } from "./contracts";
import { demoInputToken, isMovementCapError } from "./launchShield";

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

  it("spends quote tokens for demonstration buys", () => {
    const quoteToken = "0x0000000000000000000000000000000000000022";

    expect(
      demoInputToken({
        hook: "0x0000000000000000000000000000000000000001",
        poolId: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
        launchToken: "0x0000000000000000000000000000000000000011",
        quoteToken,
        currency0: "0x0000000000000000000000000000000000000011",
        currency1: quoteToken,
      }),
    ).toBe(quoteToken);
  });
});
