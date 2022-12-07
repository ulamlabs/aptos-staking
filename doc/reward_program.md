
<a name="staking_reward_program"></a>

# Module `staking::reward_program`

This module implements reward programs logic. There can be many reward programs at once,
each can be registered to the same (and only one) <code><a href="controller.md#staking_controller">controller</a></code>
published under the same module address. All global reward program's data is stored
within <code><a href="reward_program.md#staking_reward_program_RewardProgram">RewardProgram</a></code> struct under a dedicated address.
All user related data is stored within <code><a href="reward_program.md#staking_reward_program_RewardProgramUserData">RewardProgramUserData</a></code> struct under the user account.


-  [Resource `RewardProgram`](#staking_reward_program_RewardProgram)
-  [Struct `RewardProgramUserData`](#staking_reward_program_RewardProgramUserData)
-  [Constants](#@Constants_0)
-  [Function `new`](#staking_reward_program_new)
-  [Function `does_exist`](#staking_reward_program_does_exist)
-  [Function `new_user_data`](#staking_reward_program_new_user_data)
-  [Function `update`](#staking_reward_program_update)
-  [Function `withdraw_reward`](#staking_reward_program_withdraw_reward)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::math64</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="">0x1::type_info</a>;
</code></pre>



<a name="staking_reward_program_RewardProgram"></a>

## Resource `RewardProgram`

Not user-specific data needed by a reward program.<br>
<code>reward_per_token_acc</code> is expressed in the reward coin precision,
e.g. 10k Octas reward accumulated per one Aptos token.


<pre><code><b>struct</b> <a href="reward_program.md#staking_reward_program_RewardProgram">RewardProgram</a> <b>has</b> key
</code></pre>



<a name="staking_reward_program_RewardProgramUserData"></a>

## Struct `RewardProgramUserData`

User-specific data needed by a reward program.


<pre><code><b>struct</b> <a href="reward_program.md#staking_reward_program_RewardProgramUserData">RewardProgramUserData</a> <b>has</b> store
</code></pre>



<a name="@Constants_0"></a>

## Constants


<a name="staking_reward_program_E_INVALID_REWARD_COIN_TYPE"></a>

An user tries to withdraw a reward passing incorrect reward coin type.


<pre><code><b>const</b> <a href="reward_program.md#staking_reward_program_E_INVALID_REWARD_COIN_TYPE">E_INVALID_REWARD_COIN_TYPE</a>: u64 = 1;
</code></pre>



<a name="staking_reward_program_E_NO_REWARD"></a>

The withdrawal failed because there is no reward for an user to be withdrawn.


<pre><code><b>const</b> <a href="reward_program.md#staking_reward_program_E_NO_REWARD">E_NO_REWARD</a>: u64 = 2;
</code></pre>



<a name="staking_reward_program_E_REWARD_PROGRAM_ZERO_BALANCE"></a>

The reward program has zero reward coin' balance.


<pre><code><b>const</b> <a href="reward_program.md#staking_reward_program_E_REWARD_PROGRAM_ZERO_BALANCE">E_REWARD_PROGRAM_ZERO_BALANCE</a>: u64 = 3;
</code></pre>



<a name="staking_reward_program_TIER_DURATION"></a>

Duration of a tier. Here, 1 week in seconds.


<pre><code><b>const</b> <a href="reward_program.md#staking_reward_program_TIER_DURATION">TIER_DURATION</a>: u64 = 604800;
</code></pre>



<a name="staking_reward_program_new"></a>

## Function `new`

Creates a new reward program with a reward <code>Coin</code> of type <code>R</code>.<br>
The reward program starts immediately and rewards until <code>end_time</code> (unix timestamp in seconds).<br>
It rewards <code>reward_rate</code> per second plus <code>tier_return</code> % for each full tier under which the amount was staked.<br>
The method moves the newly created reward program to a new, dedicated address and returns the address.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_program.md#staking_reward_program_new">new</a>&lt;R&gt;(creator_account: &<a href="">signer</a>, seed: <a href="">vector</a>&lt;u8&gt;, end_time: u64, reward_rate: u64, tier_return: u64): <b>address</b>
</code></pre>



<a name="staking_reward_program_does_exist"></a>

## Function `does_exist`

Checks whether a <code><a href="reward_program.md#staking_reward_program_RewardProgram">RewardProgram</a></code> exists under a <code>reward_program_addr</code>.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_program.md#staking_reward_program_does_exist">does_exist</a>(reward_program_addr: <b>address</b>): bool
</code></pre>



<a name="staking_reward_program_new_user_data"></a>

## Function `new_user_data`

Creates the <code><a href="reward_program.md#staking_reward_program_RewardProgramUserData">RewardProgramUserData</a></code> for a new user to the reward program.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_program.md#staking_reward_program_new_user_data">new_user_data</a>(reward_program_addr: <b>address</b>): <a href="reward_program.md#staking_reward_program_RewardProgramUserData">reward_program::RewardProgramUserData</a>
</code></pre>



<a name="staking_reward_program_update"></a>

## Function `update`

Updates a <code><a href="reward_program.md#staking_reward_program_RewardProgram">RewardProgram</a></code> stored under <code>reward_program_addr</code> with information about
the current <code>user_stake</code> and <code><a href="pool.md#staking_pool">pool</a></code>'s <code>total_staked</code> amount.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <b>update</b>(reward_program_addr: <b>address</b>, total_staked: u64, user_data: &<b>mut</b> <a href="reward_program.md#staking_reward_program_RewardProgramUserData">reward_program::RewardProgramUserData</a>, user_stake: u64)
</code></pre>



<a name="staking_reward_program_withdraw_reward"></a>

## Function `withdraw_reward`

Withdraws as much reward as possible for the user and transfer it to the <code>user_addr</code>.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="reward_program.md#staking_reward_program_withdraw_reward">withdraw_reward</a>&lt;R&gt;(reward_program_addr: <b>address</b>, user_addr: <b>address</b>, user_data: &<b>mut</b> <a href="reward_program.md#staking_reward_program_RewardProgramUserData">reward_program::RewardProgramUserData</a>)
</code></pre>
