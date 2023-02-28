module bob::nft{
    use sui::tx_context::TxContext;
    use sui::collectible::{create_collection, CollectionCreatorCap, Collectible};
    use sui::transfer::share_object;
    use std::option::none;
    use sui::object::UID;
    use sui::object;
    use sui::publisher::Publisher;
    use sui::display::Display;
    use sui::transfer;
    use sui::tx_context;

    struct NFT has drop{}

    struct BobYard has key,store{
        id:UID,
    }

    struct Hoder has key,store{
        id:UID,
        pub:Publisher,

        mint_ablity:CollectionCreatorCap<BobYard>
    }

    fun init(winer:NFT,ctx:&mut TxContext){
        let (pub,display,mint_ablity) = create_collection<NFT,BobYard>(winer,none(),ctx);
        transfer::transfer(display,tx_context::sender(ctx));

        let h = Hoder {
            pub,
            id:object::new(ctx),
            mint_ablity
        };

        share_object(h);
    }
}