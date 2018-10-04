#!/usr/bin/env bash

mkdir build/extra

# PepeBase
cat build/contracts/PepeBase.json | python3 -c "import sys, json; print(json.load(sys.stdin)['bytecode'])" > build/extra/PepeBase.bytecode.txt
cat build/contracts/PepeBase.json | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)['abi']))" > build/extra/PepeBase.abi.json

go run "$GOPATH/src/github.com/ethereum/go-ethereum/cmd/abigen/main.go" \
 --abi build/extra/PepeBase.abi.json \
 --bin build/extra/PepeBase.bytecode.txt \
 --pkg token \
 --out "$GOPATH/src/cryptopepe.io/cryptopepe-reader/abi/token/pepe_token.go"


# PepeAuctionSale
cat build/contracts/PepeAuctionSale.json | python3 -c "import sys, json; print(json.load(sys.stdin)['bytecode'])" > build/extra/PepeAuctionSale.bytecode.txt
cat build/contracts/PepeAuctionSale.json | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)['abi']))" > build/extra/PepeAuctionSale.abi.json

go run "$GOPATH/src/github.com/ethereum/go-ethereum/cmd/abigen/main.go" \
 --abi build/extra/PepeAuctionSale.abi.json \
 --bin build/extra/PepeAuctionSale.bytecode.txt \
 --pkg sale \
 --out "$GOPATH/src/cryptopepe.io/cryptopepe-reader/abi/sale/sale_auction.go"

# CozyTimeAuction
cat build/contracts/CozyTimeAuction.json | python3 -c "import sys, json; print(json.load(sys.stdin)['bytecode'])" > build/extra/CozyTimeAuction.bytecode.txt
cat build/contracts/CozyTimeAuction.json | python3 -c "import sys, json; print(json.dumps(json.load(sys.stdin)['abi']))" > build/extra/CozyTimeAuction.abi.json

go run "$GOPATH/src/github.com/ethereum/go-ethereum/cmd/abigen/main.go" \
 --abi build/extra/CozyTimeAuction.abi.json \
 --bin build/extra/CozyTimeAuction.bytecode.txt \
 --pkg cozy \
 --out "$GOPATH/src/cryptopepe.io/cryptopepe-reader/abi/cozy/cozy_auction.go"
