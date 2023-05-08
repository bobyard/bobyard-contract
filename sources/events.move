module bob::events {
    use sui::event::emit;
    use sui::object::ID;

    friend bob::bobYard;
    friend bob::core;


    struct ListEvent<phantom T> has copy, drop {
        list_id: ID,
        list_item_id: ID,
        expire_time: u64,
        ask: u64,
        owner: address,
    }

    struct DeListEvent<phantom T> has copy, drop {
        list_id: ID,
        list_item_id: ID,
        expire_time: u64,
        ask: u64,
        owner: address,
    }

    struct BuyEvent<phantom T> has copy, drop {
        list_id: ID,
        item_id: ID,
        ask: u64,
        owner: address,
        buyer: address,
    }

    struct AcceptOfferEvent<phantom T> has copy, drop {
        offer_id: ID,
        list_id: ID,
        item_id: ID,
        offer_amount: u64,
        owner: address,
        buyer: address,
    }

    struct OfferEvent<phantom T> has copy, drop {
        offer_id: ID,
        list_id: ID,
        offer_amount: u64,
        expire_time: u64,
        owner: address,
    }

    struct CancelOfferEvent<phantom T> has copy, drop {
        offer_id: ID,
        list_id: ID,
        owner: address,
    }


    public(friend) fun EmitListEvent<T>(list_id: ID, list_item_id: ID, ask: u64, expire_time: u64, owner: address) {
        emit(ListEvent<T> {
            list_id,
            list_item_id,
            expire_time,
            ask,
            owner,
        })
    }

    public(friend) fun EmitDeListEvent<T>(list_id: ID, list_item_id: ID, ask: u64, expire_time: u64, owner: address) {
        emit(DeListEvent<T> {
            list_id,
            list_item_id,
            expire_time,
            ask,
            owner,
        })
    }

    public(friend) fun EmitBuyEvent<T>(list_id: ID, item_id: ID, ask: u64, owner: address, buyer: address) {
        emit(BuyEvent<T> {
            list_id,
            item_id,
            ask,
            owner,
            buyer,
        });
    }

    public(friend) fun EmitAcceptOfferEvent<T>(
        offer_id: ID,
        list_id: ID,
        item_id: ID,
        owner: address,
        buyer: address,
        offer_amount: u64
    ) {
        emit(AcceptOfferEvent<T> {
            offer_id,
            list_id,
            item_id,
            offer_amount,
            owner,
            buyer,
        });
    }

    public(friend) fun EmitOfferEvent<T>(
        offer_id: ID,
        list_id: ID,
        offer_amount: u64,
        expire_time: u64,
        owner: address
    ) {
        emit(OfferEvent<T> {
            offer_id,
            list_id,
            offer_amount,
            expire_time,
            owner
        })
    }

    public(friend) fun EmitCancelOfferEvent<T>(offer_id: ID, list_id: ID, owner: address) {
        emit(CancelOfferEvent<T> {
            offer_id,
            list_id,
            owner,
        });
    }
}