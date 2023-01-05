// owner
module ino::whitelist{
    use std::vector;

    const WHITE_LIST: vector<address> = vector<address>[
        @0x97a50e228e7be5322656b2cf82e742c370c7fc0e,
        @0xa6b17437cbe185667712656b8b9a8e4351566d34
    ];

    public fun get_white_list(): vector<address>{
        WHITE_LIST
    }

    public fun is_white_list(element: &address): bool {
        vector::contains<address>(&WHITE_LIST,element)
    }
}