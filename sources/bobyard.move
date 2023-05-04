module bob::bobYard {
    use bob::events::EmitBuyEvent;
    use sui::clock::{Clock, timestamp_ms};
    use sui::coin::{Coin, Self};
    use sui::dynamic_object_field as dyn;
    use sui::object::{Self, ID, UID};
    use sui::transfer::{Self, public_transfer};
    use sui::tx_context::{Self, TxContext};

    friend bob::interface;
    friend bob::admin;

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;
    const EBuyerCanBeSeller: u64 = 3;
    const EExpired: u64 = 4;


    struct Market<phantom T> has key {
        id: UID,
        offer_id: UID,
        owner: address
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

        transfer::share_object(Market<T> { id, offer_id, owner: tx_context::sender(ctx) })
    }

    public(friend) fun first_list<T, ITEM: key+store>(
        marketplace: &mut Market<T>,
        item: ITEM,
        ask: u64,
        expire_time: u64,
        owner: address,
        ctx: &mut TxContext
    ) {
        let listing = init_list(ask, expire_time, owner, ctx);
        let list_id = object::id(&listing);

        add_item_to_list<T, bool, ITEM>(&mut listing, true, item);
        add_listing_to_market<T, ID, Listing>(marketplace, list_id, listing);
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
        public_transfer(paid, owner);
        item
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
}