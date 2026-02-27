const path = require("path");
const fs = require("fs");

let cached = null;

function loadTestingConfig() {
    if (cached !== null) return cached;
    const file = path.resolve(process.cwd(), "testing.json");
    try {
        const raw = fs.readFileSync(file, "utf8");
        cached = JSON.parse(raw);
        return cached || {};
    } catch (_) {
        cached = {};
        return {};
    }
}

function getBackendUrl(network) {
    const config = loadTestingConfig();
    if (network === "sepolia") {
        const u = config.wpSepoliaUrl;
        if (!u || !String(u).trim()) throw new Error("testing.json wpSepoliaUrl is required for Sepolia testnet");
        return String(u).trim();
    }
    return (config.wpEthUrl && String(config.wpEthUrl).trim()) || "https://dsoul.org";
}

module.exports = { loadTestingConfig, getBackendUrl };
