
<a name="staking_controller"></a>

# Module `staking::controller`

The <code><a href="controller.md#staking_controller">controller</a></code> module is strictly tied with the corresponding <code><a href="pool.md#staking_pool">pool</a></code> module
published under the same address. <br> Its responsibility is to store <code><a href="">vector</a>&lt;<b>address</b>&gt;</code>
of registered <code>RewardProgram</code>s and notify them whenever an user <code><a href="">stake</a></code>'s / <code>unstake</code>'s coins.<br>
Also, it is a proxy for an user to withdraw rewards from a chosen reward program
(the program must be registered to the <code><a href="controller.md#staking_controller">controller</a></code>) <br> and it passes <code>RewardProgramUserData</code>
stored under an user's account to an appropriate reward program.


-  [Resource `ControllerData`](#staking_controller_ControllerData)
-  [Resource `RewardProgramsUser`](#staking_controller_RewardProgramsUser)
-  [Constants](#@Constants_0)
-  [Function `create_reward_program`](#staking_controller_create_reward_program)
-  [Function `withdraw_reward_from_program`](#staking_controller_withdraw_reward_from_program)
-  [Function `notify`](#staking_controller_notify)


<pre><code><b>use</b> <a href="">0x1::bcs</a>;
<b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::simple_map</a>;
<b>use</b> <a href="reward_program.md#staking_reward_program">staking::reward_program</a>;
</code></pre>



<a name="staking_controller_ControllerData"></a>

## Resource `ControllerData`

<code><a href="controller.md#staking_controller">controller</a></code>'s module internal singleton data struct.


<pre><code><b>struct</b> <a href="controller.md#staking_controller_ControllerData">ControllerData</a> <b>has</b> key
</code></pre>



<a name="staking_controller_RewardProgramsUser"></a>

## Resource `RewardProgramsUser`

Stores <code>RewardProgramUserData</code> structs mapped to appropriate reward program addresses.
The data is stored under an user account.


<pre><code><b>struct</b> <a href="controller.md#staking_controller_RewardProgramsUser">RewardProgramsUser</a> <b>has</b> key
</code></pre>



<a name="@Constants_0"></a>

## Constants


<a name="staking_controller_E_NOT_ADMIN"></a>

A not-admin user tries to create a reward program.


<pre><code><b>const</b> <a href="controller.md#staking_controller_E_NOT_ADMIN">E_NOT_ADMIN</a>: u64 = 1;
</code></pre>



<a name="staking_controller_E_NOT_REGISTERED_USER"></a>

An user that never staked to this pool tries to withdraw.


<pre><code><b>const</b> <a href="controller.md#staking_controller_E_NOT_REGISTERED_USER">E_NOT_REGISTERED_USER</a>: u64 = 2;
</code></pre>



<a name="staking_controller_E_REWARD_PROGRAM_INDEX_TOO_LARGE"></a>

An user provided a reward program index that is too large.


<pre><code><b>const</b> <a href="controller.md#staking_controller_E_REWARD_PROGRAM_INDEX_TOO_LARGE">E_REWARD_PROGRAM_INDEX_TOO_LARGE</a>: u64 = 3;
</code></pre>



<a name="staking_controller_create_reward_program"></a>

## Function `create_reward_program`

Creates a reward program with given <code>reward_rate</code> (per second), <code>tier_return</code> (percent),
<code>end_time</code> (unix timestamp in seconds), and reward coin type <code>Coin&lt;R&gt;</code>.


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#staking_controller_create_reward_program">create_reward_program</a>&lt;R&gt;(creator: &<a href="">signer</a>, end_time: u64, reward_rate: u64, tier_return: u64)
</code></pre>



<a name="staking_controller_withdraw_reward_from_program"></a>

## Function `withdraw_reward_from_program`

Transfers rewards from a reward program at index <code>reward_program_index</code> to an <code>user</code>.<br>
Registers the <code>user</code> for <code>Coin&lt;R&gt;</code> if needed, where <code>R</code> is the type of the reward coin.


<pre><code><b>public</b> entry <b>fun</b> <a href="controller.md#staking_controller_withdraw_reward_from_program">withdraw_reward_from_program</a>&lt;R&gt;(user: &<a href="">signer</a>, reward_program_index: u64)
</code></pre>



<a name="staking_controller_notify"></a>

## Function `notify`

Notifies all registered reward programs about the current <code>user_stake</code>.<br>
Ensures the <code>user</code> is registered to all available reward programs.


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="controller.md#staking_controller_notify">notify</a>&lt;T&gt;(user: &<a href="">signer</a>, user_stake: u64)
</code></pre>
