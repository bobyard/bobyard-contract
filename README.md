# The https://bobYard.io nft bobYard smart contract

# Contract call
## init shell value
```shell
PKG=0x56f4f98bb44e5bec83b97cdd17ea3d4194aa8c098ba1003fd2d8e481264ae632
MK=0x647129c278fb89ca99181c8066534e7f4f3432805387141e1f41c3a13f371ed7
ADMIN=0x694c746553721bb3af146d12fa8a32a297fded916382e26b809f7800e79588e7
```

## Init Market with Coin type
```shell
sui client call --package $PKG --module bobYard --function create --type-args  0x2::sui::SUI --args $ADMIN --gas-budget 300000000
```


## List Object
```shell
sui client call --package $PKG --module bobYard --function list --type-args 0x2::sui::SUI 0xbbc4945f4d02d05df8aecad3937a04e7434687017f008efcb4ff0c2f3a2a8f31::Ninjas::NinJasNFT  --args $MK 0xf1bf514ea68add21bf4042638430996cf26cc70a81f2ca607ed3fea6fa0c9d88 100000000 --gas-budget 30000000
```

## Delist Object
```shell
sui client call --package $PKG --module bobYard --function delist --type-args 0x2::sui::SUI 0xbbc4945f4d02d05df8aecad3937a04e7434687017f008efcb4ff0c2f3a2a8f31::Ninjas::NinJasNFT  --args $MK 0x21fe31f29516c4d382d67d297876ae306a8b03e9a03d5ad58ac34d5e6450a92d --gas-budget 30000000
```

## Buy Object
```shell
sui client call --package $PKG --module bobYard --function buy_one --type-args 0x2::devnet_nft::DevNetNFT 0x2::sui::SUI  --args $MK 0x15d669bcac7b018f84baaa15048acbf4c54340e7 0x377c51b45ffa1dc5ef3fb59a833cdb1dcd175634 --gas-budget 300000
```

## Make Offer
```shell
sui client call --package $PKG --module bobYard --function make_offer --type-args 0x2::devnet_nft::DevNetNFT 0x2::sui::SUI  --args $MK 0xa4e25513b1c4ac125929c3a350590e77206ea369 0x3473808455e7c09d1496cfa5498ff4a983b6c8f6 0 --gas-budget 300000
```

## Cancel Offer
```shell
sui client call --package $PKG --module bobYard --function cancel_offer --type-args 0x2::devnet_nft::DevNetNFT 0x2::sui::SUI  --args $MK 0x6d679cf41d10ef1e78d25e465c3f09f9908104be 
--gas-budget 300000
```

## accept offer
```shell
sui client call --package $PKG --module bobYard --function accept_offer --type-args 0x2::devnet_nft::DevNetNFT 0x2::sui::SUI  --args $MK 0xa4e25513b1c4ac125929c3a350590e77206ea369 0x3473808455e7c09d1496cfa5498ff4a983b6c8f6 --gas-budget 300000
```