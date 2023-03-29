module bob::BobYard {
    use bob::Admin;
    use bob::events::{EmitCreateMarketEvent, EmitListEvent, EmitDeListEvent, EmitBuyEvent, EmitAcceptOfferEvent, EmitOfferEvent, EmitCancelOfferEvent};
    use sui::clock;
    use sui::coin::{Coin, Self};
    use sui::dynamic_object_field as ofield;
    use sui::object::{Self, ID, UID};
    use sui::transfer::{Self, public_transfer};
    use sui::tx_context::{Self, TxContext};
    use std::vector;

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;
    const EBuyerCanBeSeller: u64 = 3;
    const EAskAmountAndItemBothZero: u64 = 4;
    const EExpired: u64 = 5;

    struct Makret<phantom T> has key {
        id: UID,
        offer_id: UID,
        fee: u64,
        fee_point: u64,
    }

    struct Listing has key, store {
        id: UID,
        item_length:u64,
        ask_coin: u64,
        ask_item: u64,
        expiration: u64,
        owner: address,
    }

    struct Offers has key, store {
        id: UID,
        list_id: ID,
        expire_time: u64,
        owner: address,
    }

    public entry fun create<T>(manage: &mut Admin::Manage, ctx: &mut TxContext) {
        assert!(Admin::is_admin(manage, ctx), ENotOwner);
        let id = object::new(ctx);
        let offer_id = object::new(ctx);
        EmitCreateMarketEvent(&id, &offer_id);
        transfer::share_object(Makret<T> { id, offer_id, fee: 15, fee_point: 10000 })
    }

    public entry fun list<T, SELL: key + store, WANT: key+store>(
        marketplace: &mut Makret<T>,
        items: vector<SELL>,
        ask_coin: u64,
        ask_item: u64,
        expiration: u64,
        time: &clock::Clock,
        ctx: &mut TxContext
    ) {
        assert!(ask_coin == 0 && ask_item == 0, EAskAmountAndItemBothZero);
        assert!(clock::timestamp_ms(time) < expiration, EExpired);

        let owner = tx_context::sender(ctx);
        let listing = Listing {
            id: object::new(ctx),
            ask_coin,
            ask_item,
            expiration,
            owner,
            item_length:0,
        };

        //todo let event object_ids = [];
        let list_id = object::id(&listing);
        let item_length = 0;
        let put_len = vector::length(&items);
        while (item_length < put_len) {
            ofield::add(&mut listing.id, item_length, vector::pop_back(&mut items));
            //TODO add item object id. let frentend can see it
            item_length = item_length +1;
        };
        vector::destroy_empty(items);

        listing.item_length = item_length;
        ofield::add(&mut marketplace.id, list_id, listing);

        EmitListEvent<SELL, T>(list_id, ask_coin, owner)
    }

    //TODO put more intm in the listing


    public entry fun delist<T: key + store, MKTYPE>(
        marketplace: &mut Makret<MKTYPE>,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let Listing {
            id,
            item_length,
            ask_coin,
            ask_item,
            expiration,
            owner,
        } = ofield::remove(&mut marketplace.id, item_id);

        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        let length = 0;
        while (length < item_length) {
            let item:T = ofield::remove(&mut id, length);
            public_transfer(item, owner);

            length = length +1;
        };


        object::delete(id);
        EmitDeListEvent<T, MKTYPE>(item_id, ask_coin, owner)
    }
    //
    // fun buy<T: key + store, MKTYPE>(
    //     marketplace: &mut Makret<MKTYPE>,
    //     item_id: ID,
    //     paid: Coin<MKTYPE>,
    //     ctx: &mut TxContext
    // ): (T, Coin<MKTYPE>) {
    //     let Listing {
    //         id,
    //         ask,
    //         owner
    //     } = ofield::remove(&mut marketplace.id, item_id);
    //     assert!(ask < coin::value(&paid), EAmountIncorrect);
    //     let buyer = tx_context::sender(ctx);
    //     assert!(buyer != owner, EBuyerCanBeSeller);
    //
    //     EmitBuyEvent<T, MKTYPE>(item_id, ask, owner, buyer);
    //
    //     let item: T = ofield::remove(&mut id, true);
    //     object::delete(id);
    //
    //     if (ask == coin::value(&paid)) {
    //         public_transfer(paid, owner);
    //         return (item, coin::zero<MKTYPE>(ctx))
    //     } else {
    //         let take = coin::split(&mut paid, ask, ctx);
    //         public_transfer(take, owner);
    //         return (item, paid)
    //     }
    // }
    //
    // public entry fun buy_one<T: key + store, COIN>(
    //     marketplace: &mut Makret<COIN>,
    //     item_id: ID,
    //     paid: vector<Coin<COIN>>,
    //     ctx: &mut TxContext
    // ) {
    //     use sui::pay::join_vec;
    //     use sui::coin::zero;
    //     let sender = tx_context::sender(ctx);
    //
    //     let to_mark_paid = zero<COIN>(ctx);
    //     join_vec(&mut to_mark_paid, paid);
    //
    //     let (item, c) = buy<T, COIN>(marketplace, item_id, to_mark_paid, ctx);
    //
    //     public_transfer(
    //         item,
    //         sender
    //     );
    //
    //     public_transfer(
    //         c,
    //         sender,
    //     );
    // }
    //
    // public entry fun accept_offer<BuyItem: key+store, SellItem: key+store, COIN>(
    //     marketplace: &mut Makret<COIN>,
    //     list_id: ID,
    //     offer_id: ID,
    //     ctx: &mut TxContext
    // ) {
    //     let sender = tx_context::sender(ctx);
    //
    //     let Listing {
    //         id: list_uid,
    //         owner,
    //         ask,
    //     } = ofield::remove(&mut marketplace.id, list_id);
    //
    //     assert!(sender == owner, ENotOwner);
    //
    //     //for buyer
    //     let Offers {
    //         id: offer_uid,
    //         list_id,
    //         expire_time: _,
    //         owner: buyer,
    //     } = ofield::remove(&mut marketplace.offer_id, offer_id);
    //
    //     let paid: SellItem = ofield::remove(&mut offer_uid, true);
    //     object::delete(offer_uid);
    //     public_transfer(paid, owner);
    //
    //     // for seller
    //     let list_item: BuyItem = ofield::remove(&mut list_uid, true);
    //     object::delete(list_uid);
    //     public_transfer(list_item, buyer);
    //
    //     //emit event
    //     EmitAcceptOfferEvent<BuyItem, SellItem, COIN>(offer_id, list_id, owner, buyer, ask)
    // }
    //
    //
    // public entry fun make_offer<T: key + store, MKTYPE>(
    //     marketplace: &mut Makret<MKTYPE>,
    //     list_id: ID,
    //     paid: T,
    //     expire_time: u64,
    //     ctx: &mut TxContext)
    // {
    //     let owner = tx_context::sender(ctx);
    //
    //     let id = object::id(&paid);
    //     let offer = Offers {
    //         id: object::new(ctx),
    //         list_id,
    //         expire_time,
    //         owner
    //     };
    //
    //     ofield::add(&mut offer.id, true, paid);
    //     ofield::add(&mut marketplace.offer_id, id, offer);
    //
    //     EmitOfferEvent<T, MKTYPE>(id, list_id, 0, expire_time, owner)
    // }
    //
    // public entry fun cancel_offer<T: key + store, MKTYPE>(
    //     marketplace: &mut Makret<MKTYPE>,
    //     offer_id: ID,
    //     ctx: &mut TxContext
    // ) {
    //     let Offers {
    //         id,
    //         list_id,
    //         expire_time: _,
    //         owner,
    //     } = ofield::remove(&mut marketplace.offer_id, offer_id);
    //     assert!(tx_context::sender(ctx) == owner, ENotOwner);
    //
    //     let item: T = ofield::remove(&mut id, true);
    //     public_transfer(item, owner);
    //     object::delete(id);
    //     //emit event
    //     EmitCancelOfferEvent<T, MKTYPE>(offer_id, list_id, owner)
    // }
}