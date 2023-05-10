import "./style.css";
import * as trees from "./assets/trees.json";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import { ethers, verifyMessage } from "ethers";

import Onboard from "@web3-onboard/core";
import injectedModule from "@web3-onboard/injected-wallets";
import gnosisModule from "@web3-onboard/gnosis";

let wallets, address, ethersProvider, ethersSigner;

// Basic document structure
document.querySelector("#app").innerHTML = `
  <div>
    <h1>Bananapus Rewards</h1>
    <p>Join the <a href="https://discord.gg/ErQYmth4dS">Discord server</a> to learn more.</p>
    <div class="buttons">
      <button id="connect">Connect</button>
      <button id="stake">Stake</button>
      <button id="check">Check Rewards</button>
    </div>
  </div>
  <div class="buttons" id="buttonSection"></div>`;

// web3-onboard boilerplate
const onboard = Onboard({
  wallets: [injectedModule(), gnosisModule()],
  chains: [
    {
      id: "0x1",
      token: "ETH",
      label: "Ethereum Mainnet",
      rpcUrl: import.meta.env.VITE_MAINNET_RPC_URL,
    },
    {
      id: "0x89",
      token: "MATIC",
      label: "Polygon Mainnet",
      rpcUrl: import.meta.env.VITE_POLYGON_RPC_URL,
    },
    {
      id: "0xa",
      token: "ETH",
      label: "Optimism",
      rpcUrl: import.meta.env.VITE_OPTIMISM_RPC_URL,
    },
    {
      id: "0xa4b1",
      token: "ETH",
      label: "Arbitrum One",
      rpcUrl: import.meta.env.VITE_ARBITRUM_RPC_URL,
    },
  ],
  appMetadata: {
    name: "Bananapus Rewards",
    icon: "/light-icon-round.svg",
    description: "Welcome to the Bananapus rewards portal.",
  },
  connect: {
    iDontHaveAWalletLink: "https://metamask.io/",
  },
});

// Connect wallet
document.getElementById("connect").addEventListener("click", async () => {
  wallets = await onboard.connectWallet();
  if (wallets[0]) {
    document.getElementById("connect").innerText = "Connected";
    ethersProvider = new ethers.BrowserProvider(wallets[0].provider, "any");
    ethersSigner = await ethersProvider.getSigner();
  } else {
    document.getElementById("connect").innerText = "Connect";
    ethersProvider = null;
    ethersSigner = null;
  }
  console.log(wallets);
});

document.getElementById("stake").addEventListener("click", async () => {
  if (!wallets || !wallets[0]?.accounts[0]?.address) {
    alert("You must connect your wallet.");
    return;
  }

  // Clear any elements currently in buttonSection
  document.getElementById("buttonSection").textContent = "";

  address = wallets[0]?.accounts[0]?.address;
  console.log(address);

  const amountInput = document.createElement("input")
  amountInput.name = "amountInput"
  amountInput.id = "amountInput"
  amountInput.setAttribute("type", "number")
  amountInput.setAttribute("placeholder", "123456789")

  const amountLabel = document.createElement("label")
  amountLabel.innerText = "Amount: "
  amountLabel.setAttribute("for", "amountInput")

  const currencySpan = document.createElement("span")
  currencySpan.innerText = " NANA "

  const signButton = document.createElement("button")
  signButton.innerText = `Sign`;

  signButton.onclick = async () => {
    if (!ethersSigner) {
      alert("You must have a signer. Please connect your wallet.");
      return;
    }

    const amount = String(document.getElementById("amountInput").value) + "000000000000000000"
    await onboard.setChain({ chainId: "0x1" });
    console.log(`Staking ${amount} NANA for ${address}.`);
    const timestamp = String(Math.floor(Date.now() / 1000))

    const message = JSON.stringify({
      description: "Staking NANA for Bananapus rewards",
      timestamp, 
      amount,
    }, null, 2)

    const signature = await ethersSigner.signMessage(message);
    console.log('signature: ', signature, 'verified: ', verifyMessage(message, signature));

    await fetch(`${import.meta.env.VITE_BANANAPUS_API_URL}/staker`, {
      headers: { 'Content-Type': 'application/json' },
      method: 'POST',
      body: JSON.stringify({
        address,
        timestamp,
        amount,
        signature,
      })
    }).then(res => res.json())
    .then(json => console.log(json))

  }
  
  const explainer = document.createElement("p")
  explainer.style.fontSize = "2em"
  explainer.innerText = "Enter the number of tokens you would like to stake, and click \"Sign\" to commit to holding that many tokens. As long as you do, you'll continue to qualify for $NANA rewards."

  document.getElementById("buttonSection").appendChild(amountLabel)
  document.getElementById("buttonSection").appendChild(amountInput)
  document.getElementById("buttonSection").appendChild(currencySpan)
  document.getElementById("buttonSection").appendChild(signButton)
  document.getElementById("buttonSection").appendChild(explainer)

})

// Check for rewards, and if they exist, create claim buttons
document.getElementById("check").addEventListener("click", () => {
  if (!wallets || !wallets[0]?.accounts[0]?.address) {
    alert("You must connect your wallet.");
    return;
  }

  // Clear any elements currently in buttonSection
  document.getElementById("buttonSection").textContent = "";

  address = wallets[0]?.accounts[0]?.address;
  console.log(address);

  for (const [chainId, tree_obj] of Object.entries(Object.values(trees)[0])) {
    if (chainId === "roots") continue;
    const tree = StandardMerkleTree.load(tree_obj);

    for (const [i, v] of tree.entries()) {
      if (v[0] === address) {
        const proof = tree.getProof(i);
        newClaimer(chainId, v[0], v[1], proof);
        console.log(
          `Proof to claim ${v[1]} tokens on chain ${chainId}:`,
          proof
        );
      }
    }
  }
});

// Create claim button
function newClaimer(chainId, address, amount, proof) {
  const hexChainId = "0x" + parseInt(chainId).toString(16);
  const chainName =
    onboard.state.get().chains.find((c) => c.id === hexChainId).label ??
    hexChainId;

  const claimButton = document.createElement("button");
  claimButton.innerText = `Claim on ${chainName}`;

  claimButton.onClick = async () => {
    if (!ethersSigner) {
      alert("You must have a signer");
      return;
    }

    await onboard.setChain({ chainId: hexChainId });
    console.log(
      `Claiming ${amount} for ${address} on chain ${hexChainId} with proof:`,
      proof
    );

    // Placeholder. Once contract is ready, this will claim rewards.
    const txn = await ethersSigner.sendTransaction({
      to: address,
      value: 1,
    });

    const receipt = await txn.wait();
    console.log(receipt);
  };

  document.getElementById("buttonSection").appendChild(claimButton);
}
