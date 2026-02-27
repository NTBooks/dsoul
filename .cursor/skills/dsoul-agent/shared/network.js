const readline = require("readline");

const MAINNET = "mainnet";
const SEPOLIA = "sepolia";
const VALID = [MAINNET, SEPOLIA];

function getExplorerTxUrl(network, txHash) {
    if (network === MAINNET) {
        return "https://etherscan.io/tx/" + txHash;
    }
    if (network === SEPOLIA) {
        return "https://sepolia.basescan.org/tx/" + txHash;
    }
    throw new Error("Invalid network: " + network);
}

function askNetwork() {
    return new Promise((resolve) => {
        const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
        rl.question(
            "Use ETH mainnet (prod, dsoul.org) or Sepolia testnet? (mainnet|sepolia): ",
            (answer) => {
                rl.close();
                const raw = (answer || "").trim().toLowerCase();
                const chosen = raw === "mainnet" || raw === "m" ? MAINNET : raw === "sepolia" || raw === "s" ? SEPOLIA : null;
                if (VALID.includes(chosen)) resolve(chosen);
                else resolve(SEPOLIA);
            }
        );
    });
}

const { loadTestingConfig } = require("./testing-config.js");

function networkFromValue(v) {
    const s = String(v || "").trim().toLowerCase();
    if (s === "mainnet" || s === "m") return MAINNET;
    if (s === "sepolia" || s === "s") return SEPOLIA;
    return null;
}

async function getNetwork() {
    const config = loadTestingConfig();
    const fromConfig = networkFromValue(config.network);
    if (fromConfig) return fromConfig;
    const fromEnv = networkFromValue(process.env.NETWORK);
    if (fromEnv) return fromEnv;
    return askNetwork();
}

async function resolveNetwork(loadWalletFn) {
    const config = loadTestingConfig();
    const fromConfig = networkFromValue(config.network);
    if (fromConfig) return fromConfig;
    const fromEnv = networkFromValue(process.env.NETWORK);
    if (fromEnv) return fromEnv;
    const wallet = await loadWalletFn();
    if (wallet && VALID.includes(wallet.network)) return wallet.network;
    return askNetwork();
}

module.exports = {
    MAINNET,
    SEPOLIA,
    VALID,
    getExplorerTxUrl,
    askNetwork,
    getNetwork,
    resolveNetwork,
};
