module bob::utils {
    use std::hash;
    use std::string::{Self, String};
    use std::vector;

    use sui::bcs::{Self, peel_u64};
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    const EINVALID_LENGTH: u64 = 998;
    const EINVALID_REMAINER: u64 = 999;

    // utils
    public fun num_str(num: u64): String
    {
        let v1 = vector::empty();
        while (num / 10 > 0) {
            let rem = num % 10;
            vector::push_back(&mut v1, (rem + 48 as u8));
            num = num / 10;
        };
        vector::push_back(&mut v1, (num + 48 as u8));
        vector::reverse(&mut v1);
        string::utf8(v1)
    }

    public fun pseudo_random(add: address, remaining: u64, ctx: &mut TxContext): u64
    {
        let x = bcs::to_bytes<address>(&add);
        let y = bcs::to_bytes<u64>(&remaining);

        let uid = object::new(ctx);
        let z = bcs::to_bytes<UID>(&uid);
        object::delete(uid);

        vector::append(&mut x, y);
        vector::append(&mut x, z);
        let tmp = hash::sha2_256(x);
        let data = vector::empty<u8>();
        let i = 24;
        while (i < 32)
            {
                let x = vector::borrow(&tmp, i);
                vector::append(&mut data, vector<u8>[*x]);
                i = i + 1;
            };

        assert!(remaining > 0, 999);
        let random = peel_u64(&mut bcs::new(data)) % remaining + 1;
        if (random == 0)
            {
                random = 1;
            };
        random
    }

    public fun verify(
        proof: &vector<vector<u8>>,
        root: vector<u8>,
        leaf: vector<u8>
    ): bool {
        process_proof(proof, leaf) == root
    }

    fun process_proof(proof: &vector<vector<u8>>, leaf: vector<u8>): vector<u8> {
        let computed_hash = leaf;
        let proof_length = vector::length(proof);
        let i = 0;

        while (i < proof_length) {
            computed_hash = hash_pair(computed_hash, *vector::borrow(proof, i));
            i = i + 1;
        };

        computed_hash
    }

    fun lt(a: &vector<u8>, b: &vector<u8>): bool {
        let i = 0;
        let len = vector::length(a);
        assert!(len == vector::length(b), EINVALID_LENGTH);

        while (i < len) {
            let aa = *vector::borrow(a, i);
            let bb = *vector::borrow(b, i);
            if (aa < bb) return true;
            if (aa > bb) return false;
            i = i + 1;
        };

        false
    }


    fun hash_pair(a: vector<u8>, b: vector<u8>): vector<u8> {
        if (lt(&a, &b)) efficient_hash(a, b) else efficient_hash(b, a)
    }

    fun efficient_hash(a: vector<u8>, b: vector<u8>): vector<u8> {
        vector::append(&mut a, b);
        hash::sha2_256(a)
    }
}