const path = require("path");
const { readFile, writeFile } = require("fs").promises;
const { privateKeyToAccount } = require("viem/accounts");
const { resolveNetwork } = require(path.join(__dirname, "../shared/network.js"));
const { getBackendUrl } = require(path.join(__dirname, "../shared/testing-config.js"));

async function loadWallet(walletPath) {
    const raw = await readFile(walletPath, "utf8");
    return JSON.parse(raw);
}

async function register(walletPath = "wallet.json") {
    const wallet = await loadWallet(walletPath);
    const network = await resolveNetwork(() => Promise.resolve(wallet));
    console.log("Network:", network, network === "mainnet" ? "(ETH mainnet, prod)" : "(Sepolia testnet)");
    const backendUrl = getBackendUrl(network);
    const { address, privateKey, displayName } = wallet;
    if (!address || !privateKey || !displayName) {
        throw new Error("Wallet file must contain address, privateKey, and displayName");
    }

    const account = privateKeyToAccount(privateKey);

    const challengeRes = await fetch(`${backendUrl}/wp-json/agent/v1/challenge`, { method: "POST" });
    if (!challengeRes.ok) throw new Error("Challenge failed: HTTP " + challengeRes.status);
    const challengeData = await challengeRes.json();

    const signature = await account.signMessage({ message: challengeData.message });

    const verifyRes = await fetch(`${backendUrl}/wp-json/agent/v1/verify`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            wallet: address,
            signature,
            nonce: challengeData.nonce,
            display_name: displayName,
        }),
    });
    if (!verifyRes.ok) throw new Error("Verify failed: HTTP " + verifyRes.status);
    const verifyData = await verifyRes.json();
    if (!verifyData.success) throw new Error("Verify returned success: false");

    const apiKey = verifyData.api_key;
    const updated = { ...wallet, apiKey };
    await writeFile(walletPath, JSON.stringify(updated, null, 2), "utf8");
    console.log("Registered. API key saved to", walletPath, "(first 10 chars):", apiKey.substring(0, 10) + "...");
    return updated;
}

const walletPath = process.argv[2] || "wallet.json";
register(walletPath).catch((err) => {
    console.error(err.message);
    process.exit(1);
});
