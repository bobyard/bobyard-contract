module obj::marketplace {
    use sui::dynamic_object_field as ofield;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID, UID};
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use std::vector;
    use sui::event;

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;

    struct Marketplace<phantom T> has key {
        id: UID
    }

    struct Listing has key, store {
        id: UID,
        ask: u64,
        owner: address,
    }

    struct Offers<T> has key, store {
        id: UID,
        item_id: ID,
        offer_items: vector<T>,
        owner: address,
    }

    struct ListItem<T> has key, store {
        id: UID,
        items: vector<T>,
    }

    struct Bid<T> has key, store {
        id: UID,
        list_id: ID,
        items: vector<T>,
        expire_time: u64,
    }

    struct ListEvent has copy, drop {
        list_id: ID,
        ask: u64,
        owner: address,
    }

    struct OfferEvent has copy, drop {
        offer_id: ID,
        owner: address,
    }

    public entry fun create<COIN>(ctx: &mut TxContext) {
        //assert!(tx_context::sender(ctx) == @obj, ENotOwner);
        let id = object::new(ctx);
        transfer::share_object(Marketplace<COIN> { id })
    }

    public entry fun list<T: key + store, COIN>(
        marketplace: &mut Marketplace<COIN>,
        items: vector<T>,
        ask: u64,
        ctx: &mut TxContext
    ) {
        assert!(vector::length(&mut items) == 0, EEmptyObjects);

        let items = ListItem {
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

    public entry fun delist<T: key + store, COIN>(
        marketplace: &mut Marketplace<COIN>,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let Listing {
            id,
            owner,
            ask: _,
        } = ofield::remove(&mut marketplace.id, item_id);

        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        let item: T = ofield::remove(&mut id, true);
        transfer::transfer(item, tx_context::sender(ctx));
        object::delete(id);
    }

    public fun buy<T: key + store, COIN>(
        marketplace: &mut Marketplace<COIN>,
        item_id: ID,
        paid: Coin<COIN>
    ): ListItem<T> {
        let Listing {
            id,
            ask,
            owner
        } = ofield::remove(&mut marketplace.id, item_id);

        transfer::transfer(paid, owner);

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


    //TODO make this work
    // public entry fun accept_offer<T: key+store, COIN>(
    //     marketplace: &mut Marketplace<COIN>,
    //     item_id: ID,
    //     offer_id: ID
    // ) {
    //     let Listing {
    //         id,
    //         ask,
    //         owner
    //     } = ofield::remove(&mut marketplace.id, item_id)
    // }
    //
    // public entry fun make_offer<T: key + store>(
    //     item_id: ID,
    //     paids: vector<T>,
    //     expire_time: u64,
    //     ctx: &mut TxContext)
    // {
    //     let id = object::new(ctx);
    //     let bid = Bid<T> {
    //         id,
    //         list_id: item_id,
    //         items: paids,
    //         expire_time
    //     };
    //
    //     let owner = tx_context::sender(ctx);
    //
    //     // emit(OfferEvent{
    //     //     offer_id: bid.id,
    //     //     onwer,
    //     // });
    //
    //     transfer::transfer(bid, owner);
    // }
    //
    //
    // public entry fun cancel_offer<T: key + store>(
    //     bid_id: Bid<T>,
    //     ctx: &mut TxContext
    // ) {
    //     let Bid<T> {
    //         id,
    //         list_id,
    //         items,
    //         expire_time
    //     } = bid_id;
    //     let sender = tx_context::sender(ctx);
    //
    //     if (!vector::is_empty(&mut items)) {
    //         let item = vector::pop_back(&mut items);
    //         transfer::transfer(item, sender);
    //     };
    //
    //     vector::destroy_empty(items);
    //     object::delete(id)
    // }
}