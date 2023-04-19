# Generator

Given `input.json` which contains:

- a list of [`ChainID`s](https://chainlist.org/) and reward totals for those chains
- a list of recipients, and the proportion of rewards they're entitled to on each chain

outputs `trees.json` containing:

- a merkle tree root for each chain.
- a merkle tree for each chain (used for generating proofs in the claiming frontend).

## Usage

Prepare `input.json` with totals and recipients (this is an example).

```json
{
  "chains": {
    "10": "100000000000000000000",
    "137": "200000000000000000000",
    "42161": "300000000000000000000"
  },
  "recipients": {
    "0x5427b5141a6cc8228a9e74248f51210380adbae9": "1",
    "0x30670d81e487c80b9edc54370e6eaf943b6eab39": "2",
    "0xAF28bcB48C40dBC86f52D459A6562F658fc94B1e": "3",
    "0x6860f1A0cF179eD93ABd3739c7f6c8961A4EEa3c": "4",
    "0x823b92d6a4b2AED4b15675c7917c9f922ea8ADAD": "5",
    "0x2DdA8dc2f67f1eB94b250CaEFAc9De16f70c5A51": "6"
  }
}
```

Be sure to surround all values with double quotes.

Install and run with:

```bash
# Install dependancies
yarn

# Run script
yarn generate
```

## Generate Proofs Locally

To generate proofs locally, first ensure you have a properly formatted `trees.json` (as created by `yarn generate`), and then run:

```bash
yarn prove
```

Which will write proofs to `proofs.json`
