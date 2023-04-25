module bob::admin {
    use sui::object::{Self, UID};
    use sui::transfer::share_object;
    use sui::tx_context::{Self, TxContext};
    use sui::vec_set::{Self, VecSet};

    const E_NOT_MANAGE_OR_ADMIN: u64 = 0;

    struct Manage has key {
        id: UID,
        supper: address,
        admin: VecSet<address>,
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext): Manage {
        let manage = Manage {
            id: object::new(ctx),
            supper: tx_context::sender(ctx),
            admin: vec_set::empty(),
        };
        manage
    }

    #[test_only]
    public fun test_delete(manage: Manage) {
        let Manage {
            id,
            supper: _,
            admin: _,
        } = manage;

        object::delete(id);
    }

    fun init(ctx: &mut TxContext) {
        let manage = Manage {
            id: object::new(ctx),
            supper: tx_context::sender(ctx),
            admin: vec_set::empty(),
        };
        share_object(manage);
    }

    public entry fun add(manage: &mut Manage, new_admin: address, ctx: &mut TxContext) {
        assert!(is_admin(manage, ctx), E_NOT_MANAGE_OR_ADMIN);
        if (!vec_set::contains(&manage.admin, &new_admin)) {
            vec_set::insert(&mut manage.admin, new_admin);
        }
    }

    public entry fun remove(manage: &mut Manage, remove: address, ctx: &mut TxContext) {
        assert!(is_admin(manage, ctx), E_NOT_MANAGE_OR_ADMIN);
        if (!vec_set::contains(&manage.admin, &remove)) {
            vec_set::remove(&mut manage.admin, &remove);
        }
    }

    public fun is_admin(manage: &Manage, ctx: &mut TxContext): bool {
        let sender = tx_context::sender(ctx);
        if (sender == manage.supper) {
            true
        } else if (vec_set::contains(&manage.admin, &sender)) {
            true
        } else {
            false
        }
    }
}
