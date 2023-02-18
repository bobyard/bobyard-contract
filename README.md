# obj.exchange smart contract

# Contract call
## init shell value
```shell
PKG=
MK=
```


## Init Market with Coin type
```shell
sui client call --package $PKG --module marketplace --function create --type-args  0x2::sui::SUI --gas-budget 300000
```

## List Object

```shell
sui client call --package $PKG --module marketplace --function list --type-args 0x2::devnet_nft::DevNetNFT 0x2::sui::SUI  --args $MK 0x3a892d9a6be88a60ba6489a208bad707344343a4 100000000 --gas-budget 300000
```

## Buy Object

```shell
sui client call --package $PKG --module marketplace --function buy --type-args 0x2::devnet_nft::DevNetNFT 0x2::sui::SUI  --args $MK 0x15d669bcac7b018f84baaa15048acbf4c54340e7 0x377c51b45ffa1dc5ef3fb59a833cdb1dcd175634 --gas-budget 300000
```

## Make Bid
```shell

```


## TODO
- 完成多（绑定）item上架
- 完成collecion offer&互换
- 完成indexer入库（postgres）
- 前端设计