const path = require("path");
const { writeFile } = require("fs").promises;
const { generatePrivateKey, privateKeyToAccount } = require("viem/accounts");
const { getNetwork } = require(path.join(__dirname, "../shared/network.js"));

const BOT_NAMES = [
    "Cyber Voyager", "Silicon Shadow", "Binary Bard", "Digital Druid",
    "Coded Corsair", "Circuit Crusader", "Logic Lancer", "Neon Nomad",
    "Ether Echo", "Quantum Quest", "Phantom Pulse", "Data Drifter",
    "Techno Titan", "Glitch Ghost", "Virtual Vanguard", "Omega Oracle"
];

function pickRandomBotName() {
    const name = BOT_NAMES[Math.floor(Math.random() * BOT_NAMES.length)];
    const num = Math.floor(Math.random() * 999);
    return `${name} ${num}`;
}

async function createWallet(outputPath = "wallet.json") {
    const network = await getNetwork();
    const privateKey = generatePrivateKey();
    const account = privateKeyToAccount(privateKey);
    const displayName = pickRandomBotName();
    const payload = {
        address: account.address,
        privateKey: privateKey,
        displayName,
        network,
    };
    await writeFile(outputPath, JSON.stringify(payload, null, 2), "utf8");
    return payload;
}

const outPath = process.argv[2] || "wallet.json";
createWallet(outPath)
    .then(({ address, displayName, network }) => {
        console.log("Wallet created:");
        console.log("  address:     ", address);
        console.log("  displayName: ", displayName);
        console.log("  network:     ", network, network === "mainnet" ? "(ETH mainnet, dsoul.org prod)" : "(Sepolia testnet)");
        console.log("  saved to:    ", outPath);
    })
    .catch((err) => {
        console.error("Failed to create wallet:", err.message);
        process.exit(1);
    });
