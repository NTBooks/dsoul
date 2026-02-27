const path = require("path");
const { readFile } = require("fs").promises;
const { createPublicClient, http } = require("viem");
const { baseSepolia } = require("viem/chains");
const { getExplorerTxUrl, resolveNetwork, MAINNET, SEPOLIA } = require(path.join(__dirname, "../shared/network.js"));

async function loadWallet(walletPath) {
    const raw = await readFile(walletPath, "utf8");
    return JSON.parse(raw);
}

async function requestFaucet(walletPath = "wallet.json") {
    const wallet = await loadWallet(walletPath);
    const { address } = wallet;
    if (!address) throw new Error("Wallet file missing address");

    const network = await resolveNetwork(() => Promise.resolve(wallet));
    if (network === MAINNET) {
        console.log("Faucet is only available on testnet. Use Sepolia for the faucet (set NETWORK=sepolia or choose sepolia when prompted), or fund your address on mainnet manually.");
        console.log("Address:", address);
        return;
    }

    const publicClient = createPublicClient({
        chain: baseSepolia,
        transport: http(),
    });

    let cdp;
    try {
        const { loadTestingConfig } = require(path.join(__dirname, "../shared/testing-config.js"));
        const config = loadTestingConfig();
        const apiKeyId = config.cdpApiKeyId || process.env.CDP_API_KEY_ID;
        const apiKeySecret = config.cdpApiKeySecret || process.env.CDP_API_KEY_SECRET;
        if (!apiKeyId || !apiKeySecret) {
            console.log("CDP not configured (add cdpApiKeyId and cdpApiKeySecret to testing.json). Send Base Sepolia ETH manually to:", address);
            return;
        }
        const { CdpClient } = require("@coinbase/cdp-sdk");
        cdp = new CdpClient({ apiKeyId, apiKeySecret });
    } catch (e) {
        console.log("CDP SDK not configured. Send Base Sepolia ETH manually to:", address);
        return;
    }

    console.log("Requesting ETH from Coinbase Base Sepolia faucet for", address);
    try {
        const { transactionHash } = await cdp.evm.requestFaucet({
            address,
            network: "base-sepolia",
            token: "eth",
        });
        console.log("Faucet tx submitted:", transactionHash);
        const receipt = await publicClient.waitForTransactionReceipt({ hash: transactionHash });
        console.log("Confirmed:", getExplorerTxUrl(SEPOLIA, receipt.transactionHash));
    } catch (err) {
        console.error("Faucet request failed:", err.message);
        console.log("Send Base Sepolia ETH manually to:", address);
    }
}

const walletPath = process.argv[2] || "wallet.json";
requestFaucet(walletPath).catch((err) => {
    console.error(err.message);
    process.exit(1);
});
