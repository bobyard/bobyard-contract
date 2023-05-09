module bob::BobYardIO {

    use bob::core::Market;
    use sui::clock::Clock;
    use sui::tx_context::TxContext;
    use bob::bobYard;
    use sui::object::ID;
    use sui::coin::Coin;

    public entry fun list<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        item: ITEM,
        ask: u64,
        expire_time: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        bobYard::list<T, ITEM>(marketplace, item, ask, expire_time, clock, ctx);
    }

    public entry fun change_listing<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        ask: u64,
        expire_time: u64,
        ctx: &mut TxContext
    ) {
        bobYard::change_listing<T, ITEM>(marketplace, list_id, ask, expire_time, ctx);
    }

    public entry fun delist<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        ctx: &mut TxContext
    ) {
        bobYard::delist<T, ITEM>(marketplace, list_id, ctx);
    }

    public entry fun buy_one<T, ITEM: key + store>(
        marketplace: &mut Market<T>,
        item_id: ID,
        paid: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        bobYard::buy<T, ITEM>(marketplace, item_id, paid, clock, ctx);
    }

    public entry fun sweep<T, ITEM: key+store>(
        marketplace: &mut Market<T>,
        item_ids: vector<ID>,
        paid: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        bobYard::sweep<T, ITEM>(marketplace, item_ids, paid, clock, ctx);
    }


    public entry fun make_offer<T>(
        marketplace: &mut Market<T>,
        list_id: ID,
        paid: Coin<T>,
        expire_time: u64,
        ctx: &mut TxContext)
    {
        bobYard::make_offer(marketplace, list_id, paid, expire_time, ctx);
    }

    public entry fun cancel_offer<T>(
        marketplace: &mut Market<T>,
        offer_id: ID,
        ctx: &mut TxContext
    ) {
        cancel_offer<T>(marketplace, offer_id, ctx);
    }

    public entry fun accept_offer<T, BuyItem: key+store>(
        marketplace: &mut Market<T>,
        list_id: ID,
        offer_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        bobYard::accept_offer<T, BuyItem>(marketplace, list_id, offer_id, clock, ctx);
    }
}
