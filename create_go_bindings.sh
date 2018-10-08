#!/usr/bin/env bash

mkdir build/extra

# PepeBase
cat build/contracts/PepeBase.json | python3 -c "import sys, json; print(json.load(sys.stdin)['bytecode'])" > build/extra/PepeBase.bytecode.txt
cat build/contracts/PepeBase.json | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)['abi']))" > build/extra/PepeBase.abi.json

if [ -d "$GOPATH/src/cryptopepe.io/cryptopepe-reader/abi/token" ]; then
    go run "$GOPATH/src/github.com/ethereum/go-ethereum/cmd/abigen/main.go" \
     --abi build/extra/PepeBase.abi.json \
     --bin build/extra/PepeBase.bytecode.txt \
     --pkg token \
     --out "$GOPATH/src/cryptopepe.io/cryptopepe-reader/abi/token/pepe_token.go"
else
    echo "No token output dir"
fi

# PepeAuctionSale
cat build/contracts/PepeAuctionSale.json | python3 -c "import sys, json; print(json.load(sys.stdin)['bytecode'])" > build/extra/PepeAuctionSale.bytecode.txt
cat build/contracts/PepeAuctionSale.json | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)['abi']))" > build/extra/PepeAuctionSale.abi.json

if [ -d "$GOPATH/src/cryptopepe.io/cryptopepe-reader/abi/sale" ]; then
    go run "$GOPATH/src/github.com/ethereum/go-ethereum/cmd/abigen/main.go" \
     --abi build/extra/PepeAuctionSale.abi.json \
     --bin build/extra/PepeAuctionSale.bytecode.txt \
     --pkg sale \
     --out "$GOPATH/src/cryptopepe.io/cryptopepe-reader/abi/sale/sale_auction.go"
else
    echo "No sale output dir"
fi

# CozyTimeAuction
cat build/contracts/CozyTimeAuction.json | python3 -c "import sys, json; print(json.load(sys.stdin)['bytecode'])" > build/extra/CozyTimeAuction.bytecode.txt
cat build/contracts/CozyTimeAuction.json | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)['abi']))" > build/extra/CozyTimeAuction.abi.json

if [ -d "$GOPATH/src/cryptopepe.io/cryptopepe-reader/abi/cozy" ]; then
    go run "$GOPATH/src/github.com/ethereum/go-ethereum/cmd/abigen/main.go" \
     --abi build/extra/CozyTimeAuction.abi.json \
     --bin build/extra/CozyTimeAuction.bytecode.txt \
     --pkg cozy \
     --out "$GOPATH/src/cryptopepe.io/cryptopepe-reader/abi/cozy/cozy_auction.go"
else
    echo "No cozy output dir"
fi


if [ -d "$HOME/projects/cryptopepe-client/abi" ]; then
    cp "build/extra/PepeBase.abi.json" "$HOME/projects/cryptopepe-client/abi/CPEP_abi.json"
    cp "build/extra/CozyTimeAuction.abi.json" "$HOME/projects/cryptopepe-client/abi/cozy_abi.json"
    cp "build/extra/PepeAuctionSale.abi.json" "$HOME/projects/cryptopepe-client/abi/sale_abi.json"
else
    echo "No client ABI output dir"
fi
