module bob::launchpad {

    use std::option::{Option, some, none};
    use std::string::{Self, String};

    use bob::utils::num_str;
    use sui::bcs;
    use sui::clock::{Self, Clock};
    use sui::coin::{Coin, zero, value, split};
    use sui::collectible::{Self, CollectionCreatorCap, Collectible};
    use sui::dynamic_object_field as ofield;
    use sui::object::{Self, UID, ID};
    use sui::pay::join_vec;
    use sui::transfer::{Self, share_object};
    use sui::tx_context::{Self, TxContext};
    use sui::vec_map;
    use sui::vec_set::{Self, VecSet};

    const EINVALID_AMOUNT: u64 = 0;
    const EINVALID_PROOF: u64 = 1;
    const EPAUSED: u64 = 2;
    const ESOLD_OUT: u64 = 3;
    const ESALE_NOT_STARTED: u64 = 4;
    const EINVALID_COINS: u64 = 5;

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

    struct LanchNFT<phantom NFT: key+store, phantom M> has key, store {
        id: UID,
        name: String,
        website: Option<String>,
        url: Option<String>,
        img_url: String,
        img_suffix: String,
        description: String,
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
        mint_random: bool,

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

    public fun init_launchpad<NFT: key+store, M: key+store>(
        bobyard: &mut BobYardLaunchpad,
        name: String,
        website: Option<String>,
        url: Option<String>,
        img_url: String,
        img_suffix: String,
        description: String,
        creater: address,
        royalt: u64,
        royalt_point: u64,
        supply: u64,
        mint_random: bool,
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
        //TODO check The sender is on the white list

        let lanch = LanchNFT<NFT, M> {
            id: object::new(ctx),
            name,
            website,
            url,
            img_url,
            img_suffix,
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
            mint_random,
            minted_wallet: vec_map::empty<address, u64>(),
            mint_cap,
        };

        let id = object::id(&lanch);
        //TODO event emit

        ofield::add(&mut bobyard.id, id, lanch);
    }

    public entry fun og_mint<T: store, NFT: key+store, M: key+store>(
        bobyard: &mut BobYardLaunchpad,
        launch_id: ID,
        _proof: vector<vector<u8>>,
        num: u64,
        ctx: &mut TxContext
    ) {
        let sender_address = tx_context::sender(ctx);
        let launchpad = ofield::borrow_mut<ID, LanchNFT<NFT, M>>(&mut bobyard.id, launch_id);

        // assert!(merkle_proof::verify(&proof, launch_data.merkle_root, hash::sha2_256(bcs::to_bytes(&receiver_addr))),INVALID_PROOF);
        // assert!(number <= launch_data.presale_mint_price, INVALID_AMOUNT);
        // assert!(launch_data.paused == false, EPAUSED);
        // assert!(launch_data.minted != launch_data.total_supply, ESOLD_OUT);
        // assert!(now > launch_data.presale_mint_time, ESALE_NOT_STARTED);

        // check already minted.
        if (vec_map::contains(&launchpad.minted_wallet, &sender_address)) {
            let mint_by_receiver = vec_map::get_mut(&mut launchpad.minted_wallet, &sender_address);
            assert!(*mint_by_receiver + num <= launchpad.public_mint_amount, EINVALID_AMOUNT);
            *mint_by_receiver = *mint_by_receiver + num;
        } else {
            vec_map::insert(&mut launchpad.minted_wallet, sender_address, num);
        };

        let i = 0;
        while (i < num) {
            transfer::transfer(mint(launchpad, false, ctx), sender_address);
            launchpad.minted = launchpad.minted + 1;
            i = i + 1;
        };


        // //Check if mintend. we changed the timestrap to now, then user can't clam him tokens
        // if (launchpad.minted == launchpad.supply) {
        //     launch_data.public_sale_end_time = now;
        //     launch_data.presale_end_time = now;
        // };
    }

    public entry fun public_mint<T: store, NFT: key+store, M: key+store>(
        bobyard: &mut BobYardLaunchpad,
        launch_id: ID,
        coins: vector<Coin<M>>,
        num: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender_address = tx_context::sender(ctx);
        let launchpad = ofield::borrow_mut<ID, LanchNFT<NFT, M>>(&mut bobyard.id, launch_id);
        let now = clock::timestamp_ms(clock);

        assert!(launchpad.public_mint_amount < num, EINVALID_AMOUNT);
        assert!(launchpad.paused == false, EPAUSED);
        assert!(launchpad.minted != launchpad.supply, ESOLD_OUT);
        assert!(now > launchpad.public_sale_mint_time, ESALE_NOT_STARTED);

        let paids = zero<M>(ctx);
        join_vec(&mut paids, coins);
        assert!(value(&mut paids) > num * launchpad.public_mint_price, EINVALID_COINS);
        let paid = split(&mut paids, num * launchpad.public_mint_price, ctx);
        //TODO We take launchfee or not?
        transfer::transfer(paid, launchpad.creater);

        let i: u64 = 0;
        while (i < num) {
            transfer::transfer(mint(launchpad, false, ctx), sender_address);
            launchpad.minted = launchpad.minted + 1;
            i = i + 1;
        };

        transfer::transfer(paids, sender_address)
    }

    fun mint<NFT: key+store, M: key+store>(
        launch_data: &mut LanchNFT<NFT, M>,
        is_random: bool,
        ctx: &mut TxContext
    ): Collectible<NFT> {
        let mint_position = launch_data.minted + 1;

        let baseuri = launch_data.img_url;
        string::append(&mut baseuri, num_str(mint_position));
        let token_name = launch_data.name;
        string::append(&mut token_name, string::utf8(b" #"));
        string::append(&mut token_name, num_str(mint_position));
        string::append(&mut baseuri, launch_data.img_suffix);

        collectible::mint<NFT>(&mut launch_data.mint_cap, baseuri,
            some(token_name), none<String>(), some(string::utf8(bcs::to_bytes(&launch_data.creater))), none(), ctx)
    }
}