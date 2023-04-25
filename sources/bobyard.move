module bob::bobYard {
    //use bob::events::{EmitCreateMarketEvent, EmitListEvent, EmitDeListEvent, EmitBuyEvent, EmitAcceptOfferEvent, EmitOfferEvent, EmitCancelOfferEvent};
    use sui::coin::{Coin, Self};
    use sui::dynamic_object_field as dyn;
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use bob::admin::{Manage, is_admin};
    use sui::transfer::public_transfer;

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;
    const EBuyerCanBeSeller: u64 = 3;

    struct BobYardMakret<phantom T> has key {
        id: UID,
        offer_id: UID,
        owner: address
    }

    struct Listing has key, store {
        id: UID,
        ask: u64,
        owner: address,
    }

    struct Offer has key, store {
        id: UID,
        list_id: ID,
        expire_time: u64,
        owner: address,
    }

    public entry fun create<T>(manage: &Manage, ctx: &mut TxContext) {
        assert!(is_admin(manage,ctx), ENotOwner);
        let id = object::new(ctx);
        let offer_id = object::new(ctx);
        //EmitCreateMarketEvent(&id, &offer_id);
        transfer::share_object(BobYardMakret<T> { id, offer_id,owner:tx_context::sender(ctx)})
    }

    public entry fun list<T,ITEM: key + store>(
        marketplace: &mut BobYardMakret<T>,
        item: ITEM,
        ask: u64,
        ctx: &mut TxContext
    ) {
        //let list_id = object::id(&mut item);
        let owner = tx_context::sender(ctx);

        let listing = Listing {
            id: object::new(ctx),
            ask,
            owner,
        };

        let list_id = object::id(&listing);

        dyn::add(&mut listing.id, true, item);
        dyn::add(&mut marketplace.id,list_id , listing);
        //EmitListEvent(list_id, ask, owner)
    }

    public entry fun delist<T,ITEM: key + store>(
        marketplace: &mut BobYardMakret<T>,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let Listing {
            id,
            owner,
            ask:_,
        } = dyn::remove(&mut marketplace.id, item_id);
        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        let item: ITEM = dyn::remove(&mut id, true);
        public_transfer(item, owner);
        object::delete(id);
    }

    public entry fun buy_one<T,ITEM: key + store>(
        marketplace: &mut BobYardMakret<T>,
        item_id: ID,
        paid: Coin<T>,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let (item, c) = buy<T, ITEM>(marketplace, item_id, paid, ctx);

        public_transfer(
            item,
            sender
        );

        public_transfer(
            c,
            sender,
        );
    }

    public entry fun accept_offer<T,BuyItem: key+store, SellItem: key+store>(
        marketplace: &mut BobYardMakret<T>,
        list_id: ID,
        offer_id: ID,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);

        let Listing {
            id: list_uid,
            owner,
            ask,
        } = dyn::remove(&mut marketplace.id, list_id);

        assert!(sender == owner, ENotOwner);

        //for buyer
        let Offer {
            id: offer_uid,
            list_id,
            expire_time: _,
            owner: buyer,
        } = dyn::remove(&mut marketplace.offer_id, offer_id);

        let paid: SellItem = dyn::remove(&mut offer_uid, true);
        object::delete(offer_uid);
        public_transfer(paid, owner);

        // for seller
        let list_item: BuyItem = dyn::remove(&mut list_uid, true);
        object::delete(list_uid);
        public_transfer(list_item, buyer);

        // emit event
        // EmitAcceptOfferEvent<BuyItem, SellItem, COIN>(offer_id, list_id, owner, buyer, ask)
    }

    public entry fun make_offer<T,ITEM: key + store>(
        marketplace: &mut BobYardMakret<T>,
        list_id: ID,
        paid: ITEM,
        expire_time: u64,
        ctx: &mut TxContext)
    {
        let owner = tx_context::sender(ctx);

        let id = object::id(&paid);
        let offer = Offer {
            id: object::new(ctx),
            list_id,
            expire_time,
            owner
        };

        dyn::add(&mut offer.id, true, paid);
        dyn::add(&mut marketplace.offer_id, id, offer);

        //EmitOfferEvent<T, MKTYPE>(id, list_id, 0, expire_time, owner)
    }

    public entry fun cancel_offer<T,ITEM: key + store>(
        marketplace: &mut BobYardMakret<T>,
        offer_id: ID,
        ctx: &mut TxContext
    ) {
        let Offer {
            id,
            list_id,
            expire_time: _,
            owner,
        } = dyn::remove(&mut marketplace.offer_id, offer_id);
        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        let item: ITEM = dyn::remove(&mut id, true);
        public_transfer(item, owner);

        object::delete(id);

        // emit event
        // EmitCancelOfferEvent<T, MKTYPE>(offer_id, list_id, owner)
    }

    fun buy<T,ITEM: key + store>(
        marketplace: &mut BobYardMakret<T>,
        item_id: ID,
        paid: Coin<T>,
        ctx: &mut TxContext
    ): (ITEM, Coin<T>) {
        let Listing {
            id,
            ask,
            owner
        } = dyn::remove(&mut marketplace.id, item_id);
        assert!(ask < coin::value(&paid), EAmountIncorrect);
        let buyer = tx_context::sender(ctx);
        assert!(buyer != owner, EBuyerCanBeSeller);

        let item: ITEM = dyn::remove(&mut id, true);
        object::delete(id);

        if (ask == coin::value(&paid)) {
            public_transfer(paid, owner);
            return (item, coin::zero<T>(ctx))
        } else {
            let take = coin::split(&mut paid, ask, ctx);
            public_transfer(take, owner);
            return (item, paid)
        }
    }
}