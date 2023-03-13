module bob::events {
    use std::type_name;

    use sui::event::emit;
    use sui::object::{Self, ID, UID};

    friend bob::BobYard;


    struct MarketCreateEvent has copy, drop {
        id: ID,
        offer_id: ID,
    }

    struct ListEvent has copy, drop {
        list_id: ID,
        list_type: type_name::TypeName,
        coin_type: type_name::TypeName,
        ask: u64,
        owner: address,
    }

    struct DeListEvent has copy, drop {
        list_id: ID,
        list_type: type_name::TypeName,
        coin_type: type_name::TypeName,
        ask: u64,
        owner: address,
    }

    struct BuyEvent has copy, drop {
        list_id: ID,
        ask: u64,
        list_type: type_name::TypeName,
        coin_type: type_name::TypeName,
        owner: address,
        buyer: address,
    }

    struct AcceptOfferEvent has copy, drop {
        offer_id: ID,
        list_id: ID,
        list_type: type_name::TypeName,
        coin_type: type_name::TypeName,
        offer_type: type_name::TypeName,
        offer_amount: u64,
        owner: address,
        buyer: address,
    }

    struct OfferEvent has copy, drop {
        offer_id: ID,
        list_id: ID,
        offer_type: type_name::TypeName,
        coin_type: type_name::TypeName,
        offer_amount: u64,
        expire_time: u64,
        owner: address,
    }

    struct CancelOfferEvent has copy, drop {
        offer_id: ID,
        list_id: ID,
        offer_type: type_name::TypeName,
        coin_type: type_name::TypeName,
        owner: address,
    }

    public(friend) fun EmitCreateMarketEvent(id: &UID, offer_id: &UID) {
        emit(MarketCreateEvent {
            id: object::uid_to_inner(id),
            offer_id: object::uid_to_inner(offer_id),
        });
    }


    public(friend) fun EmitListEvent<T: key + store, MKTYPE>(list_id: ID, ask: u64, owner: address) {
        emit(ListEvent {
            list_id,
            list_type: type_name::get<T>(),
            coin_type: type_name::get<MKTYPE>(),
            ask,
            owner,
        })
    }

    public(friend) fun EmitDeListEvent<T: key + store, MKTYPE>(list_id: ID, ask: u64, owner: address) {
        emit(DeListEvent {
            list_id,
            list_type: type_name::get<T>(),
            coin_type: type_name::get<MKTYPE>(),
            ask,
            owner,
        })
    }

    public(friend) fun EmitBuyEvent<T: key + store, MKTYPE>(list_id: ID, ask: u64, owner: address, buyer: address) {
        emit(BuyEvent {
            list_id,
            list_type: type_name::get<T>(),
            coin_type: type_name::get<MKTYPE>(),
            ask,
            owner,
            buyer,
        });
    }

    public(friend) fun EmitAcceptOfferEvent<BuyItem: key+store, SellItem: key+store, MKTYPE>(
        offer_id: ID,
        list_id: ID,
        owner: address,
        buyer: address,
        offer_amount: u64
    ) {
        emit(AcceptOfferEvent {
            offer_id,
            list_id,
            list_type: type_name::get<BuyItem>(),
            coin_type: type_name::get<MKTYPE>(),
            offer_type: type_name::get<SellItem>(),
            offer_amount: 0,
            owner,
            buyer,
        });
    }

    public(friend) fun EmitOfferEvent<T: key + store, MKTYPE>(
        offer_id: ID,
        list_id: ID,
        offer_amount: u64,
        expire_time: u64,
        owner: address
    ) {
        emit(OfferEvent {
            offer_id,
            list_id,
            offer_type: type_name::get<T>(),
            coin_type: type_name::get<MKTYPE>(),
            offer_amount,
            expire_time,
            owner
        })
    }

    public(friend) fun EmitCancelOfferEvent<T: key + store, MKTYPE>(offer_id: ID, list_id: ID, owner: address) {
        emit(CancelOfferEvent {
            offer_id,
            list_id,
            offer_type: type_name::get<T>(),
            coin_type: type_name::get<MKTYPE>(),
            owner,
        });
    }
}