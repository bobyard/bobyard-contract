module bob::BobYard {
    use bob::Events::{EmitListEvent, EmitDeListEvent};
    use bob::Admin;

    use sui::clock;
    use sui::dynamic_object_field as dyn;
    use sui::object::{Self, ID, UID};
    use sui::transfer::{Self, public_transfer};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::Coin;
    use sui::coin;
    use sui::pay;

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;
    const EBuyerCanNotBeSeller: u64 = 3;
    const EAskAmountAndItemBothZero: u64 = 4;
    const EExpired: u64 = 5;
    const ENotEmptyCanNotBeDelist:u64 = 6;
    const EOnlyOneLeft:u64 = 7;

    struct Listing<phantom WANT: key+store> has key, store {
        id: UID,
        item_length: u64,
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

    struct Makret<phantom T> has key {
        id: UID,
        offer_id: UID,
        fee: u64,
        fee_point: u64,
    }

    public entry fun create_market<T>(manage: &mut Admin::Manage, ctx: &mut TxContext) {
        assert!(Admin::is_admin(manage, ctx),ENotOwner);
        let id = object::new(ctx);
        let offer_id = object::new(ctx);
        transfer::share_object(Makret<T> { id, offer_id, fee: 15, fee_point: 10000 })
    }

    public entry fun change_market_fee<T>(manage: &mut Admin::Manage,market:&mut Makret<T>,fee:u64,ctx: &mut TxContext) {
        assert!(Admin::is_admin(manage, ctx),ENotOwner);
        market.fee = fee
    }

    public entry fun list_one<T, WANT: key+store,SELL: key + store>(
        marketplace: &mut Makret<T>,
        item: SELL,
        ask_coin: u64,
        ask_item: u64,
        expiration: u64,
        time: &clock::Clock,
        ctx: &mut TxContext
    ) {
        let list_id = first_list<T,WANT>(marketplace,ask_coin,ask_item,expiration,time,ctx);
        add_item<T,WANT,SELL>(marketplace,list_id,item);
    }

    public entry fun delist_one<T, WANT: key+store,SELL: key + store, >(
        marketplace: &mut Makret<T>,
        list_id: ID,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let list = dyn::borrow_mut<ID,Listing<WANT>>(&mut marketplace.id, list_id);
        assert!(list.owner == sender,ENotOwner);
        assert!(list.item_length == 1,EOnlyOneLeft);
        public_transfer(remove_item<T,WANT,SELL>(marketplace,list_id,0),sender);
        delist<T,WANT,SELL>(marketplace,list_id,ctx);
    }

    public entry fun delist_two<T, WANT: key+store,S0: key + store, S1: key + store, >(
        marketplace: &mut Makret<T>,
        list_id: ID,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let list = dyn::borrow_mut<ID,Listing<WANT>>(&mut marketplace.id, list_id);
        assert!(list.owner == sender,ENotOwner);
        assert!(list.item_length == 1,EOnlyOneLeft);
        public_transfer(remove_item<T,WANT,S0>(marketplace,list_id,0),sender);
        public_transfer(remove_item<T,WANT,S1>(marketplace,list_id,1),sender);
        delist<T,WANT,S0>(marketplace,list_id,ctx);
    }

    public entry fun remove_item_with_idx<T, WANT: key+store,SELL: key + store>(
        marketplace: &mut Makret<T>,
        list_id: ID,
        index:u64,
        ctx: &mut TxContext
    ) {
        let sender =tx_context::sender(ctx);
        let list = dyn::borrow_mut<ID,Listing<WANT>>(&mut marketplace.id, list_id);
        assert!(list.owner == sender,ENotOwner);
        assert!(list.item_length == 1,EOnlyOneLeft);
        public_transfer(remove_item<T,SELL,WANT>(marketplace,list_id,index),sender);
    }

    public entry fun swap<T, WANT: key+store, SELL: key + store>(
        marketplace: &mut Makret<T>,
        list_id: ID,
        coins:vector<Coin<T>>,
        ctx: &mut TxContext
    ) {
        let paid = coin::zero<T>(ctx);
        pay::join_vec(&mut paid,coins);
        let sender = tx_context::sender(ctx);
        let list = dyn::borrow_mut<ID,Listing<WANT>>(&mut marketplace.id, list_id);
        assert!(list.owner != sender,  EBuyerCanNotBeSeller);
        assert!(list.item_length > 0, ENotEmptyCanNotBeDelist);
        assert!(list.ask_coin <= coin::value(&paid), EAmountIncorrect);
        let income = coin::split(&mut paid, list.ask_coin,ctx);
        public_transfer(income,sender);
        public_transfer(paid,sender);

        public_transfer(remove_item<T,WANT,SELL>(marketplace,list_id,0),sender);

        delist<T,SELL,WANT>(marketplace,list_id,ctx)
    }

    public entry fun swap_with<T, WANT: key+store,SELL: key + store>(
        marketplace: &mut Makret<T>,
        list_id: ID,
        // coins:vector<Coin<T>>,
        item: WANT,
        ctx: &mut TxContext
    ) {
        // let paid = coin::zero<T>(ctx);
        // pay::join_vec(&mut paid,coins);

        let sender = tx_context::sender(ctx);
        let list = dyn::borrow_mut<ID,Listing<WANT>>(&mut marketplace.id, list_id);
        assert!(list.owner != sender,  EBuyerCanNotBeSeller);
        assert!(list.item_length == 0, ENotEmptyCanNotBeDelist);

        public_transfer(remove_item_from_list<T,WANT,SELL>(list,0),sender);
        public_transfer(item,list.owner);

        delist<T,SELL,WANT>(marketplace,list_id,ctx)
    }

    fun first_list<T, WANT: key+store>(
        marketplace: &mut Makret<T>,
        ask_coin: u64,
        ask_item: u64,
        expiration: u64,
        time: &clock::Clock,
        ctx: &mut TxContext
    ) :ID{
        assert!(ask_coin != 0 || ask_item != 0, EAskAmountAndItemBothZero);
        assert!(clock::timestamp_ms(time) >= expiration, EExpired);

        let owner = tx_context::sender(ctx);
        let listing = Listing<WANT> {
            id: object::new(ctx),
            ask_coin,
            ask_item,
            expiration,
            owner,
            item_length: 0,
        };

        let list_id = object::id(&listing);
        dyn::add(&mut marketplace.id, list_id, listing);
        list_id
    }

    fun add_item<T, WANT: key+store, SELL: key + store>(
        marketplace: &mut Makret<T>,
        list_id: ID,
        item: SELL
    ) {
        let list = dyn::borrow_mut<ID,Listing<WANT>>(&mut marketplace.id, list_id);
        let item_length = list.item_length;
        dyn::add(&mut list.id, item_length, item);
        list.item_length = list.item_length +1;
    }

    fun remove_item_from_list<T, WANT: key+store,SELL: key + store>(
        list: &mut Listing<WANT>,
        item_index: u64
    ):SELL {
        list.item_length = list.item_length -1;
        dyn::remove(&mut list.id, item_index)
    }

    fun remove_item<T, WANT: key+store,SELL: key + store>(
        marketplace: &mut Makret<T>,
        list_id: ID,
        item_index: u64
    ):SELL {
        let list = dyn::borrow_mut<ID,Listing<WANT>>(&mut marketplace.id, list_id);
        list.item_length = list.item_length -1;
        dyn::remove(&mut list.id, item_index)
    }

    fun delist<T, SELL: key + store,WANT:key+store>(
        marketplace: &mut Makret<T>,
        list_id: ID,
        ctx: &mut TxContext
    ) {
        let Listing {
            id,
            item_length,
            ask_coin,
            ask_item:_,
            expiration:_,
            owner,
        }:Listing<WANT> = dyn::remove(&mut marketplace.id, list_id);
        assert!(item_length==0,ENotEmptyCanNotBeDelist);
        object::delete(id);
        EmitDeListEvent<SELL, T>(list_id, ask_coin, owner)
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