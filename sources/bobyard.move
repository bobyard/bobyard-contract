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
    use bob::Offer::Offer;

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;
    const EBuyerCanNotBeSeller: u64 = 3;
    const EAskAmountAndItemBothZero: u64 = 4;
    const EExpired: u64 = 5;
    const ENotEmptyCanNotBeDelist:u64 = 6;
    const EOnlyOneLeft:u64 = 7;


    friend bob::Offer;

    struct Market<phantom T> has key {
        id: UID,
        offer_id: UID,
        fee: u64,
        fee_point: u64,
    }

    struct Listing<phantom WANT: key+store> has key, store {
        id: UID,
        item_length: u64,
        ask_coin: u64,
        ask_item: u64,
        expiration: u64,
        owner: address,
    }

    public entry fun create_market<T>(manage: &mut Admin::Manage, ctx: &mut TxContext) {
        assert!(Admin::is_admin(manage, ctx),ENotOwner);
        let id = object::new(ctx);
        let offer_id = object::new(ctx);
        transfer::share_object(Market<T> { id, offer_id, fee: 15, fee_point: 10000 })
    }

    public entry fun change_market_fee<T>(manage: &mut Admin::Manage, market:&mut Market<T>, fee:u64, ctx: &mut TxContext) {
        assert!(Admin::is_admin(manage, ctx),ENotOwner);
        market.fee = fee
    }

    public entry fun list_one<T, WANT: key+store,SELL: key + store>(
        marketplace: &mut Market<T>,
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
        marketplace: &mut Market<T>,
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
        marketplace: &mut Market<T>,
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
        marketplace: &mut Market<T>,
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
        marketplace: &mut Market<T>,
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
        marketplace: &mut Market<T>,
        list_id: ID,
        item: WANT,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let list = dyn::borrow_mut<ID,Listing<WANT>>(&mut marketplace.id, list_id);
        assert!(list.owner != sender,  EBuyerCanNotBeSeller);
        assert!(list.item_length == 0, ENotEmptyCanNotBeDelist);

        public_transfer(remove_item_from_list<T,WANT,SELL>(list,0),sender);
        public_transfer(item,list.owner);

        delist<T,SELL,WANT>(marketplace,list_id,ctx)
    }

    fun first_list<T, WANT: key+store>(
        marketplace: &mut Market<T>,
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
        marketplace: &mut Market<T>,
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
        marketplace: &mut Market<T>,
        list_id: ID,
        item_index: u64
    ):SELL {
        let list = dyn::borrow_mut<ID,Listing<WANT>>(&mut marketplace.id, list_id);
        list.item_length = list.item_length -1;
        dyn::remove(&mut list.id, item_index)
    }

    fun delist<T, SELL: key + store,WANT:key+store>(
        marketplace: &mut Market<T>,
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


    public(friend) fun add_offer<T>(marketplace: &mut Market<T>, offer_id:ID, offer:Offer<T>){
        dyn::add(&mut marketplace.offer_id, offer_id, offer);
    }
    public(friend) fun remove_offer<T>(marketplace: &mut Market<T>, offer_id:ID):Offer<T>{
        dyn::remove<ID,Offer<T>>(&mut marketplace.offer_id, offer_id)
    }
}