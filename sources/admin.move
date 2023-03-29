module bob::Admin {
    use sui::tx_context::TxContext;
    use sui::object::UID;
    use sui::vec_set::VecSet;
    use sui::object;
    use sui::tx_context;
    use sui::vec_set;
    use sui::transfer::share_object;

    friend bob::BobYard;

    const E_NOT_MANAGE_OR_ADMIN:u64 = 0;

    struct Manage has key {
        id:UID,
        supper:address,
        admin:VecSet<address>,
    }

    fun init(ctx:&mut TxContext) {
        let manage = Manage {
            id:object::new(ctx),
            supper:tx_context::sender(ctx),
            admin:vec_set::empty(),
        };
        share_object(manage);
    }

    public entry fun add(manage:&mut Manage,new_admin:address, ctx:&mut TxContext) {
        assert!(is_admin(manage,ctx),E_NOT_MANAGE_OR_ADMIN);
        if (!vec_set::contains(&manage.admin,&new_admin)) {
            vec_set::insert(&mut manage.admin,new_admin);
        }
    }

    public entry fun remove(manage:&mut Manage,remove:address, ctx:&mut TxContext) {
        assert!(is_admin(manage,ctx),E_NOT_MANAGE_OR_ADMIN);
        if (!vec_set::contains(&manage.admin,&remove)) {
            vec_set::remove(&mut manage.admin,&remove);
        }
    }

    public(friend) fun is_admin(manage:&mut Manage,ctx:&mut TxContext): bool{
        let sender = tx_context::sender(ctx);
        if (sender == manage.supper) {
            true
        } else if (vec_set::contains(&manage.admin,&sender)) {
            true
        } else {
            false
        }
    }
}