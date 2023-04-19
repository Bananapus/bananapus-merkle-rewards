import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs/promises";

const input = JSON.parse(await fs.readFile("./input.json"));
const values = Object.entries(input);

const tree = StandardMerkleTree.of(values, ["address", "uint256"]);

console.log("Root: ", tree.root);
await fs.writeFile("tree.json", JSON.stringify(tree.dump()));
console.log("Tree written to tree.json");
