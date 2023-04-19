# Generator

Given `input.json`, a list of recipients and amounts, outputs `tree.json` containing:

1. A merkle root for use in a `BananaMerkle` contract.
2. A merkle tree for generating proofs in the claiming frontend.

## Usage

Prepare `input.json` with recipients and amounts (this is an example).

```json
{
  "0x5427b5141a6cc8228a9e74248f51210380adbae9": "1000000000000000000",
  "0x30670d81e487c80b9edc54370e6eaf943b6eab39": "2000000000000000000",
  "0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e": "3000000000000000000"
}
```

Be sure to surround recipients and amounts with double quotes.

Install and run with:

```bash
# Install dependancies
yarn

# Run script
yarn start
```
