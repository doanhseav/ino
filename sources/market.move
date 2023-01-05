module ino::market {
    use sui::dynamic_object_field as ofield;
    use sui::dynamic_field as field;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, ID, UID};
    use sui::coin::{Self, Coin};
    use sui::transfer;
    use sui::pay;
    use std::vector;

    use ino::owner::{get_owner, check_owner};

    const ERROR_NOT_OWNER: u64 = 2;
    const ERROR_NOT_ENOUGH_AMOUNT: u64 = 3;
    const ERROR_ACCOUNT_BOUGHT: u64 = 4;

    struct Marketplace has key {
        id: UID,
    }

    struct Listing has key, store {
        id: UID,
        ask: u64,
        owner: address,
    }

    /// Create a new shared Marketplace.
    fun init(ctx: &mut TxContext) {
        let id = object::new(ctx);
        transfer::share_object(Marketplace { id })
    }

    /// List an item at the Marketplace.
    // only owner can call this
    public entry fun list<T: key + store>(
        marketplace: &mut Marketplace,
        item: T,
        ask: u64,
        ctx: &mut TxContext
    ) {
        //check owner
        assert!(check_owner(ctx),ERROR_NOT_OWNER);

        let item_id = object::id(&item);
        let listing = Listing {
            ask,
            id: object::new(ctx),
            owner: get_owner(),
        };

        ofield::add(&mut listing.id, true, item);
        ofield::add(&mut marketplace.id, item_id, listing)
    }

    /// Remove listing and get an item back. Only owner can do that.
    public fun delist<T: key + store>(
        marketplace: &mut Marketplace,
        item_id: ID,
        ctx: &mut TxContext
    ): T {
        let Listing {
            id,
            owner,
            ask: _,
        } = ofield::remove(&mut marketplace.id, item_id);

        assert!(tx_context::sender(ctx) == owner, ERROR_NOT_OWNER);

        let item = ofield::remove(&mut id, true);
        object::delete(id);
        item
    }

    /// Call [`delist`] and transfer item to the sender.
    public entry fun delist_and_take<T: key + store>(
        marketplace: &mut Marketplace,
        item_id: ID,
        ctx: &mut TxContext
    ) {
        let item = delist<T>(marketplace, item_id, ctx);
        transfer::transfer(item, tx_context::sender(ctx));
    }

    /// buy with 1 coin object
    public fun buy<T: key + store, COIN>(
        marketplace: &mut Marketplace,
        item_id: ID,
        paid: &mut Coin<COIN>,
        ctx: &mut TxContext,
    ): T {
        let Listing {
            id,
            ask,
            owner: receiver
        } = ofield::remove(&mut marketplace.id, item_id);
        
        assert!(coin::value(paid) >= ask, ERROR_NOT_ENOUGH_AMOUNT);
        pay::split_and_transfer<COIN>(
            paid,
            ask,
            receiver,
            ctx,
        );

        let item = ofield::remove(&mut id, true);
        object::delete(id);
        item
    }

    /// buy with several coins
    public fun buy2<T: key + store, COIN> (
        marketplace: &mut Marketplace,
        item_id: ID,
        paid: vector<Coin<COIN>>,
        ctx: &mut TxContext,
    ): T {
        let coin = vector::pop_back(&mut paid);
        pay::join_vec(&mut coin, paid);

        let Listing {
            id,
            ask,
            owner: receiver
        } = ofield::remove(&mut marketplace.id, item_id);

        assert!(coin::value(&coin) >= ask, ERROR_NOT_ENOUGH_AMOUNT);

        pay::split_and_transfer<COIN>(
            &mut coin,
            ask,
            receiver,
            ctx,
        );
        // transfer remain to sender 
        transfer::transfer(coin, tx_context::sender(ctx));

        let item = ofield::remove(&mut id, true);
        object::delete(id);
        item

    }

    /// every account can only buy 1 nft
    public entry fun buy_and_take_1<T: key + store, COIN>(
        marketplace: &mut Marketplace,
        item_id: ID,
        paid: vector<Coin<COIN>>,
        ctx: &mut TxContext
    ) {
        //check acc
        assert!(field::exists_<address>(& marketplace.id, tx_context::sender(ctx)), ERROR_ACCOUNT_BOUGHT);
        
        let item = buy2<T, COIN>(marketplace, item_id, paid, ctx);
        transfer::transfer(item, tx_context::sender(ctx));

        //save 
        field::add(&mut marketplace.id, tx_context::sender(ctx), 1u64)
    }

    /// each account can buy a certain amount of nft, 2 as an example
    public entry fun buy_and_take_n<T: key + store, COIN>(
        marketplace: &mut Marketplace,
        item_id: ID,
        paid: vector<Coin<COIN>>,
        ctx: &mut TxContext
    ) {
        let item = buy2<T, COIN>(marketplace, item_id, paid, ctx);
        //check acc
        if (field::exists_<address>(& marketplace.id, tx_context::sender(ctx))) {
            let num_nft = field::borrow_mut<address, u64>(&mut marketplace.id, tx_context::sender(ctx));
            assert!(*num_nft < 2, ERROR_ACCOUNT_BOUGHT);
            *num_nft = *num_nft + 1;
        } else {
            field::add(&mut marketplace.id, tx_context::sender(ctx), 1u64)
        };
        
        transfer::transfer(item, tx_context::sender(ctx));

    }
}

