import "./style.css";
import * as trees from "./assets/trees.json";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

let wallets;
let address;
let proofs = {};

// Basic document structure
document.querySelector("#app").innerHTML = `
  <div>
    <h1>Bananapus Rewards</h1>
    <p>Join the <a href="https://discord.gg/ErQYmth4dS">Discord server</a> to learn more.</p>
    <button id="connect">Connect</button>
    <button id="check">Check Rewards</button>
  </div>`;

document.getElementById("connect").addEventListener("click", async () => {
  if (typeof window.ethereum !== "undefined") {
    wallets = await window.ethereum.request({ method: "eth_requestAccounts" });
    console.log(wallets);
    document.getElementById("connect").innerHTML = "Connected!";
  } else {
    document.getElementById("connect").innerHTML = "Please install Metamask";
  }
});

document.getElementById("check").addEventListener("click", () => {
  if (!wallets || !wallets[0]) alert("You must connect your wallet.");

  address = wallets[0];

  for (const [chainId, tree_obj] of Object.entries(Object.values(trees)[0])) {
    if (chainId === "roots") continue;
    const tree = StandardMerkleTree.load(tree_obj);

    for (const [i, v] of tree.entries()) {
      if (v[0] === address) {
        const proof = tree.getProof(i);
        proofs[chainId] = proof;
        console.log(`Proof to claim ${v[1]} tokens on chain ${chainId}:`, proof);
      }
    }
  }
});
