// Copyright (c) Ulam Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
// Authors: Adam Chudas


/// The sole responsibility of the `pool`'s module is to store coins staked by users.<br>
/// When user `stake`'s / `unstake`'s an amount of `Coin<T>`, the `pool` calls `notify()`
/// method of the corresponding `controller` module, providing the user and new balance of the user.<br>
/// Although the `controller::notify()` method will automatically register the user to any available
/// reward programs, the user can call `pool::ping()` to achieve the same effect at any time.
module module_account::pool {
    use std::signer;
    use aptos_std::type_info::{Self, TypeInfo};

    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::resource_account;

    use module_account::controller::notify;

    /// A not-admin user tries to initialize the pool.
    const E_NOT_ADMIN: u64 = 1;
    /// An user that never staked to this pool tries to unstake / ping.
    const E_NOT_REGISTERED_USER: u64 = 2;
    /// An attempt to initalize pool that has been already initialized.
    const E_DOUBLE_INITIALIZATION: u64 = 3;
    /// An user tries to `stake` / `unstake` zero amount or `unstake` more than staked.
    const E_INVALID_AMOUNT: u64 = 4;
    /// An user calls a method providing different `Coin` type `T` than it should.
    const E_INVALID_COIN_TYPE: u64 = 5;
    /// The pool has not been initialized.
    const E_NOT_INITIALIZED: u64 = 6;
    

    /// `pool`'s module internal singleton data struct.
    struct PoolData has key {
        signer_cap: account::SignerCapability,
        is_initialized: bool,
        coin_type_info: TypeInfo,
    }

    /// Stores the balance of `Coin<T>` staked by an user in the `pool`.
    /// The struct is stored under the user's account.
    struct PoolToken has key {
        value: u64
    }
    
    /// A method that will be automatically invoked by `create_resource_account_and_publish_package`
    /// transaction. <br>The transaction provides a `signer` for the newly created resource account.<br>
    /// The method creates an unitialized `pool` module under the resource account' address.
    fun init_module(module_account: &signer) {
        let module_signer_cap = resource_account::retrieve_resource_account_cap(
            module_account, @creator
        );
        move_to(module_account, PoolData {
            signer_cap: module_signer_cap,
            is_initialized: false,
            coin_type_info: type_info::type_of<PoolData>(),
        });
    }

    /// An internal method that verifies that a correct `Coin` type `T` has been provided
    /// and the pool has been initialized.
    fun verify_coin_type<T>() acquires PoolData {
        let pool_data = borrow_global_mut<PoolData>(@module_account);
        assert!(pool_data.is_initialized, E_NOT_INITIALIZED);
        assert!(type_info::type_of<T>() == pool_data.coin_type_info, E_INVALID_COIN_TYPE);
    }


    //
    // Public methods
    //

    /// A method that must be called by the pool creator in order to initialize the pool.<br>
    /// As a type argument of this method, a type `T` of `Coin` is provided that will be used
    /// for staking.<br> The method register the pool for the `Coin<T>`.
    public entry fun init<T>(creator: &signer) acquires PoolData {
        assert!(signer::address_of(creator) == @creator, E_NOT_ADMIN);
        let pool_data = borrow_global_mut<PoolData>(@module_account);
        assert!(!pool_data.is_initialized, E_DOUBLE_INITIALIZATION);
        pool_data.is_initialized = true;
        pool_data.coin_type_info = type_info::type_of<T>();
        let module_signer = account::create_signer_with_capability(&pool_data.signer_cap);
        coin::register<T>(&module_signer);
    }

    /// Stakes amount of `Coin<T>` from `user` to `module` account.
    /// Updates user's `PoolToken` (creates if not existent) and calls `controller::notify()`.
    public entry fun stake<T>(user: &signer, amount: u64) acquires PoolData, PoolToken {
        verify_coin_type<T>();
        assert!(amount > 0, E_INVALID_AMOUNT);
        coin::transfer<T>(user, @module_account, amount);

        let user_addr = signer::address_of(user);
        if (!exists<PoolToken>(user_addr)) move_to(user, PoolToken { value: 0 });
        let pool_token = borrow_global_mut<PoolToken>(user_addr);

        pool_token.value = pool_token.value + amount;
        notify<T>(user, pool_token.value);
    }

    /// Unstakes amount of `Coin<T>` from `module` to `user` account.
    /// Updates user's `PoolToken` and calls `controller::notify()`.
    public entry fun unstake<T>(user: &signer, amount: u64) acquires PoolData, PoolToken {
        verify_coin_type<T>();
        let user_addr = signer::address_of(user);
        assert!(exists<PoolToken>(user_addr), E_NOT_REGISTERED_USER);
        let pool_token = borrow_global_mut<PoolToken>(user_addr);
        assert!(amount > 0 && amount <= pool_token.value, E_INVALID_AMOUNT);

        let module_data = borrow_global_mut<PoolData>(@module_account);
        let module_signer = account::create_signer_with_capability(&module_data.signer_cap);
        coin::transfer<T>(&module_signer, user_addr, amount);

        pool_token.value = pool_token.value - amount;
        notify<T>(user, pool_token.value);
    }

    /// Calls `controller::notify()` with user's current balance in order to register the user
    /// to all available reward programs and/or update program rewards.
    public entry fun ping<T>(user: &signer) acquires PoolData, PoolToken {
        verify_coin_type<T>();
        let user_addr = signer::address_of(user);
        assert!(exists<PoolToken>(user_addr), E_NOT_REGISTERED_USER);
        let pool_token = borrow_global<PoolToken>(user_addr);
        notify<T>(user, pool_token.value);
    }
}
