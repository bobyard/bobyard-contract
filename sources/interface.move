module bob::interface {
    use bob::bobYard::{Self, Market, rem_listing_from_market, init_offer, add_offer_to_market, rem_offer_from_market, add_item_to_list, add_listing_to_market, init_list, Listing, is_last, change_listing_price_or_time};
    use bob::events::{EmitDeListEvent, EmitListEvent, EmitOfferEvent, EmitCancelOfferEvent, EmitAcceptOfferEvent};
    use sui::clock::{Clock, timestamp_ms};
    use sui::coin::{Self, Coin};
    use sui::dynamic_object_field as dyn;
    use sui::object::{Self, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::vector;


    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;
    const EBuyerCanBeSeller: u64 = 3;
    const EExpired: u64 = 4;
    const ENotLastVersion: u64 = 5;


    public entry fun list<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        item: ITEM,
        ask: u64,
        expire_time: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);
        assert!(ask > 0, EAmountIncorrect);
        assert!(expire_time > timestamp_ms(clock), EExpired);

        let owner = tx_context::sender(ctx);
        let item_id = object::id(&item);

        let listing = init_list(ask, expire_time, owner, ctx);
        let list_id = object::id(&listing);

        add_item_to_list<T, bool, ITEM>(&mut listing, true, item);
        add_listing_to_market<T, ID, Listing>(marketplace, list_id, listing);

        EmitListEvent<T>(list_id, item_id, ask, expire_time, owner)
    }

    public entry fun change_listing<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        ask: u64,
        expire_time: u64,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);
        change_listing_price_or_time<T, ITEM>(marketplace, list_id, ask, expire_time, ctx);
    }

    public entry fun delist<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);
        let (
            id,
            ask,
            expire_time,
            owner,
        ) = rem_listing_from_market<T, ID>(marketplace, list_id);
        assert!(tx_context::sender(ctx) == owner, ENotOwner);
        let item: ITEM = dyn::remove(&mut id, true);
        let item_object_id = object::id(&item);
        transfer::public_transfer(item, owner);
        object::delete(id);

        EmitDeListEvent<T>(list_id, item_object_id, ask, expire_time, owner)
    }

    public entry fun buy_one<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        item_id: ID,
        paid: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(
            bobYard::buy_one<T, ITEM>(marketplace, item_id, paid, clock, ctx),
            sender
        );
    }

    fun destroy_or_sender<T>(coin: Coin<T>, ctx: &mut TxContext) {
        let val = coin::value(&coin);
        if (val == 0) {
            coin::destroy_zero(coin);
        }else {
            transfer::public_transfer(coin, tx_context::sender(ctx));
        }
    }

    public entry fun sweep<T, ITEM: key+store>(
        marketplace: &mut Market<T>,
        item_ids: vector<ID>,
        paid: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);

        let length = vector::length(&item_ids);
        let i: u64 = 0;
        while (i < length) {
            let item_id = vector::pop_back(&mut item_ids);
            bobYard::sweep<T, ITEM>(marketplace, item_id, &mut paid, clock, ctx);

            i = i + 1;
        };

        destroy_or_sender(paid, ctx);
    }


    public entry fun make_offer<T>(
        marketplace: &mut Market<T>,
        list_id: ID,
        paid: Coin<T>,
        expire_time: u64,
        ctx: &mut TxContext)
    {
        assert!(is_last(marketplace), ENotLastVersion);
        let amount = coin::value(&paid);

        let offer = init_offer(list_id, paid, expire_time, tx_context::sender(ctx), ctx);
        let offer_id = object::id(&offer);
        add_offer_to_market(marketplace, offer);

        EmitOfferEvent<T>(offer_id, list_id, expire_time, amount, tx_context::sender(ctx))
    }

    public entry fun cancel_offer<T>(
        marketplace: &mut Market<T>,
        offer_id: ID,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);

        let (
            id,
            list_id,
            paid,
            _,
            owner,
        ) = rem_offer_from_market(marketplace, offer_id);
        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        EmitCancelOfferEvent<T>(offer_id, list_id, owner);
        transfer::public_transfer(paid, owner);
        object::delete(id);
    }

    public entry fun accept_offer<T, BuyItem: key+store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        offer_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);

        let sender = tx_context::sender(ctx);
        let (
            list_uid,
            _,
            _,
            owner,
        ) = rem_listing_from_market<T, ID>(marketplace, list_id);
        assert!(sender == owner, ENotOwner);

        let (
            offer_uid,
            list_id,
            paid,
            expire_time,
            buyer,
        ) = rem_offer_from_market(marketplace, offer_id);

        assert!(expire_time > timestamp_ms(clock), EExpired);
        assert!(&list_id == object::uid_as_inner(&list_uid), EEmptyObjects);
        let offer_amount = coin::value(&paid);

        object::delete(offer_uid);
        transfer::public_transfer(paid, owner);

        // for seller
        let list_item: BuyItem = dyn::remove(&mut list_uid, true);
        let item_id = object::id(&list_item);
        object::delete(list_uid);
        transfer::public_transfer(list_item, buyer);

        // emit event
        EmitAcceptOfferEvent<T>(offer_id, list_id, item_id, owner, buyer, offer_amount)
    }
}
