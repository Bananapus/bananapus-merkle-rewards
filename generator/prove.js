import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs/promises";

const trees = JSON.parse(await fs.readFile("./trees.json"));

const proofs = {}

for (const [chainId, tree_object] of Object.entries(trees)) {
  if(chainId === "roots") continue;
  proofs[chainId] = []
  const tree = StandardMerkleTree.load(tree_object);

  for (const [i, v] of tree.entries()) {
    const proof = tree.getProof(i);
    proofs[chainId].push({
      address: v[0],
      value: v[1],
      leaf: proof[0],
      proof: proof[1],
    });
  }
}

await fs.writeFile("proofs.json", JSON.stringify(proofs, null, 2));
console.log("Proofs written to proofs.json");
