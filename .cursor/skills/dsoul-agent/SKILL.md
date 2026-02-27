---
name: dsoul-agent
description: Wallet/agent flow for dsoul/x402: create wallet, faucet (test ETH), register with WordPress, check balance, buy credits. Use when the user wants to set up or use an agent wallet for diamond-soul (Base Sepolia or mainnet). Run only the steps the user asked for; do not run buy-credits unless they explicitly ask to buy credits.
license: MIT
metadata:
  author: DSoul.org
  version: "0.0.1"
---

# dsoul Agent (Wallet Flow)

EVM wallet flow for the dsoul/x402 agent: create wallet → faucet (testnet) → register with WordPress → check balance → buy credits (optional). All steps use **wallet.json** (and optional **testing.json**). **Run only the steps the user asked for**—e.g. if they say "create wallet, use faucet, then get balance", do **not** run buy-credits unless they ask for it.

**Disambiguation:** This skill is for the **wallet/agent** flow (pnpm create-wallet, pnpm faucet, pnpm register, pnpm balance, pnpm buy-credits). For the **dsoul CLI** (install, config, freeze, etc.), use the dsoul-cli skill.

---

## Prerequisites

- From project root: `pnpm install` once (viem; faucet also uses @coinbase/cdp-sdk).
- Optional **testing.json** (copy from `testing.json.example`): `network`, `wpEthUrl`, `wpSepoliaUrl`, and for faucet only `cdpApiKeyId`, `cdpApiKeySecret`. Prod (mainnet) users often need no testing.json; defaults apply.

---

## 1. Create wallet

**When:** User explicitly asks to create or make a wallet.

**Command:**

```bash
pnpm create-wallet [output-path]
```

Default output: `./wallet.json`. Script asks (or reads `testing.json` `network`): **mainnet** (dsoul.org prod) or **sepolia** (testnet). Output: `address`, `privateKey`, `displayName`, `network`. Do not commit wallet.json or expose the private key.

---

## 2. Faucet (test ETH)

**When:** User explicitly asks to use the faucet or get test ETH (e.g. after creating a wallet).

**Command:**

```bash
pnpm faucet [wallet-path]
```

Default wallet: `./wallet.json`. **Faucet is testnet-only** (Base Sepolia). If network is mainnet, script prints that the faucet is unavailable and shows the address for manual funding. For Sepolia: set `cdpApiKeyId` and `cdpApiKeySecret` in testing.json (from https://portal.cdp.coinbase.com/) or the script skips faucet and prints the address. Do not run buy-credits unless the user asks for it.

---

## 3. Register

**When:** User has a funded wallet and wants to register with the diamond-soul WordPress backend (e.g. after faucet, before balance or buy-credits).

**Command:**

```bash
pnpm register [wallet-path]
```

Default wallet: `./wallet.json`. Performs challenge → sign with wallet → verify; writes **apiKey** into the wallet file. Run balance or buy-credits only if the user explicitly asks for those.

**Config:** Optional testing.json: `wpEthUrl` (default `https://dsoul.org` for mainnet), `wpSepoliaUrl` (required for Sepolia).

---

## 4. Balance

**When:** User explicitly asks to check, see, or get their balance (stamps, PMCREDIT). Use after register when they asked for balance. Do **not** run buy-credits unless they ask to buy credits.

**Command:**

```bash
pnpm balance [wallet-path]
```

Default wallet: `./wallet.json`. Wallet must contain **apiKey**. Calls `GET /wp-json/diamond-soul/v1/balance`; handles 202/pending with retries. Response includes `stamps` or `pmcredit`.

---

## 5. Buy credits

**When:** **Only** when the user explicitly asks to buy credits, get more PMCREDIT, top up, or purchase credits (e.g. "buy credits", "get more credits", "top up"). Do **not** run as part of a generic setup; do **not** run when they only asked for wallet, faucet, and balance.

**Command:**

```bash
pnpm buy-credits [wallet-path] [amount]
```

Default wallet: `./wallet.json`. Default amount: `7`. Wallet must contain **apiKey** and **privateKey**. Flow: GET 402 from buy-credits endpoint → parse price/pay-to → fetch ETH/USD → send ETH from wallet → POST with txHash to claim. Uses testing.json `wpEthUrl` / `wpSepoliaUrl` as other steps.

---

## Summary

| Step           | Command                | When to run                                      |
|----------------|------------------------|--------------------------------------------------|
| Create wallet  | `pnpm create-wallet`   | User asks to create/make a wallet                |
| Faucet         | `pnpm faucet`          | User asks for faucet / test ETH                  |
| Register       | `pnpm register`       | User has funded wallet, needs to register       |
| Balance        | `pnpm balance`        | User asks to check/see/get balance               |
| Buy credits    | `pnpm buy-credits`    | **Only** when user explicitly asks to buy credits |

Scripts live under `.cursor/skills/dsoul-agent/scripts/` (create-wallet.js, faucet.js, register.js, balance.js, buy-credits.js). Shared logic in `.cursor/skills/dsoul-agent/shared/` (network.js, testing-config.js). Package.json wires `pnpm create-wallet`, `pnpm faucet`, etc., to those scripts.
