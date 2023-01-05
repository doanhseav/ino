module ino::nft {
    use sui::url::{Self, Url};
    use std::string;
    use std::vector::{ borrow, length};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;

    use ino::owner::{get_owner};
    use ino::whitelist::is_white_list;
    use ino::url_;

    const ERROR_NOT_WHITELIST: u64 = 0;
    const ERROR_OUT_OF_RANGE: u64 = 1;
    const ERROR_NOT_OWNER: u64 = 2;

    struct NFT has key, store {
        id: UID,
        name: string::String,
        description: string::String,
        url: Url,
    }

    // struct URL has key {
    //     id: UID,
    //     url: vector<vector<u8>>
    // }

    // fun init(ctx: &mut TxContext) {
    //     // let a:  vector<vector<u8>> = vector::empty();
    //     let urll  = URL {
    //         id: object::new(ctx),
    //         url: url_::get_url()
    //     };

    //     transfer::share_object(urll);
    //     // let url: vector<vector<u8>> = vector::empty();
    //     // vector::append(&mut url, url_::get_url());
    // }
    
    public entry fun mint_nft (
        name: vector<u8>,
        description: vector<u8>,
        //index of url in url list
        index: u64,
        ctx: &mut TxContext,
    ) {
        let user_address = tx_context::sender(ctx);
        let url = url_::get_url_list();
        //check white list
        assert!(is_white_list(&user_address), ERROR_NOT_WHITELIST);
        //check 
        assert!(index < length(&url), ERROR_OUT_OF_RANGE);

        let nft = NFT {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(*borrow(&url, index))
        };

        transfer::transfer(nft, get_owner());
    }
        
    public entry fun batch_mint_nfts (
        name: vector<u8>,
        description: vector<u8>,
        index: u64,
        quan: u64, //number of nft minted
        ctx: &mut TxContext,
    ) {
        let url = url_::get_url_list();
        let user_address = tx_context::sender(ctx);
        //check white list
        assert!(is_white_list(&user_address), ERROR_NOT_WHITELIST);
        //check 
        assert!(index < length(&url), ERROR_OUT_OF_RANGE);

        let i = 0;
        while (i < quan) {
            let nft = NFT {
                id: object::new(ctx),
                name: string::utf8(name),
                description: string::utf8(description),
                url: url::new_unsafe_from_bytes(*borrow(&url, index))
            };
            transfer::transfer(nft, get_owner());
            i = i + 1;
        };
    }

    public entry fun burn(nft: NFT) {
        let NFT { id, name: _, description: _, url: _ } = nft;
        object::delete(id)
    }



    // public entry fun delete_url (
    //     urll: &mut URL,
    //     url: vector<u8>,
    //     ctx: &mut TxContext
    // ) {
    //     // check if the sender is owner or not
    //     assert!(check_owner(ctx), ERROR_NOT_OWNER);
    //     vector::push_back(&mut urll.url, url)
    // }
}