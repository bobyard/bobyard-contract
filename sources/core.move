module bob::core {
    use bob::events::{EmitBuyEvent, EmitListEvent};
    use sui::clock::{Clock, timestamp_ms};
    use sui::coin::{Coin, Self};
    use sui::dynamic_object_field as dyn;
    use sui::object::{Self, ID, UID};
    use sui::transfer::{Self, public_transfer};
    use sui::tx_context::{Self, TxContext};


    friend bob::manage;
    friend bob::internal;

    #[test_only]
    friend bob::core_tests;

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;
    const EBuyerCanBeSeller: u64 = 3;
    const EExpired: u64 = 4;
    const ENotLastVersion: u64 = 5;

    const VERSION: u64 = 0;
    const TX_FEE_DECIMAL: u64 = 10000;

    struct Market<phantom T> has key {
        id: UID,
        offer_id: UID,
        fee: u64,
        fee_coin: Coin<T>,
        version: u64,
    }

    struct Listing has key, store {
        id: UID,
        ask: u64,
        expire_time: u64,
        owner: address,
    }

    struct Offer<phantom T> has key, store {
        id: UID,
        list_id: ID,
        paid: Coin<T>,
        expire_time: u64,
        owner: address,
    }

    public(friend) fun init_market<T>(ctx: &mut TxContext) {
        let id = object::new(ctx);
        let offer_id = object::new(ctx);
        transfer::share_object(
            Market<T> {
                id, offer_id, fee: 50, fee_coin: coin::zero<T>(
                    ctx
                ), version: VERSION
            }
        )
    }

    public(friend) fun is_last<T>(mk: &mut Market<T>): bool {
        mk.version == VERSION
    }

    public(friend) fun buy_one<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        paid: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ): ITEM {
        let Listing {
            id,
            ask,
            expire_time,
            owner
        } = dyn::remove(&mut marketplace.id, list_id);
        assert!(ask == coin::value(&paid), EAmountIncorrect);
        assert!(timestamp_ms(clock) <= expire_time, EExpired);

        let buyer = tx_context::sender(ctx);
        assert!(buyer != owner, EBuyerCanBeSeller);

        let item: ITEM = dyn::remove(&mut id, true);
        let item_id = object::id(&item);
        object::delete(id);

        EmitBuyEvent<T>(list_id, item_id, ask, owner, buyer);
        take_market_fee(marketplace, &mut paid, ctx);
        public_transfer(paid, owner);
        item
    }

    public(friend) fun sweep<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        paid: &mut Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let Listing {
            id,
            ask,
            expire_time,
            owner
        } = dyn::remove(&mut marketplace.id, list_id);
        assert!(ask <= coin::value(paid), EAmountIncorrect);
        assert!(timestamp_ms(clock) <= expire_time, EExpired);

        let buyer = tx_context::sender(ctx);
        assert!(buyer != owner, EBuyerCanBeSeller);

        let item: ITEM = dyn::remove(&mut id, true);
        let item_id = object::id(&item);
        object::delete(id);

        EmitBuyEvent<T>(list_id, item_id, ask, owner, buyer);
        let to_seller = coin::split(paid, ask, ctx);

        take_market_fee(marketplace, &mut to_seller, ctx);

        public_transfer(to_seller, owner);
        public_transfer(item, owner);
        EmitBuyEvent<T>(list_id, item_id, ask, owner, buyer);
    }

    public(friend) fun change_listing_price_and_time<T, ITEM: key+store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        ask: u64,
        expire_time: u64,
        ctx: &mut TxContext
    ) {
        let listing = dyn::borrow_mut<ID, Listing>(&mut marketplace.id, list_id);
        assert!(tx_context::sender(ctx) == listing.owner, ENotOwner);

        listing.ask = ask;
        listing.expire_time = expire_time;
        let item_id = object::id(listing);

        EmitListEvent<T>(list_id, item_id, ask, expire_time, listing.owner);
    }

    public(friend) fun init_list(
        ask: u64,
        expire_time: u64,
        owner: address,
        ctx: &mut TxContext,
    ): Listing {
        Listing {
            id: object::new(ctx),
            ask,
            expire_time,
            owner,
        }
    }

    public(friend) fun init_offer<T>(
        list_id: ID,
        paid: Coin<T>,
        expire_time: u64,
        owner: address,
        ctx: &mut TxContext,
    ): Offer<T> {
        Offer<T> {
            id: object::new(ctx),
            list_id,
            paid,
            expire_time,
            owner,
        }
    }

    public(friend) fun add_item_to_list<T, NAME: copy+drop+store, ITEM: key+store>(
        listing: &mut Listing,
        name: NAME,
        item: ITEM
    ) {
        dyn::add<NAME, ITEM>(&mut listing.id, name, item);
    }

    public(friend) fun add_listing_to_market<T, NAME: copy+drop+store, ITEM: key+store>(
        market: &mut Market<T>,
        name: NAME,
        listing: Listing
    ) {
        dyn::add<NAME, Listing>(&mut market.id, name, listing);
    }

    public(friend) fun rem_item_from_list<T, NAME: copy+drop+store, ITEM: key+store>(
        listing: &mut Listing,
        name: NAME
    ): ITEM {
        dyn::remove<NAME, ITEM>(&mut listing.id, name)
    }

    public(friend) fun rem_listing_from_market<T, NAME: copy+drop+store>(
        market: &mut Market<T>,
        name: NAME
    ): (UID, u64, u64, address) {
        let Listing {
            id,
            ask,
            expire_time,
            owner,
        } = dyn::remove<NAME, Listing>(&mut market.id, name);
        (id, ask, expire_time, owner)
    }

    public(friend) fun add_offer_to_market<T>(
        market: &mut Market<T>,
        offer: Offer<T>
    ) {
        dyn::add<ID, Offer<T>>(&mut market.offer_id, object::id(&offer), offer);
    }

    public(friend) fun rem_offer_from_market<T>(
        market: &mut Market<T>,
        offer_id: ID
    ): (UID, ID, Coin<T>, u64, address) {
        let Offer {
            id,
            list_id,
            paid,
            expire_time,
            owner,
        } = dyn::remove<ID, Offer<T>>(&mut market.offer_id, offer_id);
        (id, list_id, paid, expire_time, owner)
    }

    public(friend) fun change_market_fee<T>(
        market: &mut Market<T>,
        fee: u64
    ) {
        market.fee = fee;
    }

    public(friend) fun take_market_fee_coin<T>(
        market: &mut Market<T>,
        ctx: &mut TxContext
    ) {
        let fee = coin::value(&market.fee_coin);
        let take = coin::split(&mut market.fee_coin, fee, ctx);
        public_transfer(take, tx_context::sender(ctx));
    }

    public(friend) fun take_market_fee<T>(
        market: &mut Market<T>,
        paid: &mut Coin<T>,
        ctx: &mut TxContext
    ) {
        let paid_val = coin::value(paid);
        let fee = market.fee * paid_val / TX_FEE_DECIMAL;
        let take = coin::split(paid, fee, ctx);
        coin::join(&mut market.fee_coin, take);
    }

    #[test]
    fun test_take_market_fee() {
        use sui::sui::SUI;
        use sui::test_scenario::{Self, next_tx};
        use sui::test_utils;

        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);
        // let clock = clock::create_for_testing(&mut ctx);
        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let coin = coin::mint_for_testing<SUI>(100, &mut ctx);
        take_market_fee(&mut market, &mut coin, &mut ctx);
        assert!(coin::value(&coin) == 100, 1);
        assert!(coin::value(&market.fee_coin) == 0, 2);
        test_utils::destroy(coin);

        let coin = coin::mint_for_testing<SUI>(1000, &mut ctx);
        take_market_fee(&mut market, &mut coin, &mut ctx);
        assert!(coin::value(&coin) == 995, 3);
        assert!(coin::value(&market.fee_coin) == 5, 4);

        test_utils::destroy(coin);

        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_take_market_fee_coin() {
        use sui::sui::SUI;
        use sui::test_scenario::{Self, next_tx};
        use sui::test_utils;

        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);
        // let clock = clock::create_for_testing(&mut ctx);
        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let coin = coin::mint_for_testing<SUI>(1000, &mut ctx);
        take_market_fee(&mut market, &mut coin, &mut ctx);
        assert!(coin::value(&coin) == 995, 3);
        assert!(coin::value(&market.fee_coin) == 5, 4);
        test_utils::destroy(coin);

        take_market_fee_coin(&mut market, &mut ctx);
        next_tx(&mut scenario, sender);
        let coin = test_scenario::take_from_sender<Coin<SUI>>(&mut scenario);
        assert!(coin::value(&coin) == 5, 5);
        assert!(coin::value(&market.fee_coin) == 0, 6);
        test_utils::destroy(coin);

        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }
}