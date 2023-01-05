// module launchpad::main{

//     use std::vector;

//     use sui::tx_context::{ Self, TxContext };
//     use sui::object::{ Self, UID };
//     use sui::transfer::{ transfer, share_object };
//     use sui::coin::{ Self, Coin };
//     use sui::sui::SUI;
//     //use sui::balance::{ Self };
//     use sui::pay;
//     use sui::dynamic_object_field as ofield;
    
//     use launchpad::whitelist::{ is_white_list };
//     use launchpad::token_cap:: { get_hard_cap };
//     use launchpad::time_ido:: { 
//         get_none_time,
//         get_buy_time,
//         get_claim_time,
//         get_setup_time
//     };
//     use launchpad::config:: { 
//         get_allow_amount,
//         get_receive_amount 
//     };
//     use launchpad::owner::{
//         check_owner
//     };

//     // error area
//     const ERROR_NOT_OWNER: u64 = 1;
//     const ERROR_NOT_BUY_TIME: u64 = 2;
//     const ERROR_NOT_WHITELIST: u64 = 3;
//     const ERROR_NOT_AMOUNT_ALLOWED: u64 = 4;
//     const ERROR_NOT_HARDCAP_FULL: u64 = 5;
//     const ERROR_NO_COIN: u64 = 6;
//     const ERROR_ACCOUNT_BUYED: u64 = 7;
//     const ERROR_NOT_CLAIM_TIME: u64 = 8;
//     const ERROR_NOT_BUYED_TOKEN: u64 = 9;
//     const ERROR_AMOUNT_RECEIVE_NOT_VALID: u64 = 10;
//     const ERROR_ACCOUNT_BUYED_EMPTY: u64 = 11;
//     const ERROR_NOT_CONFIG_TIME: u64 = 12;
//     const ERROR_WHITELIST_EMPTY: u64 = 13;
//     const ERROR_BALANCE_EQUAL_ZERO: u64 = 14;
//     const ERROR_TIME_UPDATED_INVALID: u64 = 15;
//     const ERROR_INSUFFER_BALANCE: u64 = 16;
//     // end error area

//     struct IdoData has key, store {
//         id: UID,
//         owner: address,
//         hard_cap: u64, // total token sale
//         time_option: u64, // time mode, default 0 , 0: nothing/upcoming, 1 : buytime, 2 : claim time, 3: end
//         account_buyed: vector<address>,
//     }

//     struct ClaimableToken<phantom T> has key,store{
//         id: UID,
//         owner: address,
//         claimable: vector<Coin<T>>
//     }

//     struct AccountToken has key,store{
//         id: UID,
//         token_amount: u64
//     }

//     struct TokenClaimable<phantom T> has key, store{
//         id: UID,
//         claimable: vector<Coin<T>>
//     }

//     /*
//     * init_funtion: comment for test
//     */
//     fun init(ctx:&mut TxContext){
//         init_ido(ctx);
//     }

//     // init data
//     //call one time in init function
//     public fun init_ido(ctx:&mut TxContext){
//         let id = object::new(ctx);
//         let owner = tx_context::sender(ctx);
        
//         //let white_list_address = get_white_list();
//         let hard_cap = 0;
//         let time_option = get_none_time();
//         let account_buyed = vector<address>[];

//         let ido_object = IdoData {
//             id,
//             owner,
//             hard_cap,
//             time_option,
//             account_buyed  
//             //white_list_address
//         };

//         //transfer(ido_object,owner);
//         share_object(ido_object);
//     }

//     /*
//     * buy function with coin is array
//     * ido_object:IdoData is object created at init. this is ido object data
//     * amount:u64 optional
//     */
//     //public entry fun buy(ido_object:&mut IdoData, coins: vector<Coin<SUI>>, ctx:&mut TxContext){
//     public entry fun buy_with_coins(ido_object:&mut IdoData,coins: vector<Coin<SUI>>,ctx:&mut TxContext){
//         assert!(vector::length(&coins) > 0,ERROR_NO_COIN);
//         // check time
//         // assert!(ido_object.time_option == get_buy_time(),ERROR_NOT_BUY_TIME);
//         let user_address = tx_context::sender(ctx);
//         // check whitelist
//         assert!(is_white_list(&user_address),ERROR_NOT_WHITELIST);
//         // check harcap
//         assert!(ido_object.hard_cap <= get_hard_cap(),ERROR_NOT_HARDCAP_FULL);

//         let ido_id = &ido_object.id;
//         // check buy one time
//         assert!(!ofield::exists_<address>(ido_id,tx_context::sender(ctx)),ERROR_ACCOUNT_BUYED);
        
//         // join and transfer coin
//         join_coins_and_transfer(
//             coins,
//             get_allow_amount(),
//             ido_object.owner,
//             ctx
//         );
//         // save to data
//        // let parent = &ido_object.id;
//        let token_amount = get_receive_amount();
//         ofield::add<address,AccountToken>(
//             &mut ido_object.id, 
//             tx_context::sender(ctx), 
//             AccountToken { 
//                 id: object::new(ctx), 
//                 token_amount 
//             }
//         );

        
//         // update hardcap
//         ido_object.hard_cap = ido_object.hard_cap + token_amount;
//         if (!vector::contains<address>(&ido_object.account_buyed,&tx_context::sender(ctx)))
//             vector::push_back<address>(&mut ido_object.account_buyed,tx_context::sender(ctx));
//         // emit event
       
//     }


//     /*
//     * buy function with coin is object
//     * ido_object:IdoData is object created at init. this is ido object data
//     * amount:u64 optional
//     */
//     //public entry fun buy(ido_object:&mut IdoData, coins: vector<Coin<SUI>>, ctx:&mut TxContext){
//     public entry fun buy_with_coin(ido_object:&mut IdoData,coins: Coin<SUI>,ctx:&mut TxContext){
//         assert!(coin::value(&coins) > 0,ERROR_NO_COIN);
//         assert!(coin::value(&coins) >= get_allow_amount(), ERROR_INSUFFER_BALANCE);
//         // check time
//         // assert!(ido_object.time_option == get_buy_time(),ERROR_NOT_BUY_TIME);
//         let user_address = tx_context::sender(ctx);
//         // check whitelist
//         assert!(is_white_list(&user_address),ERROR_NOT_WHITELIST);
//         // check harcap
//         assert!(ido_object.hard_cap <= get_hard_cap(),ERROR_NOT_HARDCAP_FULL);

//         let ido_id = &ido_object.id;
//         // check buy one time
//         assert!(!ofield::exists_<address>(ido_id,tx_context::sender(ctx)),ERROR_ACCOUNT_BUYED);
        
//         // save to data
//        // let parent = &ido_object.id;
//        let token_amount = get_receive_amount();
//         ofield::add<address,AccountToken>(
//             &mut ido_object.id, 
//             tx_context::sender(ctx), 
//             AccountToken { 
//                 id: object::new(ctx), 
//                 token_amount 
//             }
//         );

//         // join and transfer coin
//         pay::split_and_transfer<SUI>(&mut coins,get_allow_amount(),ido_object.owner,ctx);
//         // transfer remain to sender 
//         transfer(coins, tx_context::sender(ctx));
        
//         // update hardcap
//         ido_object.hard_cap = ido_object.hard_cap + token_amount;
//         if (!vector::contains<address>(&ido_object.account_buyed,&tx_context::sender(ctx)))
//             vector::push_back<address>(&mut ido_object.account_buyed,tx_context::sender(ctx));
//         // emit event
       
//     }

//     fun join_coins_and_transfer(coins: vector<Coin<SUI>>,amount: u64,recipient: address,ctx: &mut TxContext){
//         assert!(vector::length(&coins) > 0,ERROR_NO_COIN);
//         let coin = vector::pop_back(&mut coins);
//         pay::join_vec(&mut coin, coins);
//         // coin must greater than amount
//         // compare with min-max if nescesnary
//         assert!(coin::value(&coin) >= amount, ERROR_NO_COIN);
//         // split and transfer to project
//         pay::split_and_transfer<SUI>(&mut coin,amount,recipient,ctx);
//         // transfer remain to sender 
//         transfer(coin, tx_context::sender(ctx));
//     }

//     // /*
//     // * receive token from wallet before claim
//     // */
//     // public entry fun receive_token_coins<T>(coins:vector<Coin<T>>,receive:address,ido_object:&mut IdoData){
//     //     assert!(vector::length(&coins) > 0,ERROR_NO_COIN);
//     //     let coin = vector::pop_back(&mut coins);
//     //     pay::join_vec(&mut coin, coins);
//     //     ofield::add<address,Coin<T>>(&mut ido_object.id,receive,coin);
       
//     //    // transfer(coin,recipient);
//     // }

//     /*
//     * funtion receive coin
//     * split coin by list whitelist
//     * call after buy time (setup time)
//     */
//     public entry fun setup_before_claim<T>(coins:&mut Coin<T>,ido_object:&mut IdoData, ctx:&mut TxContext){
//         // check time 
//         // assert!(ido_object.time_option == get_setup_time(),ERROR_NOT_CONFIG_TIME);
//         // check only owner can call this function
//         assert!(check_owner(ctx),ERROR_NOT_OWNER);
//         // check array whitelist empty or not
//         assert!(!vector::is_empty<address>(&ido_object.account_buyed),ERROR_WHITELIST_EMPTY);
//         // check coin type (not founded!!!!!)
//         // check coin value
//         assert!(coin::value(coins) > 0,ERROR_BALANCE_EQUAL_ZERO);
//         // check list buyed empty or not
//         let totalBuyed = vector::length(&ido_object.account_buyed);
//         assert!(totalBuyed > 0, ERROR_ACCOUNT_BUYED_EMPTY);
//         // split coin buy list buyed to transfer
//         let vec: vector<Coin<T>> = coin::divide_into_n(coins,totalBuyed+1,ctx);
//         let len =  vector::length(&vec);
//         assert!(len == totalBuyed,ERROR_ACCOUNT_BUYED_EMPTY);
//         //ofield::add<address,vector<Coin<T>>>(&mut ido_object.id,ido_object.owner,vec);
//         let token_claimable = TokenClaimable{
//             id: object::new(ctx),
//             claimable: vec
//         };
//         //transfer(token_claimable,tx_context::sender(ctx));
//         //vector::destroy_empty(vec);
//         // event
//         share_object(token_claimable);

//     }

//     /*
//     * claim funtion 
//     */
//     public entry fun claim<T>(ido_object:&mut IdoData, token_claimable: &mut TokenClaimable<T>, ctx:&mut TxContext){
//         // check time
//         assert!(ido_object.time_option == get_claim_time(),ERROR_NOT_CLAIM_TIME);
//         // check whitelist
//         let user_address = tx_context::sender(ctx);
//         assert!(is_white_list(&user_address),ERROR_NOT_WHITELIST);
//         // check buyed
//         let ido_id = &ido_object.id;
//         assert!(ofield::exists_<address>(ido_id,tx_context::sender(ctx)),ERROR_NOT_BUYED_TOKEN);
        
//         // remove dynamic data, to check exists condition
//         let AccountToken {
//             id,
//             token_amount
//         } = ofield::remove<address,AccountToken>(&mut ido_object.id, tx_context::sender(ctx));
//         assert!(token_amount == get_receive_amount(),ERROR_AMOUNT_RECEIVE_NOT_VALID);
//         // get token
//         let received_token = vector::pop_back(&mut token_claimable.claimable);
//         transfer(received_token,tx_context::sender(ctx));
//         object::delete(id);
//     }

//     /*
//     * update time
//     * not found timestamp at the moment
//     * be careful
//     */
//     public entry fun update_time_option(ido_object:&mut IdoData,time_option: u64, ctx:&mut TxContext){
//         // check owner
//         assert!(check_owner(ctx),ERROR_NOT_OWNER);
//         // check time_option updated must greater than current
//         assert!(ido_object.time_option < time_option,ERROR_TIME_UPDATED_INVALID);
//         // update
//         ido_object.time_option = time_option;
//         // event
//     }

// }