module obj::marketplace {
    use sui::dynamic_object_field as ofield;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID, UID};
    use sui::coin::{Coin,Self};
    use sui::transfer;
    use sui::event;
    use sui::event::emit;


    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;
    const EBuyerCanBeSeller:u64 = 3;

    struct Admin has key {
        id: UID,
        owner: address,
    }

    struct Marketplace<phantom T> has key {
        id: UID,
        offer_id: UID,
        owner: address
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
        buyer: address,
    }

    struct AcceptOfferEvent has copy, drop {
        offer_id: ID,
        list_id: ID,
        owner: address,
        buyer: address,
    }

    struct OfferEvent has copy, drop {
        offer_id: ID,
        list_id: ID,
        expire_time: u64,
        owner: address,
    }

    struct CancelOfferEvent has copy, drop {
        offer_id: ID,
        list_id: ID,
        owner: address,
    }


    fun init(ctx: &mut TxContext) {
        transfer::share_object(Admin { id: object::new(ctx), owner: tx_context::sender(ctx) })
    }

    public entry fun create<MKTYPE>(admin: &Admin, ctx: &mut TxContext) {
        assert!(tx_context::sender(ctx) == admin.owner, ENotOwner);

        let id = object::new(ctx);
        let offer_id = object::new(ctx);

        emit(MarketCreateEvent {
            id: object::uid_to_inner(&id),
            offer_id: object::uid_to_inner(&offer_id),
        });

        transfer::share_object(Marketplace<MKTYPE> { id, offer_id, owner: tx_context::sender(ctx) })
    }

    public entry fun list<T: key + store, MKTYPE>(
        marketplace: &mut Marketplace<MKTYPE>,
        item: T,
        ask: u64,
        ctx: &mut TxContext
    ) {
        let list_id = object::id(&mut item);
        let owner = tx_context::sender(ctx);

        let listing = Listing {
            id: object::new(ctx),
            ask,
            owner,
        };

        ofield::add(&mut listing.id, true, item);
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

        let item: T = ofield::remove(&mut id, true);
        object::delete(id);
        transfer::transfer(item, owner);

        emit(DeListEvent {
            list_id: item_id,
            ask,
            owner,
        })
    }

    public fun buy<T: key + store, MKTYPE>(
        marketplace: &mut Marketplace<MKTYPE>,
        item_id: ID,
        paid: Coin<MKTYPE>,
        ctx: &mut TxContext
    ): T {
        let Listing {
            id,
            ask,
            owner
        } = ofield::remove(&mut marketplace.id, item_id);
        assert!(ask < coin::value(&paid),EAmountIncorrect);

        let buyer = tx_context::sender(ctx);
        assert!(buyer == owner,EBuyerCanBeSeller);

        if (ask == coin::value(&paid)) {
            transfer::transfer(paid, owner);
        } else {
            let take = coin::split(&mut paid,ask,ctx);
            transfer::transfer(take, owner);
            transfer::transfer(paid, buyer);
        };




        emit(BuyEvent {
            list_id: item_id,
            ask,
            owner,
            buyer,
        });

        let item = ofield::remove(&mut id, true);
        object::delete(id);
        item
    }

    public entry fun buy_and_take<T: key + store, COIN>(
        marketplace: &mut Marketplace<COIN>,
        item_id: ID,
        paid: vector<Coin<COIN>>,
        ctx: &mut TxContext
    ) {
        use sui::pay::join_vec;
        use sui::coin::zero;

        let to_mark_paid = zero<COIN>(ctx);
        //if (vector::length(&paid) > 1){
         //   let a = vector::pop_back(&mut paid);
        join_vec(&mut to_mark_paid,paid);
        //};

        transfer::transfer(
            buy<T, COIN>(marketplace, item_id, to_mark_paid, ctx),
            tx_context::sender(ctx)
        );
    }

    public entry fun accept_offer<BuyItem: key+store, SellItem: key+store, COIN>(
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
            item_id,
            expire_time: _,
            owner: buyer,
        } = ofield::remove(&mut marketplace.offer_id, offer_id);

        let paid: SellItem = ofield::remove(&mut offer_uid, true);
        object::delete(offer_uid);
        transfer::transfer(paid, owner);

        // for seller
        let list_item: BuyItem = ofield::remove(&mut list_uid, true);
        object::delete(list_uid);
        transfer::transfer(list_item, buyer);

        //emit event
        emit(AcceptOfferEvent {
            offer_id,
            list_id: item_id,
            owner,
            buyer,
        });
    }

    public entry fun make_offer<T: key + store, NKTYPE>(
        marketplace: &mut Marketplace<NKTYPE>,
        item_id: ID,
        paid: T,
        expire_time: u64,
        ctx: &mut TxContext)
    {
        let owner = tx_context::sender(ctx);

        let id = object::id(&paid);
        let offer = Offers {
            id: object::new(ctx),
            item_id,
            expire_time,
            owner
        };

        ofield::add(&mut offer.id, true, paid);
        ofield::add(&mut marketplace.offer_id, id, offer);

        emit(OfferEvent { offer_id: id, list_id: item_id, expire_time, owner })
    }

    public entry fun cancel_offer<T: key + store, MKTYPE>(
        marketplace: &mut Marketplace<MKTYPE>,
        offer_id: ID,
        ctx: &mut TxContext
    ) {
        let Offers {
            id,
            item_id,
            expire_time: _,
            owner,
        } = ofield::remove(&mut marketplace.offer_id, offer_id);
        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        let item: T = ofield::remove(&mut id, true);
        transfer::transfer(item, owner);

        //emit event
        emit(CancelOfferEvent {
            offer_id,
            list_id: item_id,
            owner,
        });

        object::delete(id)
    }
}