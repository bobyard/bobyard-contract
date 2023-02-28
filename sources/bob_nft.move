module bob::nft {
    use sui::tx_context::TxContext;
    use sui::collectible::{create_collection, CollectionCreatorCap, Collectible};
    use sui::transfer::{share_object, transfer};
    use std::option::{none, Option};
    use sui::object::UID;
    use sui::object;
    use sui::publisher::Publisher;
    use sui::display;
    use bob::launchpad::{BobYardLanchpad, init_launchpad};
    use std::string::String;
    use sui::tx_context;

    struct NFT has drop {}

    struct BobYard has key, store {
        id: UID,
    }

    struct Hoder has key, store {
        id: UID,
        pub: Publisher,
        mint_ablity: CollectionCreatorCap<BobYard>
    }

    fun init(winer: NFT, ctx: &mut TxContext) {
        let (pub, display, mint_ablity) = create_collection<NFT, BobYard>(winer, none(), ctx);
        display::share(display);

        let h = Hoder {
            pub,
            id: object::new(ctx),
            mint_ablity
        };
        share_object(h);
    }

    public entry fun create_lanchpad<T:store>(
        bobyard: &mut BobYardLanchpad,
        name: Option<String>,
        website: Option<String>,
        url: Option<String>,
        img_url: String,
        meta: Option<T>,
        creater: address,
        royalt: u64,
        royalt_point: u64,
        supply: u64,
        og_mint_amount: Option<u64>,
        og_mint_proce: Option<u64>,
        og_mint_time: Option<u64>,
        og_end_time: Option<u64>,
        presale_mint_amount: Option<u64>,
        presale_mint_price: Option<u64>,
        presale_mint_time: Option<u64>,
        presale_end_time: Option<u64>,
        public_mint_amount: u64,
        public_mint_price: u64,
        public_sale_mint_time: u64,
        public_sale_end_time: u64,
        hoder:Hoder,
        ctx: &mut TxContext,
    ) {
        let Hoder{id,pub,mint_ablity} = hoder;
        object::delete(id);
        transfer(pub,tx_context::sender(ctx));

        init_launchpad(
            bobyard,
            name,
            website,
            url,
            img_url,
            meta,
            creater,
            royalt,
            royalt_point,
            supply,
            og_mint_amount,
            og_mint_proce,
            og_mint_time,
            og_end_time,
            presale_mint_amount,
            presale_mint_price,
            presale_mint_time,
            presale_end_time,
            public_mint_amount,
            public_mint_price,
            public_sale_mint_time,
            public_sale_end_time,
            mint_ablity,
            ctx,
        );
    }
}