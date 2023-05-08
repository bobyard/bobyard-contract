#[test_only]
module bob::bobyard_tests {
    use sui::object::UID;

    const EAmountIncorrect: u64 = 0;
    const ENotOwner: u64 = 1;
    const EEmptyObjects: u64 = 2;
    const EBuyerCanBeSeller: u64 = 3;
    const EExpired: u64 = 4;
    const ENotLastVersion: u64 = 5;

    #[test_only]
    struct Item has key, store {
        id: UID,
    }

    #[test]
    fun test_list() {
        // TODO
    }
}
