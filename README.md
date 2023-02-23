# obj.exchange smart contract

# Contract call
## init shell value
```shell
PKG=
MK=
```


## Init Market with Coin type
```shell
sui client call --package $PKG --module marketplace --function create --type-args  0x2::sui::SUI --args 0xc1abebd6884f6f9a74d6ffd5f36108a2745d42bb --gas-budget 300000
```


## List Object

```shell
sui client call --package $PKG --module marketplace --function list --type-args 0x2::devnet_nft::DevNetNFT 0x2::sui::SUI  --args $MK 0x3a892d9a6be88a60ba6489a208bad707344343a4 100000000 --gas-budget 300000
```

## Buy Object

```shell
sui client call --package $PKG --module marketplace --function buy_and_take --type-args 0x2::devnet_nft::DevNetNFT 0x2::sui::SUI  --args $MK 0x15d669bcac7b018f84baaa15048acbf4c54340e7 0x377c51b45ffa1dc5ef3fb59a833cdb1dcd175634 --gas-budget 300000
```

## Make Offer
```shell
sui client call --package $PKG --module marketplace --function make_offer --type-args 0x2::devnet_nft::DevNetNFT 0x2::sui::SUI  --args $MK 0xa4e25513b1c4ac125929c3a350590e77206ea369 0x3473808455e7c09d1496cfa5498ff4a983b6c8f6 0 --gas-budget 300000
```

## Cancel Offer
```shell
sui client call --package $PKG --module marketplace --function cancel_offer --type-args 0x2::devnet_nft::DevNetNFT 0x2::sui::SUI  --args $MK 0x6d679cf41d10ef1e78d25e465c3f09f9908104be 
--gas-budget 300000
```
## accept offer

```shell
sui client call --package $PKG --module marketplace --function accept_offer --type-args 0x2::devnet_nft::DevNetNFT 0x2::sui::SUI  --args $MK 0xa4e25513b1c4ac125929c3a350590e77206ea369 0x3473808455e7c09d1496cfa5498ff4a983b6c8f6 --gas-budget 300000
```
