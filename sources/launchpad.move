module bob::launchpad {
    use std::option::{Option, some, none};
    use std::string::String;
    use sui::collectible::CollectionCreatorCap;
    use sui::tx_context::TxContext;
    use sui::vec_map;
    use sui::object::{UID, ID};
    use sui::object;
    use sui::dynamic_object_field as ofield;
    use sui::transfer::share_object;
    use sui::tx_context;
    use sui::vec_set::VecSet;
    use sui::vec_set;
    use sui::collectible;
    use sui::transfer;
    use std::string;
    use std::bcs;

    const EINVALID_AMOUNT:u64 = 0;

    struct Admin has key {
        id: UID,
        manage: VecSet<address>,
    }

    struct BobYardLaunchpad has key {
        id: UID,
        tax_fee: u64,
        tax_fee_point: u64,
        partner: VecSet<address>,
    }

    struct LanchNFT<phantom NFT: key+store> has key, store {
        id: UID,
        name: Option<String>,
        website: Option<String>,
        url: Option<String>,
        img_url: String,
        description:String,
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

        let bobyard = BobYardLaunchpad {
            id: object::new(ctx),
            tax_fee: 0,
            tax_fee_point: 10000,
            partner: vec_set::empty(),
        };

        share_object(bobyard);
        share_object(admin);
    }

    public fun init_launchpad<NFT: key+store>(
        bobyard: &mut BobYardLaunchpad,
        name: Option<String>,
        website: Option<String>,
        url: Option<String>,
        img_url: String,
        description:String,
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
        let lanch = LanchNFT<NFT> {
            id: object::new(ctx),
            name,
            website,
            url,
            img_url,
            description,
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

    public entry fun og_mint<T: store, NFT: key+store>(bobyard: &mut BobYardLaunchpad, launch_id:ID, _proof:vector<vector<u8>>, num:u64, ctx:&mut TxContext) {
        let receiver_addr = tx_context::sender(ctx);

        let launchpad = ofield::borrow_mut<ID,LanchNFT<NFT>>(&mut bobyard.id,launch_id);
        // assert!(merkle_proof::verify(&proof, launch_data.merkle_root, hash::sha2_256(bcs::to_bytes(&receiver_addr))),INVALID_PROOF);
        // assert!(number <= launch_data.presale_mint_price, INVALID_AMOUNT);
        // assert!(launch_data.paused == false, EPAUSED);
        // assert!(launch_data.minted != launch_data.total_supply, ESOLD_OUT);
        // assert!(now > launch_data.presale_mint_time, ESALE_NOT_STARTED);

        // check already minted.
        if (vec_map::contains(&launchpad.minted_wallet, &receiver_addr)) {
            let mint_by_receiver = vec_map::get_mut(&mut launchpad.minted_wallet, &receiver_addr);
            assert!(*mint_by_receiver + num <= launchpad.public_mint_amount, EINVALID_AMOUNT);
            *mint_by_receiver = *mint_by_receiver + num;
        } else {
            vec_map::insert(&mut launchpad.minted_wallet, receiver_addr, num);
        };

        let i = 0;
        while (i < num) {
            mint_random(receiver_addr, launchpad,ctx);

            i =i+1;
        };


        // //Check if mintend. we changed the timestrap to now, then user can't clam him tokens
        // if (launchpad.minted == launchpad.supply) {
        //     launch_data.public_sale_end_time = now;
        //     launch_data.presale_end_time = now;
        // };
    }

    // public entry fun pre_mint(bobyard: &mut BobYardLaunchpad, launch_id:ID, proof:vector<u8>, num:u64, ctx:&mut TxContext) {}
    // public entry fun public_mint(bobyard: &mut BobYardLaunchpad, launch_id:ID, num:u64, ctx:&mut TxContext) {}

    fun mint_random<NFT: key+store>(recver:address,lanchpad: &mut LanchNFT<NFT>,ctx:&mut TxContext) {
        let nft = collectible::mint<NFT>(&mut lanchpad.mint_cap,lanchpad.img_url,
            lanchpad.name,none<String>(),some(string::utf8(bcs::to_bytes(&lanchpad.creater))),none(),ctx);
        transfer::transfer(nft,recver);
    }
}