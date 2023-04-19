import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs/promises";

const input = JSON.parse(await fs.readFile("./input.json"));
const recipients = Object.entries(input.recipients);

const recipient_total = Object.values(input.recipients)
  .map((v) => BigInt(v))
  .reduce((a, b) => a + b);

const trees = { roots: {} };

for (const [chain, chain_total] of Object.entries(input.chains)) {
  const values = recipients.map(([address, amount]) => [
    address,
    (BigInt(chain_total) * BigInt(amount) / recipient_total).toString(),
  ]);

  const tree = StandardMerkleTree.of(values, ["address", "uint256"]);
  trees.roots[chain] = tree.root
  trees[chain] = tree.dump()
}

await fs.writeFile("trees.json", JSON.stringify(trees, null, 2));
console.log("Trees written to trees.json");
