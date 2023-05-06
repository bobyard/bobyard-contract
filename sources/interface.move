module bob::interface {
    use bob::bobYard::{Market, is_last};
    use bob::core;
    use sui::clock::{Clock, timestamp_ms};
    use sui::coin::Coin;
    use sui::object:: ID;
    use sui::tx_context::TxContext;

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

        core::list<T, ITEM>(marketplace, item, ask, expire_time, clock, ctx);
    }

    public entry fun change_listing<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        ask: u64,
        expire_time: u64,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);
        core::change_listing<T, ITEM>(marketplace, list_id, ask, expire_time, ctx);
    }

    public entry fun delist<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);
        core::delist<T, ITEM>(marketplace, list_id, ctx);
    }

    public entry fun buy_one<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        item_id: ID,
        paid: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);
        core::buy<T, ITEM>(marketplace, item_id, paid, clock, ctx);
    }

    public entry fun sweep<T, ITEM: key+store>(
        marketplace: &mut Market<T>,
        item_ids: vector<ID>,
        paid: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);
        core::sweep<T, ITEM>(marketplace, item_ids, paid, clock, ctx);
    }


    public entry fun make_offer<T>(
        marketplace: &mut Market<T>,
        list_id: ID,
        paid: Coin<T>,
        expire_time: u64,
        ctx: &mut TxContext)
    {
        assert!(is_last(marketplace), ENotLastVersion);
        core::make_offer(marketplace, list_id, paid, expire_time, ctx);
    }

    public entry fun cancel_offer<T>(
        marketplace: &mut Market<T>,
        offer_id: ID,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);
        core::cancel_offer<T>(marketplace, offer_id, ctx);
    }

    public entry fun accept_offer<T, BuyItem: key+store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        offer_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(is_last(marketplace), ENotLastVersion);
        core::accept_offer<T, BuyItem>(marketplace, list_id, offer_id, clock, ctx);
    }
}
