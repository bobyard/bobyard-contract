module bob::Offer {
    use sui::object::{UID, ID};
    use sui::coin::Coin;
    use sui::dynamic_object_field as dyn;
    use bob::BobYard::Market;
    use sui::tx_context::TxContext;
    use sui::tx_context;
    use sui::object;
    use bob::Utils::handle_coin_vector;
    use sui::clock::Clock;
    use bob::BobYard;
    use sui::transfer;

    const ENotOwner: u64 = 1;
    const ENotEmptyOffer:u64 = 2;
    const ENotRightFunCall:u64=3;

    struct Offer<phantom T> has key,store{
        id:UID,
        list_id:ID,
        offer:Coin<T>,
        item_length:u64,
        expire_time:u64,
        owner:address,
    }

    public entry fun make_offer<T>(market:&mut Market<T>, list_id:ID, offer_coins:vector<Coin<T>>, offer_value:u64, expire_time:u64, time:&Clock, ctx:&mut TxContext){
        let sender = tx_context::sender(ctx);
        let paid = handle_coin_vector<T>(offer_coins,offer_value,ctx);

        let offer = Offer<T>{
            id: object::new(ctx),
            list_id,
            offer:paid,
            item_length:0,
            expire_time,
            owner:sender,
        };

        let offer_id = object::id(&offer);
        BobYard::add_offer(market,offer_id,offer);
    }

    public entry fun make_offer_with_one_item<T,ITEM:key+store>(market:&mut Market<T>, list_id:ID, offer_coins:vector<Coin<T>>, offer_value:u64, item:ITEM, expire_time:u64, time:&Clock, ctx:&mut TxContext){
        let sender = tx_context::sender(ctx);
        let paid = handle_coin_vector<T>(offer_coins,offer_value,ctx);

        let offer = Offer<T>{
            id: object::new(ctx),
            list_id,
            offer:paid,
            item_length:1,
            expire_time,
            owner:sender,
        };

        let offer_id = object::id(&offer);
        dyn::add(&mut offer.id, 0, item);
        //offer.item_length = 1;

        BobYard::add_offer(market,offer_id,offer);
    }

    public entry fun cancel_offer<T>(market:&mut Market<T>,offer_id:ID,ctx:&mut TxContext){
        let Offer<T>{
            id,
            list_id: _,
            offer,
            item_length,
            expire_time: _,
            owner,
        } = BobYard::remove_offer(market,offer_id);
        assert!(owner == tx_context::sender(ctx), ENotOwner);
        assert!(item_length == 0,ENotEmptyOffer);
        transfer::public_transfer(offer,owner);
        object::delete(id);
    }

    public entry fun cancel_offer_with_one<T,ITEM:key + store>(market:&mut Market<T>,offer_id:ID,ctx:&mut TxContext){
        let Offer<T>{
            id,
            list_id: _,
            offer,
            item_length,
            expire_time: _,
            owner,
        } = BobYard::remove_offer(market,offer_id);
        assert!(owner == tx_context::sender(ctx), ENotOwner);
        assert!(item_length == 1,ENotRightFunCall);

        transfer::public_transfer(offer,owner);
        transfer::public_transfer(dyn::remove<u64,ITEM>(&mut id,0),owner);

        object::delete(id);
    }

    public entry fun accept_offer<T>(market:&mut Market<T>,list_id:ID,offer_id:ID,ctx:&mut TxContext) {

    }

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
