module ino::url_ {
    use std::vector;
    use ino::owner::{check_owner};
    use sui::tx_context::{TxContext};

    const ERROR_NOT_OWNER: u64 = 2;

    const URLS: vector<vector<u8>> = vector<vector<u8>>[
        b"https://png.pngitem.com/pimgs/s/149-1499086_transparent-flying-cat-png-flying-cat-no-background.png",
        b"https://png.pngitem.com/pimgs/s/49-497525_annoyed-peter-peter-family-guy-transparent-hd-png.png",
    ];

    public fun get_url(): vector<vector<u8>>{
        URLS
    }

    public fun get_url_list(): vector<vector<u8>>{
        let url: vector<vector<u8>> = vector::empty();
        vector::append(&mut url, get_url());
        url
    }

    public entry fun add_url (
        urll: vector<vector<u8>>,
        url: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(check_owner(ctx), ERROR_NOT_OWNER);
        vector::push_back(&mut urll, url)
    }
}
    