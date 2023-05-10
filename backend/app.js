const express = require("express");
const sqlite3 = require("sqlite3").verbose();
const ethers = require("ethers");
const cors = require("cors");
require("dotenv").config();

// Serialize BigInt
BigInt.prototype.toJSON = function () {
  return this.toString();
};

// Ethers provider and JBTokenStore initialization
const provider = new ethers.JsonRpcProvider(process.env.JSON_RPC_URL);

const JBTokenStore = new ethers.Contract(
  "0x6FA996581D7edaABE62C15eaE19fEeD4F1DdDfE7",
  [
    "function balanceOf(address _holder, uint256 _projectId) view returns (uint256)",
  ],
  provider
);

// Initialize database if needed
const db = new sqlite3.Database("./stakers.db", (err) => {
  if (err) console.log("stakers.db already exists");
  console.log("Connected to stakers.db");
});

// Create table if needed
db.run(
  `CREATE TABLE stakers(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  address text UNIQUE NOT NULL CHECK(address GLOB '0x[0-9a-f]*' AND LENGTH(address) = 42),
  timestamp INTEGER NOT NULL CHECK(timestamp GLOB '[0-9]*'),
  amount text NOT NULL CHECK(amount GLOB '[0-9]*'),
  signature text NOT NULL
)`,
  (err) => {
    if (err) console.log("Stakers table already exists");
    console.log("Connected to stakers table");
  }
);

// Start express
const app = express();
app.use(express.json());
app.use(cors());

app.get("/", (_, res) => {
  res.status(200).json({ data: "Welcome to the Bananpus API 🍌" });
});

// Read database
app.get("/stakers", (_, res) => {
  const sql = "SELECT * from stakers";
  db.all(sql, [], (err, rows) => {
    if (err) res.status(500).json({ error: JSON.stringify(err) });
    res.status(200).json({ data: rows });
  });
});

// Lookup staker by address
app.get("/staker/:address", (req, res) => {
  const address = req.params.address.toLowerCase();
  const sql = `SELECT * FROM stakers WHERE address = ?`;

  db.get(sql, [address], (err, row) => {
    if (err) res.status(500).json({ error: err.message });
    res.status(200).json({ data: row });
  });
});

// Get $NANA balance for :address
app.get("/balance/:address", async (req, res) => {
  const address = req.params.address.toLowerCase();
  const [block, balance] = await Promise.all([
    provider.getBlockNumber(),
    JBTokenStore.balanceOf(address, 488),
  ]);
  res.json({ block, address, balance });
});

// Write new staker to database
app.post("/staker", async (req, res) => {
  let { address, timestamp, amount, signature } = req.body;

  if (!address || !timestamp || !amount || !signature)
    return res.status(400).json({ error: "Your request is missing fields" });

  if (BigInt(amount) < 0 || isNaN(amount))
    return res.status(400).json({ error: "Invalid amount" });

  address = address.toLowerCase();
  const addressRegex = /^0x[0-9a-f]{40}$/;
  if (!addressRegex.test(address))
    return res.status(400).json({ error: "Invalid address" });

  if (
    isNaN(timestamp) ||
    Math.floor(Date.now() / 1000) - timestamp > 60 ||
    Math.floor(Date.now() / 1000) - timestamp < 0
  )
    return res.status(400).json({ error: "Invalid or old timestamp" });

  const signedMessage = JSON.stringify(
    {
      description: "Staking NANA for Bananapus rewards",
      timestamp,
      amount,
    },
    undefined,
    2
  );

  // Validate signature
  if (ethers.verifyMessage(signedMessage, signature).toLowerCase() !== address)
    return res.status(400).json({ error: "Invalid signature" });

  // Validate that address currently holds amount
  const balance = await JBTokenStore.balanceOf(address, 488);
  if (balance < BigInt(amount))
    return res
      .status(400)
      .json({ error: "$NANA balance less than staking amount" });

  const sql = `
    INSERT INTO stakers(address, timestamp, amount, signature)
    VALUES(?, ?, ?, ?)
    ON CONFLICT(address) 
    DO UPDATE SET timestamp = excluded.timestamp, amount = excluded.amount, signature = excluded.signature
  `;

  db.run(sql, [address, timestamp, amount, signature], (err) => {
    if (err) {
      return res.status(500).json({ error: err.message });
    }
    res
      .status(200)
      .json({ success: `Successfully staked ${amount} $NANA for ${address}.` });
  });
});

const port = (process.argv[2] && !isNaN(process.argv[2])) ? process.argv[2] : 3000
app.listen(port, () =>
  console.log(`Server started on http://localhost:${port}`)
);
