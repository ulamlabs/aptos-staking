// Copyright (c) Ulam Labs, Inc.
// SPDX-License-Identifier: Apache-2.0
// Authors: Adam Chudas


/// This module implements reward programs logic. There can be many reward programs at once,
/// each can be registered to the same (and only one) `controller`
/// published under the same module address. All global reward program's data is stored
/// within `RewardProgram` struct under a dedicated address.
/// All user related data is stored within `RewardProgramUserData` struct under the user account.
module module_account::reward_program {
    use std::signer;
    use aptos_std::math64;
    use aptos_std::type_info::{Self, TypeInfo};

    use aptos_framework::account;
    use aptos_framework::coin;
    use aptos_framework::timestamp;

    friend module_account::controller;

    /// An user tries to withdraw a reward passing incorrect reward coin type.
    const E_INVALID_REWARD_COIN_TYPE: u64 = 1;
    /// The withdrawal failed because there is no reward for an user to be withdrawn.
    const E_NO_REWARD: u64 = 2;
    /// The reward program has zero reward coin' balance.
    const E_REWARD_PROGRAM_ZERO_BALANCE: u64 = 3;

    /// Duration of a tier. Here, 1 week in seconds.
    const TIER_DURATION: u64 = 604800;

    /// Not user-specific data needed by a reward program.<br>
    /// `reward_per_token_acc` is expressed in the reward coin precision,
    /// e.g. 10k Octas reward accumulated per one Aptos token.
    struct RewardProgram has key {
        signer_cap: account::SignerCapability,
        reward_coin_type_info: TypeInfo,
        reward_coin_precision: u64,
        end_time: u64,
        last_update_time: u64,
        total_staked: u64,
        reward_per_token_acc: u64,
        reward_rate: u64,
        tier_return: u64,
    }

    /// User-specific data needed by a reward program.
    struct RewardProgramUserData has store {
        reward_per_token_paid: u64,
        reward_earned: u64,
        staked_amount: u64,
        staked_timestamp: u64,
    }

    /// Creates a new reward program with a reward `Coin` of type `R`.<br>
    /// The reward program starts immediately and rewards until `end_time` (unix timestamp in seconds).<br>
    /// It rewards `reward_rate` per second plus `tier_return` % for each full tier under which the amount was staked.<br>
    /// The method moves the newly created reward program to a new, dedicated address and returns the address.
    public(friend) fun new<R>(creator_account: &signer, seed: vector<u8>, end_time: u64,
        reward_rate: u64, tier_return: u64, 
    ): address {
        let (reward_program_account, reward_program_signer_cap) =
            account::create_resource_account(creator_account, seed);
        let reward_coin_precision = math64::pow(10, (coin::decimals<R>() as u64));

        move_to(&reward_program_account, RewardProgram {
            signer_cap: reward_program_signer_cap,
            reward_coin_type_info: type_info::type_of<R>(),
            reward_coin_precision,
            end_time,
            last_update_time: timestamp::now_seconds(),
            total_staked: 0,
            reward_per_token_acc: 0,
            reward_rate,
            tier_return,
        });
        coin::register<R>(&reward_program_account);
        signer::address_of(&reward_program_account)
    }

    /// Checks whether a `RewardProgram` exists under a `reward_program_addr`.
    public(friend) fun does_exist(reward_program_addr: address): bool {
        exists<RewardProgram>(reward_program_addr)
    }

    /// Creates the `RewardProgramUserData` for a new user to the reward program.
    public(friend) fun new_user_data(reward_program_addr: address): RewardProgramUserData
    acquires RewardProgram {
        let reward_program = borrow_global<RewardProgram>(reward_program_addr);
        RewardProgramUserData {
            reward_per_token_paid: reward_program.reward_per_token_acc,
            reward_earned: 0,
            staked_amount: 0,
            staked_timestamp: 0,
        }
    }
    
    /// Updates a `RewardProgram` stored under `reward_program_addr` with information about
    /// the current `user_stake` and `pool`'s `total_staked` amount. 
    public(friend) fun update(
        reward_program_addr: address,
        total_staked: u64,
        user_data: &mut RewardProgramUserData,
        user_stake: u64
    ) acquires RewardProgram {
        let reward_program = borrow_global_mut<RewardProgram>(reward_program_addr);
        update_reward_per_token_acc(reward_program);
        reward_program.last_update_time = timestamp::now_seconds();
        reward_program.total_staked = total_staked;
        update_user_reward(reward_program, user_data, user_stake);
    }
    
    /// Withdraws as much reward as possible for the user and transfer it to the `user_addr`.
    public(friend) fun withdraw_reward<R>(
        reward_program_addr: address,
        user_addr: address,
        user_data: &mut RewardProgramUserData,
    ) acquires RewardProgram {
        let reward_program = borrow_global_mut<RewardProgram>(reward_program_addr);
        let reward_coin_type_info = reward_program.reward_coin_type_info;
        assert!(type_info::type_of<R>() == reward_coin_type_info, E_INVALID_REWARD_COIN_TYPE);

        let user_staked_amount = user_data.staked_amount;
        update_user_reward(reward_program, user_data, user_staked_amount);
        let reward_amount = user_data.reward_earned;
        assert!(reward_amount > 0, E_NO_REWARD);
        let reward_program_balance = coin::balance<R>(reward_program_addr);
        assert!(reward_program_balance > 0, E_REWARD_PROGRAM_ZERO_BALANCE);
        if (reward_amount > reward_program_balance) reward_amount = reward_program_balance;

        user_data.reward_earned = user_data.reward_earned - reward_amount;
        let reward_program_signer =
            account::create_signer_with_capability(&reward_program.signer_cap);
        coin::transfer<R>(&reward_program_signer, user_addr, reward_amount);
    }

    /// Updates a reward that would be earned by a single token
    /// if it was staked from the beginning of the program.
    fun update_reward_per_token_acc(self: &mut RewardProgram) {
        if (self.total_staked == 0) return;
        let last_time_reward_applicable = last_time_reward_applicable(self);
        if (self.last_update_time >= last_time_reward_applicable) return;
        let d_time = last_time_reward_applicable - self.last_update_time;
        let d_reward = self.reward_rate * d_time * self.reward_coin_precision / self.total_staked;
        self.reward_per_token_acc = self.reward_per_token_acc + d_reward;
    }

    /// Returns a minimum of the current time and the `end_time`. 
    fun last_time_reward_applicable(self: &mut RewardProgram): u64 {
        let now = timestamp::now_seconds();
        if (now < self.end_time) now
        else self.end_time
    }

    /// Get the number of full tiers that since `staked_timestamp`.
    fun get_full_tier_count(self: &mut RewardProgram, staked_timestamp: u64): u64 {
        if (staked_timestamp == 0) return 0;
        let last_time_reward_applicable = last_time_reward_applicable(self);
        if (staked_timestamp >= last_time_reward_applicable) return 0;
        let stake_duration = last_time_reward_applicable - staked_timestamp;
        stake_duration / TIER_DURATION
    }

    /// Updates a reward earned by an user so far, and updates with the new `user_stake`.
    fun update_user_reward(
        self: &mut RewardProgram, user_data: &mut RewardProgramUserData, user_stake: u64,
    ) {
        let user_previous_stake = user_data.staked_amount;
        user_data.staked_amount = user_stake;
        
        // Reward based on `reward_rate`
        let d_reward_per_token = self.reward_per_token_acc - user_data.reward_per_token_paid;
        let d_reward = d_reward_per_token * user_previous_stake / self.reward_coin_precision;
        user_data.reward_per_token_paid = self.reward_per_token_acc;
        user_data.reward_earned = user_data.reward_earned + d_reward;

        let should_update_user_staked_timestamp = (user_stake > user_previous_stake);

        // Reward based on `tier_return`
        let tier_count = get_full_tier_count(self, user_data.staked_timestamp);
        if (tier_count > 0) {
            let tier_reward = user_previous_stake;
            while (tier_count > 0) {
                tier_reward = tier_reward * (100 + self.tier_return) / 100;
                tier_count = tier_count - 1;
            };
            tier_reward = tier_reward - user_previous_stake;
            user_data.reward_earned = user_data.reward_earned + tier_reward;
            should_update_user_staked_timestamp = true;
        };

        if (should_update_user_staked_timestamp)
            user_data.staked_timestamp = timestamp::now_seconds();
    }
}
