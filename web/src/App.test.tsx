import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import App from "./App";

describe("LaunchShield interface", () => {
  it("presents the honest pre-deployment demonstration workflow", () => {
    render(<App />);

    expect(screen.getByRole("heading", { name: "Protected launches, enforced in the pool." })).toBeInTheDocument();
    expect(screen.getAllByText("Awaiting public deployment")).toHaveLength(3);
    expect(screen.getByRole("button", { name: "Normal Buy" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Trigger Large Swap" })).toBeDisabled();
    expect(screen.getByRole("button", { name: "Trigger Volatility" })).toBeDisabled();
    expect(screen.getByText(/Does not prevent bots, MEV, or price loss/)).toBeInTheDocument();
  });
});
