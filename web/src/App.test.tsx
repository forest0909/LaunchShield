import { cleanup, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it } from "vitest";
import type { Hex } from "viem";

import App, { PublishedTransactions } from "./App";
import { deployment, deploymentTransactions } from "./contracts";

afterEach(() => {
  cleanup();
});

describe("LaunchShield interface", () => {
  it("presents deployed testnet evidence while wallet actions stay gated", () => {
    render(<App />);

    expect(screen.getByRole("heading", { name: "Protected launches, enforced in the pool." })).toBeInTheDocument();
    expect(screen.getByText(deployment?.poolId ?? "")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /view contract/i })).toHaveAttribute(
      "href",
      `https://www.okx.com/web3/explorer/xlayer-test/address/${deployment?.hook}`,
    );
    expect(screen.getByRole("button", { name: "Normal Buy" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Trigger Large Swap" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Trigger Volatility" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Switch to X Layer Testnet" })).toBeInTheDocument();
    expect(screen.getByText(/Does not prevent bots, MEV, or price loss/)).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /verify normal buy transaction/i })).toHaveAttribute(
      "href",
      `https://www.okx.com/web3/explorer/xlayer-test/tx/${deploymentTransactions.normalSwap}`,
    );
  });

  it("links submitted deployment and demonstration transactions to explorer evidence", () => {
    const hash = `0x${"1".repeat(64)}` as Hex;

    render(
      <PublishedTransactions
        transactions={{
          launchTokenDeployment: hash,
          quoteTokenDeployment: hash,
          hookDeployment: null,
          poolInitialization: hash,
          normalSwap: hash,
          volatilityTrigger: hash,
        }}
      />,
    );

    expect(screen.getByRole("link", { name: /verify XSH deployment transaction/i })).toHaveAttribute(
      "href",
      `https://www.okx.com/web3/explorer/xlayer-test/tx/${hash}`,
    );
    expect(screen.getByRole("link", { name: /verify mUSDC deployment transaction/i })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /verify pool initialization transaction/i })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /verify normal buy transaction/i })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /verify volatility trigger transaction/i })).toBeInTheDocument();
    expect(screen.queryByRole("link", { name: /verify Hook deployment transaction/i })).not.toBeInTheDocument();
  });
});
