//wallet
module ino::owner {
    
    use sui::tx_context::{Self, TxContext};

    const OWNER: address = @0xa92343adf74e139287f590c8b5a1ebca65a491f4;
    
    public fun get_owner(): address{
        OWNER
    }

    public fun check_owner (ctx: &mut TxContext): bool {
        let sender_address = tx_context::sender(ctx);
        let check = (sender_address == OWNER);
        check
    }

}