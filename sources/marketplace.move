module obj::marketplace {
    use sui::dynamic_object_field as ofield;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID, UID};
    use sui::coin::Coin;
    use sui::transfer;
    use std::vector;
    use sui::event;
    use sui::event::emit;

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;

    struct Marketplace<phantom T> has key {
        id: UID,
        offer_id: UID,
    }


    struct Listing has key, store {
        id: UID,
        ask: u64,
        owner: address,
    }

    struct Offers has key, store {
        id: UID,
        item_id: ID,
        expire_time: u64,
        owner: address,
    }

    struct Items<T> has key, store {
        id: UID,
        items: vector<T>,
    }

    struct Bid<T> has key, store {
        id: UID,
        list_id: ID,
        items: vector<T>,
        expire_time: u64,
    }

    struct MarketCreateEvent has copy, drop {
        id: ID,
        offer_id: ID,
    }

    struct ListEvent has copy, drop {
        list_id: ID,
        ask: u64,
        owner: address,
    }

    struct DeListEvent has copy, drop {
        list_id: ID,
        ask: u64,
        owner: address,
    }

    struct BuyEvent has copy, drop {
        list_id: ID,
        ask: u64,
        owner: address,
    }

    struct OfferEvent has copy, drop {
        offer_id: ID,
        expire_time: u64,
        owner: address,
    }

    public entry fun create<MKTYPE>(ctx: &mut TxContext) {
        //assert!(tx_context::sender(ctx) == @obj, ENotOwner);
        let id = object::new(ctx);
        let offer_id = object::new(ctx);

        emit(MarketCreateEvent {
            id: object::uid_to_inner(&id),
            offer_id: object::uid_to_inner(&offer_id),
        });

        transfer::share_object(Marketplace<MKTYPE> { id, offer_id })
    }


    public entry fun list<T: key + store, MKTYPE>(
        marketplace: &mut Marketplace<MKTYPE>,
        items: vector<T>,
        ask: u64,
        ctx: &mut TxContext
    ) {
        assert!(vector::length(&mut items) == 0, EEmptyObjects);

        let items = Items {
            id: object::new(ctx),
            items
        };


        let list_id = object::id(&mut items);
        let owner = tx_context::sender(ctx);

        let listing = Listing {
            id: object::new(ctx),
            ask,
            owner,
        };

        ofield::add(&mut listing.id, true, items);
        ofield::add(&mut marketplace.id, list_id, listing);

        event::emit(ListEvent {
            list_id,
            ask,
            owner,
        })
    }

    public entry fun delist<T: key + store, MKTYPE>(
        marketplace: &mut Marketplace<MKTYPE>,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let Listing {
            id,
            owner,
            ask,
        } = ofield::remove(&mut marketplace.id, item_id);

        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        let Items {
            id: uid,
            items,
        } = ofield::remove(&mut id, true);
        object::delete(id);
        object::delete(uid);

        let item_length = vector::length(&mut items);
        while (item_length > 0) {
            let item: T = vector::pop_back(&mut items);
            transfer::transfer(item, owner);
            item_length = item_length - 1;
        };
        vector::destroy_empty(items);

        emit(DeListEvent {
            list_id: item_id,
            ask,
            owner,
        })
    }

    public fun buy<T: key + store, MKTYPE>(
        marketplace: &mut Marketplace<MKTYPE>,
        item_id: ID,
        paid: Coin<MKTYPE>
    ): Items<T> {
        let Listing {
            id,
            ask,
            owner
        } = ofield::remove(&mut marketplace.id, item_id);

        transfer::transfer(paid, owner);

        emit(BuyEvent {
            list_id: item_id,
            ask,
            owner,
        });

        let items = ofield::remove(&mut id, true);
        object::delete(id);

        items
    }

    public entry fun buy_and_take<T: key + store, COIN>(
        marketplace: &mut Marketplace<COIN>,
        item_id: ID,
        paid: Coin<COIN>,
        ctx: &mut TxContext
    ) {
        transfer::transfer(
            buy<T, COIN>(marketplace, item_id, paid),
            tx_context::sender(ctx)
        );
    }

    public entry fun accept_offer<T: key+store, COIN>(
        marketplace: &mut Marketplace<COIN>,
        list_id: ID,
        offer_id: ID,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);

        let Listing {
            id: list_uid,
            owner,
            ask: _,
        } = ofield::remove(&mut marketplace.id, list_id);
        assert!(sender == owner, ENotOwner);


        //for buyer
        let Offers {
            id: offer_uid,
            item_id: _,
            expire_time: _,
            owner: buyer,
        } = ofield::remove(&mut marketplace.offer_id, offer_id);

        let Items<T> {
            id: item_id,
            items,
        } = ofield::remove(&mut offer_uid, true);
        object::delete(item_id);
        object::delete(offer_uid);

        let item_length = vector::length(&mut items);
        while (item_length > 0) {
            let item: T = vector::pop_back(&mut items);
            transfer::transfer(item, owner);
            item_length = item_length - 1;
        };
        vector::destroy_empty(items);


        // for seller
        let Items<T> {
            id: items_id,
            items,
        } = ofield::remove(&mut list_uid, true);
        object::delete(list_uid);
        object::delete(items_id);

        let item_length = vector::length(&mut items);
        while (item_length > 0) {
            let item: T = vector::pop_back(&mut items);
            transfer::transfer(item, buyer);
            item_length = item_length - 1;
        };
        vector::destroy_empty(items)
    }

    public entry fun make_offer<T: key + store, NKTYPE>(
        marketplace: &mut Marketplace<NKTYPE>,
        item_id: ID,
        paids: vector<T>,
        expire_time: u64,
        ctx: &mut TxContext)
    {
        let items = Items<T> {
            id: object::new(ctx),
            items: paids,
        };
        let owner = tx_context::sender(ctx);

        let id = object::id(&items);
        let offer = Offers {
            id: object::new(ctx),
            item_id,
            expire_time,
            owner
        };

        ofield::add(&mut offer.id, true, items);
        ofield::add(&mut marketplace.offer_id, id, offer);

        emit(OfferEvent { offer_id: id, expire_time, owner })
    }

    public entry fun cancel_offer<T: key + store, MKTYPE>(
        marketplace: &mut Marketplace<MKTYPE>,
        offer_id: ID,
        ctx: &mut TxContext
    ) {
        let Offers {
            id,
            item_id: _,
            expire_time: _,
            owner,
        } = ofield::remove(&mut marketplace.offer_id, offer_id);
        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        let Items<T> {
            id: items_id,
            items,
        } = ofield::remove(&mut id, true);

        let item_length = vector::length(&mut items);

        while (item_length > 0) {
            let item: T = vector::pop_back(&mut items);
            transfer::transfer(item, owner);
            item_length = item_length - 1;
        };

        object::delete(id);
        object::delete(items_id);
        vector::destroy_empty(items);
    }
}