module bob::launchpad {
    use std::option::{Option, none};
    use std::string::String;
    use sui::collectible::CollectionCreatorCap;
    use sui::tx_context::TxContext;
    use sui::vec_map;
    use sui::object::UID;
    use sui::object;
    use sui::dynamic_object_field as ofield;
    use std::vector;
    use sui::transfer::share_object;
    use sui::tx_context;
    use sui::vec_set::VecSet;
    use sui::vec_set;

    struct Admin has key {
        id: UID,
        manage: VecSet<address>,
    }

    struct BobYardLanchpad has key {
        id: UID,
        tax_fee: u64,
        tax_fee_point: u64,
        partner: VecSet<address>,
    }

    struct LanchNFT<T: store, phantom NFT: key+store> has key, store {
        id: UID,
        name: Option<String>,
        website: Option<String>,
        url: Option<String>,
        img_url: String,
        meta: Option<T>,
        creater: address,
        royalt: u64,
        royalt_point: u64,
        supply: u64,
        minted: u64,

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

        paused: bool,
        minted_wallet: vec_map::VecMap<address, u64>,
        mint_cap: CollectionCreatorCap<NFT>
    }

    fun init(ctx: &mut TxContext) {
        let admin = Admin {
            id: object::new(ctx),
            manage: vec_set::empty(),
        };

        vec_set::insert(&mut admin.manage, tx_context::sender(ctx));

        let bobyard = BobYardLanchpad {
            id: object::new(ctx),
            tax_fee: 0,
            tax_fee_point: 10000,
            partner: vec_set::empty(),
        };

        share_object(bobyard);
        share_object(admin);
    }

    public fun init_launchpad<T: store, NFT: key+store>(
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
        mint_cap: CollectionCreatorCap<NFT>,
        ctx: &mut TxContext,
    ) {
        let lanch = LanchNFT<T, NFT> {
            id: object::new(ctx),
            name,
            website,
            url,
            img_url,
            meta,
            creater,
            royalt,
            royalt_point,
            supply,
            minted: 0,
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
            paused: false,
            minted_wallet: vec_map::empty<address, u64>(),
            mint_cap,
        };

        let id = object::id(&lanch);
        //event here
        ofield::add(&mut bobyard.id, id, lanch);
    }

    public entry fun og_mint() {}

    public entry fun pre_mint() {}

    public entry fun public_mint() {}
}