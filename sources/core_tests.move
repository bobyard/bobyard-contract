#[test_only]
module bob::core_tests {
    use bob::core::{Self, init_market, Market, init_list, add_item_to_list, add_listing_to_market, Listing, buy_one, rem_listing_from_market, sweep, init_offer, add_offer_to_market, rem_offer_from_market, take_market_fee, change_listing_price_and_time};
    use sui::clock::{Self, timestamp_ms};
    use sui::coin;
    use sui::dynamic_object_field as dyn;
    use sui::object::{Self, UID, ID};
    use sui::test_scenario::{Self, next_tx};
    use sui::test_utils::{Self, destroy};
    use sui::tx_context;

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;
    const EBuyerCanBeSeller: u64 = 3;
    const EExpired: u64 = 4;
    const ENotLastVersion: u64 = 5;

    #[test_only]
    struct Item has key, store {
        id: UID,
    }

    #[test]
    fun test_list() {
        use sui::sui::SUI;
        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);
        // let clock = clock::create_for_testing(&mut ctx);
        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let clock = clock::create_for_testing(&mut ctx);

        let item = Item { id: object::new(&mut ctx) };

        let listing = init_list(100, 100, sender, &mut ctx);
        let list_id = object::id(&listing);

        add_item_to_list<SUI, bool, Item>(&mut listing, true, item);
        add_listing_to_market<SUI, ID, Listing>(&mut market, list_id, listing);


        test_utils::destroy(clock);
        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = core::EBuyerCanBeSeller)]
    fun test_list_and_buy_with_same_sender() {
        use sui::sui::SUI;
        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);
        // let clock = clock::create_for_testing(&mut ctx);
        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let clock = clock::create_for_testing(&mut ctx);

        let item = Item { id: object::new(&mut ctx) };

        let listing = init_list(100, 100, sender, &mut ctx);
        let list_id = object::id(&listing);

        add_item_to_list<SUI, bool, Item>(&mut listing, true, item);
        add_listing_to_market<SUI, ID, Listing>(&mut market, list_id, listing);
        let paid = coin::mint_for_testing<SUI>(100, &mut ctx);
        let item = buy_one<SUI, Item>(&mut market, list_id, paid, &clock, &mut ctx);

        test_utils::destroy(item);
        test_utils::destroy(clock);
        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_list_and_buy_with_different_sender() {
        use sui::sui::SUI;
        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);
        // let clock = clock::create_for_testing(&mut ctx);
        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let clock = clock::create_for_testing(&mut ctx);

        let item = Item { id: object::new(&mut ctx) };

        let listing = init_list(100, 100, sender, &mut ctx);
        let list_id = object::id(&listing);

        add_item_to_list<SUI, bool, Item>(&mut listing, true, item);
        add_listing_to_market<SUI, ID, Listing>(&mut market, list_id, listing);
        let paid = coin::mint_for_testing<SUI>(100, &mut ctx);
        let buyer = tx_context::new_from_hint(@0x999, 0, 0, 0, 0);
        let item = buy_one<SUI, Item>(&mut market, list_id, paid, &clock, &mut buyer);

        test_utils::destroy(item);
        test_utils::destroy(clock);
        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_list_and_buy_with_buger_amount() {
        use sui::sui::SUI;
        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);
        // let clock = clock::create_for_testing(&mut ctx);
        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let clock = clock::create_for_testing(&mut ctx);

        let item = Item { id: object::new(&mut ctx) };

        let listing = init_list(100, 100, sender, &mut ctx);
        let list_id = object::id(&listing);

        add_item_to_list<SUI, bool, Item>(&mut listing, true, item);
        add_listing_to_market<SUI, ID, Listing>(&mut market, list_id, listing);
        let paid = coin::mint_for_testing<SUI>(101, &mut ctx);
        let buyer = tx_context::new_from_hint(@0x999, 0, 0, 0, 0);
        //biger when amount is fine.
        sweep<SUI, Item>(&mut market, list_id, &mut paid, &clock, &mut buyer);
        destroy(paid);

        //test_utils::destroy(item);
        test_utils::destroy(clock);
        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = core::EAmountIncorrect)]
    fun test_list_and_buy_with_lesser_amount() {
        use sui::sui::SUI;
        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);
        // let clock = clock::create_for_testing(&mut ctx);
        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let clock = clock::create_for_testing(&mut ctx);

        let item = Item { id: object::new(&mut ctx) };

        let listing = init_list(100, 100, sender, &mut ctx);
        let list_id = object::id(&listing);

        add_item_to_list<SUI, bool, Item>(&mut listing, true, item);
        add_listing_to_market<SUI, ID, Listing>(&mut market, list_id, listing);
        let paid = coin::mint_for_testing<SUI>(1, &mut ctx);
        let buyer = tx_context::new_from_hint(@0x999, 0, 0, 0, 0);
        //less when amount is not ok.
        sweep<SUI, Item>(&mut market, list_id, &mut paid, &clock, &mut buyer);
        destroy(paid);


        test_utils::destroy(clock);
        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = core::EExpired)]
    fun test_list_and_buy_with_expred() {
        use sui::sui::SUI;
        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);

        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let clock = clock::create_for_testing(&mut ctx);

        let item = Item { id: object::new(&mut ctx) };

        let listing = init_list(100, 100, sender, &mut ctx);
        let list_id = object::id(&listing);
        clock::increment_for_testing(&mut clock, 101);

        add_item_to_list<SUI, bool, Item>(&mut listing, true, item);
        add_listing_to_market<SUI, ID, Listing>(&mut market, list_id, listing);
        let paid = coin::mint_for_testing<SUI>(100, &mut ctx);
        let buyer = tx_context::new_from_hint(@0x999, 0, 0, 0, 0);
        //less when amount is not ok.
        sweep<SUI, Item>(&mut market, list_id, &mut paid, &clock, &mut buyer);
        destroy(paid);


        test_utils::destroy(clock);
        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_list_and_delist() {
        use sui::sui::SUI;
        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);
        // let clock = clock::create_for_testing(&mut ctx);
        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let clock = clock::create_for_testing(&mut ctx);

        let item = Item { id: object::new(&mut ctx) };

        let listing = init_list(100, 100, sender, &mut ctx);
        let list_id = object::id(&listing);
        let item_id = object::id(&item);

        add_item_to_list<SUI, bool, Item>(&mut listing, true, item);
        add_listing_to_market<SUI, ID, Listing>(&mut market, list_id, listing);

        let (
            id,
            ask,
            expire_time,
            owner,
        ) = rem_listing_from_market<SUI, ID>(&mut market, list_id);
        assert!(sender == owner, ENotOwner);
        assert!(ask == 100, EAmountIncorrect);
        assert!(expire_time == 100, EAmountIncorrect);

        let item: Item = dyn::remove(&mut id, true);
        assert!(item_id == object::id(&item), EEmptyObjects);

        object::delete(id);
        test_utils::destroy(item);
        test_utils::destroy(clock);
        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_change_price_and_timer() {
        use sui::sui::SUI;
        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);
        // let clock = clock::create_for_testing(&mut ctx);
        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let clock = clock::create_for_testing(&mut ctx);

        let item = Item { id: object::new(&mut ctx) };

        let listing = init_list(100, 100, sender, &mut ctx);
        let list_id = object::id(&listing);
        let item_id = object::id(&item);

        add_item_to_list<SUI, bool, Item>(&mut listing, true, item);
        add_listing_to_market<SUI, ID, Listing>(&mut market, list_id, listing);


        change_listing_price_and_time<SUI, Item>(&mut market, list_id, 200, 200, &mut ctx);

        let (
            id,
            ask,
            expire_time,
            owner,
        ) = rem_listing_from_market<SUI, ID>(&mut market, list_id);
        assert!(sender == owner, ENotOwner);
        assert!(ask == 200, EAmountIncorrect);
        assert!(expire_time == 200, EAmountIncorrect);

        let item: Item = dyn::remove(&mut id, true);
        assert!(item_id == object::id(&item), EEmptyObjects);

        object::delete(id);
        test_utils::destroy(item);
        test_utils::destroy(clock);
        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_offer() {
        use sui::sui::SUI;
        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);

        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let clock = clock::create_for_testing(&mut ctx);

        let item = Item { id: object::new(&mut ctx) };

        let listing = init_list(1000, 100, sender, &mut ctx);
        let list_id = object::id(&listing);
        let item_id = object::id(&item);

        add_item_to_list<SUI, bool, Item>(&mut listing, true, item);
        add_listing_to_market<SUI, ID, Listing>(&mut market, list_id, listing);

        let paid = coin::mint_for_testing<SUI>(1000, &mut ctx);
        let offer = init_offer(list_id, paid, 100, sender, &mut ctx);

        let offer_id = object::id(&offer);
        add_offer_to_market(&mut market, offer);

        let (
            list_uid,
            _,
            _,
            owner,
        ) = rem_listing_from_market<SUI, ID>(&mut market, list_id);
        assert!(sender == owner, ENotOwner);

        let (
            offer_uid,
            list_id,
            paid,
            expire_time,
            _,
        ) = rem_offer_from_market(&mut market, offer_id);

        assert!(expire_time > timestamp_ms(&clock), EExpired);
        assert!(&list_id == object::uid_as_inner(&list_uid), EEmptyObjects);

        let offer_amount = coin::value(&paid);
        assert!(offer_amount == 1000, EAmountIncorrect);
        take_market_fee(&mut market, &mut paid, &mut ctx);
        assert!(coin::value(&paid) == 995, EAmountIncorrect);

        object::delete(offer_uid);

        let list_item: Item = dyn::remove(&mut list_uid, true);
        object::delete(list_uid);
        assert!(item_id == object::id(&list_item), EEmptyObjects);

        test_utils::destroy(paid);
        test_utils::destroy(list_item);
        test_utils::destroy(clock);
        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_cancel_offer() {
        use sui::sui::SUI;
        let ctx = tx_context::dummy();
        let sender = tx_context::sender(&mut ctx);
        let scenario = test_scenario::begin(sender);

        init_market<SUI>(&mut ctx);
        next_tx(&mut scenario, sender);
        let market = test_scenario::take_shared<Market<SUI>>(&mut scenario);
        let clock = clock::create_for_testing(&mut ctx);

        let item = Item { id: object::new(&mut ctx) };

        let listing = init_list(1000, 100, sender, &mut ctx);
        let list_id = object::id(&listing);


        add_item_to_list<SUI, bool, Item>(&mut listing, true, item);
        add_listing_to_market<SUI, ID, Listing>(&mut market, list_id, listing);

        let paid = coin::mint_for_testing<SUI>(1000, &mut ctx);
        let offer = init_offer(list_id, paid, 100, sender, &mut ctx);

        let offer_id = object::id(&offer);
        add_offer_to_market(&mut market, offer);

        let (
            id,
            _,
            paid,
            _,
            owner,
        ) = rem_offer_from_market(&mut market, offer_id);
        assert!(sender == owner, ENotOwner);

        object::delete(id);
        test_utils::destroy(paid);
        test_utils::destroy(clock);
        test_scenario::return_shared(market);
        test_scenario::end(scenario);
    }
}
