const path = require("path");
const { readFile } = require("fs").promises;
const { resolveNetwork } = require(path.join(__dirname, "../shared/network.js"));
const { getBackendUrl } = require(path.join(__dirname, "../shared/testing-config.js"));

const MAX_RETRIES = 5;
const RETRY_DELAY_MS = 5000;

function delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

async function loadWallet(walletPath) {
    const raw = await readFile(walletPath, "utf8");
    return JSON.parse(raw);
}

async function getBalance(walletPath = "wallet.json") {
    const wallet = await loadWallet(walletPath);
    const network = await resolveNetwork(() => Promise.resolve(wallet));
    console.log("Network:", network, network === "mainnet" ? "(ETH mainnet, prod)" : "(Sepolia testnet)");
    const backendUrl = getBackendUrl(network);
    const apiKey = wallet.apiKey;
    if (!apiKey) throw new Error("Wallet file missing apiKey. Run register first.");

    for (let attempt = 1; attempt <= MAX_RETRIES; attempt++) {
        const res = await fetch(`${backendUrl}/wp-json/diamond-soul/v1/balance`, {
            headers: { Authorization: `Bearer ${apiKey}` },
        });
        const data = await res.json();

        if (res.status === 202 || data.pending) {
            console.log(`Attempt ${attempt}/${MAX_RETRIES}: activation pending...`);
            if (attempt < MAX_RETRIES) {
                await delay(RETRY_DELAY_MS);
                continue;
            }
            throw new Error("Activation did not complete after " + MAX_RETRIES + " attempts.");
        }

        const balance = data.stamps !== undefined ? data.stamps : data.pmcredit;
        if (balance !== undefined && balance !== null) {
            console.log("Balance:", balance);
            return balance;
        }

        console.log(`Attempt ${attempt}/${MAX_RETRIES}: balance undefined, retrying...`);
        if (attempt < MAX_RETRIES) await delay(RETRY_DELAY_MS);
    }

    throw new Error("Balance still undefined after " + MAX_RETRIES + " attempts.");
}

const walletPath = process.argv[2] || "wallet.json";
getBalance(walletPath).catch((err) => {
    console.error(err.message);
    process.exit(1);
});
