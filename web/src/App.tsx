import { useCallback, useEffect, useState, type ReactNode } from "react";
import type { Address } from "viem";

import { addressLink, deployment, infrastructure, transactionLink } from "./contracts";
import {
  formatCap,
  formatCountdown,
  formatFee,
  type ActivityResult,
  type ProtectionSnapshot,
} from "./presentation";
import type { DemoAction } from "./launchShield";

const initialActivity: ActivityResult = {
  tone: "idle",
  title: "No demo transaction yet",
  detail: "Connect a wallet after public deployment to run a verifiable swap.",
};

export default function App() {
  const [account, setAccount] = useState<Address | null>(null);
  const [chainId, setChainId] = useState<number | null>(null);
  const [snapshot, setSnapshot] = useState<ProtectionSnapshot | null>(null);
  const [activity, setActivity] = useState(initialActivity);
  const [busy, setBusy] = useState(false);

  const refresh = useCallback(async () => {
    if (!deployment) return;
    try {
      const { readProtectionSnapshot } = await import("./launchShield");
      setSnapshot(await readProtectionSnapshot(deployment));
    } catch {
      setActivity({
        tone: "error",
        title: "State read unavailable",
        detail: "The configured Hook could not be read from X Layer RPC.",
      });
    }
  }, []);

  useEffect(() => {
    void refresh();
  }, [refresh]);

  async function handleConnect() {
    try {
      const { connectWallet, currentChainId } = await import("./launchShield");
      setAccount(await connectWallet());
      setChainId(await currentChainId());
    } catch (error) {
      setActivity({ tone: "error", title: "Wallet connection failed", detail: errorMessage(error) });
    }
  }

  async function handleNetworkSwitch() {
    try {
      const { switchToXLayer } = await import("./launchShield");
      await switchToXLayer();
      setChainId(196);
      await refresh();
    } catch (error) {
      setActivity({ tone: "error", title: "Network switch failed", detail: errorMessage(error) });
    }
  }

  async function handleAction(action: DemoAction) {
    if (!account || !deployment) return;
    setBusy(true);
    setActivity({
      tone: "pending",
      title: "Preparing signed demo action",
      detail: "Approve the demonstration token allowance, then confirm the swap simulation and transaction.",
    });

    try {
      const { submitDemoAction } = await import("./launchShield");
      const result = await submitDemoAction(action, account);
      if (result.status === "prevented") {
        setActivity({
          tone: "prevented",
          title: "Prevented attempt",
          detail: "This swap would move the launch pool beyond its active limit. No swap was settled.",
        });
      } else {
        setActivity({
          tone: "success",
          title: action === "volatility" ? "Volatility trigger settled" : "Swap settled",
          detail: "The transaction succeeded on X Layer. Hook state has been refreshed below.",
          hash: result.hash,
        });
      }
      await refresh();
    } catch (error) {
      setActivity({ tone: "error", title: "Transaction not completed", detail: errorMessage(error) });
    } finally {
      setBusy(false);
    }
  }

  const walletReady =
    typeof window !== "undefined" && Boolean((window as Window & { ethereum?: unknown }).ethereum);
  const actionable = Boolean(deployment && account && chainId === 196 && !busy);

  return (
    <div className="page">
      <div className="shell">
        <Header
          account={account}
          chainId={chainId}
          walletReady={walletReady}
          onConnect={handleConnect}
          onSwitch={handleNetworkSwitch}
        />
        <main>
          <section className="intro">
            <div>
              <h1>Protected launches, enforced in the pool.</h1>
              <p>
                A Uniswap v4 Hook that limits extreme early price movement and raises LP fees after accepted
                volatility.
              </p>
              {deployment ? (
                <a className="outline-action" href={addressLink(deployment.hook)} target="_blank" rel="noreferrer">
                  View contract <Arrow />
                </a>
              ) : (
                <button className="outline-action" type="button" disabled>
                  View contract <Arrow />
                </button>
              )}
            </div>
          </section>
          <section className="workspace panel" aria-label="LaunchShield pool demonstration">
            <div className="left-stack">
              <PoolEvidence />
            </div>
            <div className="right-stack">
              <ProtectionPanel snapshot={snapshot} />
              <ActivityPanel activity={activity} />
              <DemoActions disabled={!actionable} busy={busy} onAction={handleAction} />
            </div>
          </section>
          <p className="limitation">
            Limits single-swap pool price movement. Does not prevent bots, MEV, or price loss.
          </p>
        </main>
      </div>
    </div>
  );
}

interface HeaderProps {
  account: Address | null;
  chainId: number | null;
  walletReady: boolean;
  onConnect: () => Promise<void>;
  onSwitch: () => Promise<void>;
}

function Header({ account, chainId, walletReady, onConnect, onSwitch }: HeaderProps) {
  return (
    <header className="nav">
      <a className="brand" href="/" aria-label="LaunchShield home">
        <span className="brand-mark" aria-hidden="true">
          <span />
          <span />
          <span />
          <span />
        </span>
        LaunchShield
      </a>
      <nav className="links" aria-label="Sections">
        <a href="#protection">How it works</a>
        <a href="#evidence">Contract evidence</a>
      </nav>
      <div className="account-controls">
        <button className="network" type="button" onClick={() => void onSwitch()}>
          {chainId === 196 ? "X Layer" : "Switch to X Layer"}
        </button>
        <button className="wallet" type="button" onClick={() => void onConnect()} disabled={!walletReady}>
          {account ? shorten(account) : walletReady ? "Connect wallet" : "Wallet unavailable"}
        </button>
      </div>
    </header>
  );
}

function PoolEvidence() {
  return (
    <article className="panel" id="evidence">
      <div className="panel-header">
        <div className="pair">
          <span className="pair-tokens" aria-hidden="true">
            <span className="token">X</span>
            <span className="token">$</span>
          </span>
          <span>
            <strong>XSH / mUSDC</strong>
            <small>Protected launch pool</small>
          </span>
        </div>
      </div>
      <div className="rows">
        <EvidenceRow
          label="Pool ID"
          value={deployment?.poolId ?? "Awaiting public deployment"}
        />
        <EvidenceRow
          label="Hook address"
          value={deployment?.hook ?? "Awaiting public deployment"}
          link={deployment ? addressLink(deployment.hook) : undefined}
        />
        <EvidenceRow
          label="PoolManager"
          value={infrastructure.poolManager}
          link={addressLink(infrastructure.poolManager)}
        />
        <EvidenceRow
          label="Demo router"
          value={infrastructure.demoRouter}
          link={addressLink(infrastructure.demoRouter)}
        />
      </div>
    </article>
  );
}

function EvidenceRow({ label, value, link }: { label: string; value: string; link?: string }) {
  return (
    <div className="row">
      <span className="row-label">{label}</span>
      <span className="mono">{value}</span>
      {link ? (
        <a className="external" href={link} target="_blank" rel="noreferrer" aria-label={`Open ${label} explorer`}>
          View <Arrow />
        </a>
      ) : null}
    </div>
  );
}

function ProtectionPanel({ snapshot }: { snapshot: ProtectionSnapshot | null }) {
  const guarded = snapshot ? snapshot.guardedUntil > BigInt(Math.floor(Date.now() / 1000)) : false;
  const mode = snapshot ? (guarded ? "Guarded" : "Normal") : "Awaiting public deployment";

  return (
    <article className="panel status" id="protection">
      <div className="mode-line">
        <span className={`mode ${snapshot ? "" : "awaiting"}`}>
          <span className="mode-dot" aria-hidden="true" />
          {mode}
        </span>
        <span className="subtle">{snapshot?.launchActive ? "Launch protection active" : "Not yet active"}</span>
      </div>
      <dl className="stat-grid">
        <div>
          <dt>Fee</dt>
          <dd>{snapshot ? formatFee(snapshot.fee) : "--"}</dd>
        </div>
        <div>
          <dt>Active cap</dt>
          <dd>{snapshot ? formatCap(snapshot.movementCap) : "--"}</dd>
        </div>
        <div>
          <dt>Cooldown</dt>
          <dd>{guarded && snapshot ? formatCountdown(snapshot.guardedUntil) : "--:--"}</dd>
        </div>
      </dl>
      <div className="timeline" aria-hidden="true">
        <span />
      </div>
      <div className="timeline-labels">
        <span>{snapshot?.initialized ? "Protection initialized" : "Deploy pool to initialize"}</span>
        <span>30 min launch window</span>
      </div>
    </article>
  );
}

function DemoActions({
  disabled,
  busy,
  onAction,
}: {
  disabled: boolean;
  busy: boolean;
  onAction: (action: DemoAction) => Promise<void>;
}) {
  return (
    <article className="panel actions">
      <h2>Demo actions</h2>
      <div className="action-grid">
        <button className="action primary" type="button" disabled={disabled} onClick={() => void onAction("normal")}>
          {busy ? "Processing..." : "Normal Buy"}
        </button>
        <button className="action danger" type="button" disabled={disabled} onClick={() => void onAction("oversized")}>
          Trigger Large Swap
        </button>
        <button className="action" type="button" disabled={disabled} onClick={() => void onAction("volatility")}>
          Trigger Volatility
        </button>
      </div>
    </article>
  );
}

function ActivityPanel({ activity }: { activity: ActivityResult }) {
  return (
    <article className="panel activity">
      <h2>Activity</h2>
      <div className={`result ${activity.tone}`}>
        <p className="result-title">
          <span className="result-dot" aria-hidden="true" />
          {activity.title}
        </p>
        <p>{activity.detail}</p>
        {activity.hash ? (
          <a className="result-link" href={transactionLink(activity.hash)} target="_blank" rel="noreferrer">
            Verify transaction <Arrow />
          </a>
        ) : null}
      </div>
    </article>
  );
}

function Arrow(): ReactNode {
  return (
    <svg aria-hidden="true" width="13" height="13" viewBox="0 0 13 13" fill="none">
      <path d="M2.5 10.5 10.5 2.5M4 2.5h6.5V9" stroke="currentColor" strokeWidth="1.35" />
    </svg>
  );
}

function shorten(address: Address) {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
}

function errorMessage(error: unknown) {
  return error instanceof Error ? error.message : "Unknown wallet or RPC error.";
}
