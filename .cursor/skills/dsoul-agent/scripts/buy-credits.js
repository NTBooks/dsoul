const path = require("path");
const { readFile } = require("fs").promises;
const { createWalletClient, createPublicClient, http, parseEther, formatEther } = require("viem");
const { privateKeyToAccount } = require("viem/accounts");
const { mainnet, baseSepolia } = require("viem/chains");
const { getExplorerTxUrl, resolveNetwork } = require(path.join(__dirname, "../shared/network.js"));
const { getBackendUrl } = require(path.join(__dirname, "../shared/testing-config.js"));

const SLIPPAGE = 1.03;
const DEFAULT_AMOUNT = 7;

async function loadWallet(walletPath) {
    const raw = await readFile(walletPath, "utf8");
    return JSON.parse(raw);
}

function parse402Response(challengeResponse) {
    if (challengeResponse.x402Version === 2 && challengeResponse.accepts?.[0]) {
        const accept = challengeResponse.accepts[0];
        return {
            requiredUsdPrice: parseFloat(accept.price.replace("$", "")),
            targetWalletAddress: accept.payTo,
            networkCaip2: accept.network,
        };
    }
    const msgStr = challengeResponse.message || "";
    const priceMatch = msgStr.match(/\$([\d.]+)/);
    const walletMatch = msgStr.match(/(0x[a-fA-F0-9]{40})/);
    if (!priceMatch || !walletMatch) throw new Error("Could not parse 402 price or payTo");
    return {
        requiredUsdPrice: parseFloat(priceMatch[1]),
        targetWalletAddress: walletMatch[1],
        networkCaip2: null,
    };
}

async function getEthUsdRate() {
    const res = await fetch("https://api.coinbase.com/v2/exchange-rates?currency=ETH");
    const data = await res.json();
    return parseFloat(data.data.rates.USD);
}

async function buyCredits(walletPath = "wallet.json", amount = DEFAULT_AMOUNT) {
    const wallet = await loadWallet(walletPath);
    const network = await resolveNetwork(() => Promise.resolve(wallet));
    console.log("Network:", network, network === "mainnet" ? "(ETH mainnet, prod)" : "(Sepolia testnet)");
    const backendUrl = getBackendUrl(network);
    const { address, privateKey, apiKey } = wallet;
    if (!address || !privateKey || !apiKey) {
        throw new Error("Wallet file must contain address, privateKey, and apiKey");
    }

    const chain = network === "mainnet" ? mainnet : baseSepolia;
    const account = privateKeyToAccount(privateKey);
    const publicClient = createPublicClient({
        chain,
        transport: http(),
    });
    const walletClient = createWalletClient({
        account,
        chain,
        transport: http(),
    });

    const challengeReq = await fetch(`${backendUrl}/wp-json/diamond-soul/v1/buy-credits`, {
        method: "POST",
        headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ amount }),
    });
    const challengeResponse = await challengeReq.json();
    if (challengeReq.status !== 402) {
        throw new Error("Expected 402 Payment Required, got " + challengeReq.status);
    }

    const { requiredUsdPrice, targetWalletAddress } = parse402Response(challengeResponse);
    const ethUsdRate = await getEthUsdRate();
    const requiredEth = (requiredUsdPrice / ethUsdRate) * SLIPPAGE;
    const weiToSend = parseEther(requiredEth.toFixed(18));

    console.log("Sending", formatEther(weiToSend), "ETH to", targetWalletAddress);
    const txHash = await walletClient.sendTransaction({
        to: targetWalletAddress,
        value: weiToSend,
    });
    const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });
    if (receipt.status !== "success") throw new Error("Transaction reverted: " + receipt.status);
    console.log("Tx confirmed:", getExplorerTxUrl(network, txHash));

    const claimRes = await fetch(`${backendUrl}/wp-json/diamond-soul/v1/buy-credits`, {
        method: "POST",
        headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ txHash, amount }),
    });
    const claimData = await claimRes.json();
    if (!claimRes.ok || !claimData.success) {
        throw new Error("Claim failed: " + (claimData.message || claimRes.status));
    }
    console.log("Claim success:", claimData.message);
}

const walletPath = process.argv[2] || "wallet.json";
const amount = parseInt(process.argv[3], 10) || DEFAULT_AMOUNT;
buyCredits(walletPath, amount).catch((err) => {
    console.error(err.message);
    process.exit(1);
});
