module bob::admin {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    const E_NOT_MANAGE_OR_ADMIN: u64 = 0;

    struct Cap has key {
        id: UID
    }

    fun init(ctx: &mut TxContext) {
        let manage = Cap {
            id: object::new(ctx)
        };

        transfer::transfer(manage, tx_context::sender(ctx));
    }
}
