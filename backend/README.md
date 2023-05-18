# Backend

The Bananapus JSON API validates and track stakers – wallet addresses which have committed to maintaining a certain $NANA balance or greater in order to claim rewards.

## Usage

I recommend using [Node.js LTS](https://nodejs.org/en)

Create a .env file with:

```bash
cp .example.env .env
```

and enter a valid JSON RPC provider endpoint under for your `JSON_RPC_URL`. Install dependencies with `yarn`, and start the API with `yarn start`. To run the API on a custom port, run `node . <port_number>`.

The applications stores data in `stakers.db`. I recommend using the [sqlite3 CLI](https://www.sqlite.org/cli.html) to back this up:

```bash
# Edit cronjobs
crontab -e
```

```cron
# Back up to `backup.db` every 10 minutes.
*/10 * * * * sqlite3 -line stakers.db '.backup backup.db'
```

## Endpoints

### `GET` /

Returns a welcome message JSON:

```json
{
  "data": "Welcome to the Bananpus API 🍌",
}
```

### `GET` /stakers

Returns a array of all current stakers.

```json
{
  "data": [
    {
      "id": 1,
      "address": "0x30670d81e487c80b9edc54370e6eaf943b6eab39",
      "timestamp": 1683695338,
      "amount": "6900000000000000000000",
      "signature": "0xa5036b2f26a2a6fce31f46ede58e66de3a295f1e4281bc79dcc6eab9db2f559e2211d6b002ad9bb3b1fc8bd74d875f4b7c04ff85e2858347d672ce3418e394a11c"
    },
    ...
  ]
}
```

### `GET` /staker/`<address>`

Returns the staker corresponding to `<address>`

`/staker/0x30670d81e487c80b9edc54370e6eaf943b6eab39`:

```json
{
  "data": {
    "id": 1,
    "address": "0x30670d81e487c80b9edc54370e6eaf943b6eab39",
    "timestamp": 1683695338,
    "amount": "6900000000000000000000",
    "signature": "0xa5036b2f26a2a6fce31f46ede58e66de3a295f1e4281bc79dcc6eab9db2f559e2211d6b002ad9bb3b1fc8bd74d875f4b7c04ff85e2858347d672ce3418e394a11c"
  }
}
```

### `GET` /balance/`<address>`

Gets $NANA balance for <address> at the current block (does not support ENS).

`/balance/0x30670d81e487c80b9edc54370e6eaf943b6eab39`:

```json
{
  "block": 17231288,
  "address": "0x30670d81e487c80b9edc54370e6eaf943b6eab39",
  "balance": "7000000000000000000000"
}
```

### `POST` /staker

Creates a new staker.

| Param | Type | Description |
| --- | --- | --- |
| address | string | An Ethereum address (ENS not supported). |
| timestamp | string | A Unix timestamp (in seconds). |
| amount | string | The amount of $NANA to stake. |
| signature | string | A signed message validating the information above. |

- `address`es do not have to be checksum validated, but must be valid Ethereum addresses.
- `amount` is a `uint256` stored as text. To stake 70 $NANA, amount should be `"70000000000000000000"` (18 decimals). If the `address` does not hold `amount` of $NANA, the `POST` will fail.
- `timestamp` must be a valid unix seconds timestamp within the previous 60 seconds.

`signature` is something resembling the following message [signed by](https://docs.ethers.org/v6/getting-started/#starting-signing) the `address`:

```json
{
  "description": "Staking NANA for Bananapus rewards",
  "timestamp": "1683738072",
  "amount": "70000000000000000000"
}
```

You can generate this in an application using [ethers](https://docs.ethers.org/v6/getting-started/#starting-signing):

```js
const message = JSON.stringify(
  {
    description: "Staking NANA for Bananapus rewards",
    timestamp: "1683738072",
    amount: "70000000000000000000",
  },
  undefined,
  2
);

const signature = await ethers_signer.signMessage(message);
```

**TODO:**

- Build tree from db
- Claim from contract in frontend
