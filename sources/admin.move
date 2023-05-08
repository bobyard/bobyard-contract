module bob::manage {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use bob::core::Market;
    use bob::core;

    const E_NOT_MANAGE_OR_ADMIN: u64 = 0;

    struct Cap has key {
        id: UID,
    }

    fun init(ctx: &mut TxContext) {
        let manage = Cap {
            id: object::new(ctx),
        };

        transfer::transfer(manage, tx_context::sender(ctx));
    }

    public entry fun change_market_fee<T>(market:&mut Market<T>,_cap:&Cap,fee:u64) {
        core::change_market_fee(market, fee);
    }

    public entry fun take_fee<T>(market:&mut Market<T>,_cap:&Cap,ctx:&mut TxContext){
        core::take_market_fee_coin(market, ctx);
    }
}
