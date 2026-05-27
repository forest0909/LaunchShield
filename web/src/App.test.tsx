import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import type { Hex } from "viem";

import App, { PublishedTransactions } from "./App";

describe("LaunchShield interface", () => {
  it("presents the honest pre-deployment demonstration workflow", () => {
    render(<App />);

    expect(screen.getByRole("heading", { name: "Protected launches, enforced in the pool." })).toBeInTheDocument();
    expect(screen.getAllByText("Awaiting public deployment")).toHaveLength(3);
    expect(screen.getByRole("button", { name: "Normal Buy" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Trigger Large Swap" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Trigger Volatility" })).toBeDisabled();
    expect(screen.getByText(/Does not prevent bots, MEV, or price loss/)).toBeInTheDocument();
    expect(screen.getByText("No public demo transactions published yet.")).toBeInTheDocument();
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
      `https://www.oklink.com/xlayer/tx/${hash}`,
    );
    expect(screen.getByRole("link", { name: /verify mUSDC deployment transaction/i })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /verify pool initialization transaction/i })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /verify normal buy transaction/i })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /verify volatility trigger transaction/i })).toBeInTheDocument();
    expect(screen.queryByRole("link", { name: /verify Hook deployment transaction/i })).not.toBeInTheDocument();
  });
});
