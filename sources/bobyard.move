module bob::bobYard {
    use bob::admin::{Manage, is_admin};
    use bob::events::{EmitListEvent, EmitDeListEvent, EmitBuyEvent, EmitAcceptOfferEvent, EmitOfferEvent, EmitCancelOfferEvent};
    use sui::clock::{Clock, timestamp_ms};
    use sui::coin::{Coin, Self};
    use sui::dynamic_object_field as dyn;
    use sui::object::{Self, ID, UID};
    use sui::transfer::{Self, public_transfer};
    use sui::tx_context::{Self, TxContext};

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;
    const EBuyerCanBeSeller: u64 = 3;
    const EExpired: u64 = 4;

    struct BobYardMakret<phantom T> has key {
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

    public entry fun create<T>(manage: &Manage, ctx: &mut TxContext) {
        assert!(is_admin(manage, ctx), ENotOwner);
        let id = object::new(ctx);
        let offer_id = object::new(ctx);
        transfer::share_object(BobYardMakret<T> { id, offer_id, owner: tx_context::sender(ctx) })
    }

    public entry fun list<T, ITEM: key + store>(
        marketplace: &mut BobYardMakret<T>,
        item: ITEM,
        ask: u64,
        expire_time: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(ask > 0, EAmountIncorrect);
        assert!(expire_time > timestamp_ms(clock), EExpired);

        let owner = tx_context::sender(ctx);
        let listing = Listing {
            id: object::new(ctx),
            ask,
            expire_time,
            owner,
        };

        let list_id = object::id(&listing);
        let item_object_id = object::id(&item);
        dyn::add(&mut listing.id, true, item);
        dyn::add(&mut marketplace.id, list_id, listing);

        EmitListEvent<T>(list_id, item_object_id, ask, expire_time, owner)
    }

    public entry fun delist<T, ITEM: key + store>(
        marketplace: &mut BobYardMakret<T>,
        list_id: ID,
        ctx: &mut TxContext
    ) {
        let Listing {
            id,
            owner,
            expire_time,
            ask,
        } = dyn::remove(&mut marketplace.id, list_id);
        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        let item: ITEM = dyn::remove(&mut id, true);
        let item_object_id = object::id(&item);
        public_transfer(item, owner);
        object::delete(id);

        EmitDeListEvent<T>(list_id, item_object_id, ask, expire_time, owner)
    }

    public entry fun buy_one<T, ITEM: key + store>(
        marketplace: &mut BobYardMakret<T>,
        item_id: ID,
        paid: Coin<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        public_transfer(
            buy<T, ITEM>(marketplace, item_id, paid, clock, ctx),
            sender
        );
    }

    public entry fun accept_offer<T, BuyItem: key+store>(
        marketplace: &mut BobYardMakret<T>,
        list_id: ID,
        offer_id: ID,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let Listing {
            id: list_uid,
            owner,
            expire_time: _,
            ask: _,
        } = dyn::remove(&mut marketplace.id, list_id);

        assert!(sender == owner, ENotOwner);

        //for buyer
        let Offer<T> {
            id: offer_uid,
            list_id,
            paid,
            expire_time,
            owner: buyer,
        } = dyn::remove(&mut marketplace.offer_id, offer_id);

        assert!(expire_time > timestamp_ms(clock), EExpired);
        assert!(&list_id == object::uid_as_inner(&list_uid), EEmptyObjects);
        let offer_amount = coin::value(&paid);

        object::delete(offer_uid);
        public_transfer(paid, owner);

        // for seller
        let list_item: BuyItem = dyn::remove(&mut list_uid, true);
        let item_id = object::id(&list_item);
        object::delete(list_uid);
        public_transfer(list_item, buyer);

        // emit event
        EmitAcceptOfferEvent<T>(offer_id, list_id,item_id, owner, buyer, offer_amount)
    }

    public entry fun make_offer<T>(
        marketplace: &mut BobYardMakret<T>,
        list_id: ID,
        paid: Coin<T>,
        expire_time: u64,
        ctx: &mut TxContext)
    {
        let amount = coin::value(&paid);

        let offer = Offer {
            id: object::new(ctx),
            list_id,
            paid,
            expire_time,
            owner: tx_context::sender(ctx)
        };
        let id = object::id(&offer);
        dyn::add(&mut marketplace.offer_id, id, offer);

        EmitOfferEvent<T>(id, list_id, expire_time, amount, tx_context::sender(ctx))
    }

    public entry fun cancel_offer<T>(
        marketplace: &mut BobYardMakret<T>,
        offer_id: ID,
        ctx: &mut TxContext
    ) {
        let Offer<T> {
            id,
            list_id,
            paid,
            expire_time: _,
            owner,
        } = dyn::remove(&mut marketplace.offer_id, offer_id);
        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        EmitCancelOfferEvent<T>(offer_id, list_id, owner);
        public_transfer(paid, owner);
        object::delete(id);
    }

    fun buy<T, ITEM: key + store>(
        marketplace: &mut BobYardMakret<T>,
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

        EmitBuyEvent<T>(list_id,item_id ,ask, owner, buyer);
        public_transfer(paid, owner);
        item
    }
}