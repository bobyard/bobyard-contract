module bob::testnet{
    use sui::collectible::{create_collection, CollectionCreatorCap};
    use sui::tx_context::TxContext;
    use std::option::{some, none};
    use sui::object::UID;
    use sui::publisher::Publisher;
    use sui::object;
    use sui::transfer::share_object;
    use sui::collectible;
    use sui::transfer;
    use std::string;
    use sui::display;
    use sui::tx_context;
    use std::string::String;

    struct TestNFt has key,store{
        id:UID,
    }

    struct Lanchpad<phantom T:store> has key {
        id:UID,
        pub:Publisher,
        mint_able:CollectionCreatorCap<T>,
    }

    struct TESTNET has drop {

    }

    fun init(winner:TESTNET,ctx:&mut TxContext) {
        let (pub,display,mint_able) = create_collection<TESTNET,TestNFt>(winner,some(200),ctx);
        display::transfer(display,tx_context::sender(ctx));
        let collection = Lanchpad<TestNFt> {
            id:object::new(ctx),
            pub,
            mint_able,
        };

        share_object(collection);
    }

    public entry fun mint<T:store>(collection:&mut Lanchpad<T>,ctx:&mut TxContext){
        let nft = collectible::mint<T>(&mut collection.mint_able,string::utf8(b"http://sui.io"),
        none<String>(),none<String>(),none<String>(),none<T>(),ctx);
        transfer::transfer(nft,tx_context::sender(ctx));
    }
}
