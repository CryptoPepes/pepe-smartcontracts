# CryptoPepes Smartcontracts


## Instructions

```bash
# Compile contracts, see if there are any warnings/errors
truffle compile
```

## Premining

```bash
# Premine pepes of deployed contract
truffle exec ./scripts/premine.js --network ropsten
```

## Generate bindings

Run the bindings script to create the necessary bindings
 (output in `$GOPATH/src/cryptopepe.io/cryptopepe-reader/abi/`).
```bash
./create_go_bindings.sh
```
