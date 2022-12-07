// Copyright (c) Ulam Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
// Authors: Adam Chudas


/// The `controller` module is strictly tied with the corresponding `pool` module
/// published under the same address. <br> Its responsibility is to store `vector<address>`
/// of registered `RewardProgram`s and notify them whenever an user `stake`'s / `unstake`'s coins.<br>
/// Also, it is a proxy for an user to withdraw rewards from a chosen reward program
/// (the program must be registered to the `controller`) <br> and it passes `RewardProgramUserData`
/// stored under an user's account to an appropriate reward program.
module module_account::controller {
    use std::bcs;
    use std::signer;
    use std::vector;

    use aptos_std::simple_map::{Self, SimpleMap};

    use aptos_framework::coin;

    use module_account::reward_program::{Self, RewardProgramUserData};

    friend module_account::pool;

    /// A not-admin user tries to create a reward program.
    const E_NOT_ADMIN: u64 = 1;
    /// An user that never staked to this pool tries to withdraw.
    const E_NOT_REGISTERED_USER: u64 = 2;
    /// An user provided a reward program index that is too large.
    const E_REWARD_PROGRAM_INDEX_TOO_LARGE: u64 = 3;

    /// `controller`'s module internal singleton data struct.
    struct ControllerData has key {
        reward_programs: vector<address>,
    }

    /// Stores `RewardProgramUserData` structs mapped to appropriate reward program addresses. 
    /// The data is stored under an user account.
    struct RewardProgramsUser has key {
        reward_program_accounts: SimpleMap<address, RewardProgramUserData>,
    }

    /// See `pool::init_module`. The method initializes the `controller` module under the same
    /// resource account as the corresponding `pool` module.
    fun init_module(module_account: &signer) {
        move_to(module_account, ControllerData {
            reward_programs: vector::empty<address>(),
        });
    }
    
    /// Creates a reward program with given `reward_rate` (per second), `tier_return` (percent),
    /// `end_time` (unix timestamp in seconds), and reward coin type `Coin<R>`.
    public entry fun create_reward_program<R>(creator: &signer, end_time: u64,
        reward_rate: u64, tier_return: u64, 
    ) acquires ControllerData {
        assert!(signer::address_of(creator) == @creator, E_NOT_ADMIN);
        let reward_programs = &mut borrow_global_mut<ControllerData>(@module_account).reward_programs;
        let seed = bcs::to_bytes<u64>(&vector::length<address>(reward_programs));
        let reward_program_addr = reward_program::new<R>(creator, seed, end_time,
            reward_rate, tier_return,
        );
        vector::push_back(reward_programs, reward_program_addr);
    }

    /// Transfers rewards from a reward program at index `reward_program_index` to an `user`.<br>
    /// Registers the `user` for `Coin<R>` if needed, where `R` is the type of the reward coin.
    public entry fun withdraw_reward_from_program<R>(user: &signer, reward_program_index: u64)
    acquires ControllerData, RewardProgramsUser {
        let user_addr = signer::address_of(user);
        assert!(exists<RewardProgramsUser>(user_addr), E_NOT_REGISTERED_USER);
        if (!coin::is_account_registered<R>(user_addr)) coin::register<R>(user);
        let reward_programs = borrow_global<ControllerData>(@module_account).reward_programs;
        assert!(
            vector::length(&reward_programs) > reward_program_index,
            E_REWARD_PROGRAM_INDEX_TOO_LARGE
        );
        let reward_programs_user = borrow_global_mut<RewardProgramsUser>(user_addr);
        let reward_program_addr = *vector::borrow<address>(&reward_programs, reward_program_index);
        let reward_program_accounts = &mut reward_programs_user.reward_program_accounts;
        let user_data = simple_map::borrow_mut(reward_program_accounts, &reward_program_addr);
        reward_program::withdraw_reward<R>(reward_program_addr, user_addr, user_data);
    }

    /// Notifies all registered reward programs about the current `user_stake`.<br>
    /// Ensures the `user` is registered to all available reward programs.
    public(friend) fun notify<T>(user: &signer, user_stake: u64)
    acquires ControllerData, RewardProgramsUser {
        ensure_user_opted_in_all(user);
        let reward_programs = borrow_global<ControllerData>(@module_account).reward_programs;
        let user_addr = signer::address_of(user);
        let reward_programs_user = borrow_global_mut<RewardProgramsUser>(user_addr);
        let reward_program_accounts = &mut reward_programs_user.reward_program_accounts;
        let total_staked = coin::balance<T>(@module_account);
        let i = 0;
        while (i < vector::length(&reward_programs)) {
            let reward_program_addr = *vector::borrow(&reward_programs, i);
            let user_data = simple_map::borrow_mut(reward_program_accounts, &reward_program_addr);
            reward_program::update(reward_program_addr, total_staked, user_data, user_stake);
            i = i + 1;
        }
    }

    /// Ensures an `user` is registered to all available reward programs.
    fun ensure_user_opted_in_all(user: &signer) acquires ControllerData, RewardProgramsUser {
        let user_addr = signer::address_of(user);
        if (!exists<RewardProgramsUser>(user_addr)) {
            move_to(user, RewardProgramsUser {
                reward_program_accounts: simple_map::create<address, RewardProgramUserData>(),
            });
        };
        let reward_programs_user = borrow_global_mut<RewardProgramsUser>(user_addr);
        let reward_program_accounts = &mut reward_programs_user.reward_program_accounts;
        let i = simple_map::length(reward_program_accounts);
        let reward_programs = borrow_global<ControllerData>(@module_account).reward_programs;
        while (i < vector::length(&reward_programs)) {
            let reward_program_addr = *vector::borrow(&reward_programs, i);
            let reward_program_user_data = reward_program::new_user_data(reward_program_addr);
            simple_map::add(reward_program_accounts,
                reward_program_addr, reward_program_user_data
            );
            i = i + 1;
        }
    }
}
