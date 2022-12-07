
<a name="staking_pool"></a>

# Module `staking::pool`

The sole responsibility of the <code><a href="pool.md#staking_pool">pool</a></code>'s module is to store coins staked by users.<br>
When user <code><a href="">stake</a></code>'s / <code>unstake</code>'s an amount of <code>Coin&lt;T&gt;</code>, the <code><a href="pool.md#staking_pool">pool</a></code> calls <code>notify()</code>
method of the corresponding <code><a href="controller.md#staking_controller">controller</a></code> module, providing the user and new balance of the user.<br>
Although the <code><a href="controller.md#staking_controller_notify">controller::notify</a>()</code> method will automatically register the user to any available
reward programs, the user can call <code><a href="pool.md#staking_pool_ping">pool::ping</a>()</code> to achieve the same effect at any time.


-  [Resource `PoolData`](#staking_pool_PoolData)
-  [Resource `PoolToken`](#staking_pool_PoolToken)
-  [Constants](#@Constants_0)
-  [Function `init`](#staking_pool_init)
-  [Function `stake`](#staking_pool_stake)
-  [Function `unstake`](#staking_pool_unstake)
-  [Function `ping`](#staking_pool_ping)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::resource_account</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::type_info</a>;
<b>use</b> <a href="controller.md#staking_controller">staking::controller</a>;
</code></pre>



<a name="staking_pool_PoolData"></a>

## Resource `PoolData`

<code><a href="pool.md#staking_pool">pool</a></code>'s module internal singleton data struct.


<pre><code><b>struct</b> <a href="pool.md#staking_pool_PoolData">PoolData</a> <b>has</b> key
</code></pre>



<a name="staking_pool_PoolToken"></a>

## Resource `PoolToken`

Stores the balance of <code>Coin&lt;T&gt;</code> staked by an user in the <code><a href="pool.md#staking_pool">pool</a></code>.
The struct is stored under the user's account.


<pre><code><b>struct</b> <a href="pool.md#staking_pool_PoolToken">PoolToken</a> <b>has</b> key
</code></pre>



<a name="@Constants_0"></a>

## Constants


<a name="staking_pool_E_NOT_ADMIN"></a>

A not-admin user tries to initialize the pool.


<pre><code><b>const</b> <a href="pool.md#staking_pool_E_NOT_ADMIN">E_NOT_ADMIN</a>: u64 = 1;
</code></pre>



<a name="staking_pool_E_NOT_REGISTERED_USER"></a>

An user that never staked to this pool tries to unstake / ping.


<pre><code><b>const</b> <a href="pool.md#staking_pool_E_NOT_REGISTERED_USER">E_NOT_REGISTERED_USER</a>: u64 = 2;
</code></pre>



<a name="staking_pool_E_DOUBLE_INITIALIZATION"></a>

An attempt to initalize pool that has been already initialized.


<pre><code><b>const</b> <a href="pool.md#staking_pool_E_DOUBLE_INITIALIZATION">E_DOUBLE_INITIALIZATION</a>: u64 = 3;
</code></pre>



<a name="staking_pool_E_INVALID_AMOUNT"></a>

An user tries to <code><a href="">stake</a></code> / <code>unstake</code> zero amount or <code>unstake</code> more than staked.


<pre><code><b>const</b> <a href="pool.md#staking_pool_E_INVALID_AMOUNT">E_INVALID_AMOUNT</a>: u64 = 4;
</code></pre>



<a name="staking_pool_E_INVALID_COIN_TYPE"></a>

An user calls a method providing different <code>Coin</code> type <code>T</code> than it should.


<pre><code><b>const</b> <a href="pool.md#staking_pool_E_INVALID_COIN_TYPE">E_INVALID_COIN_TYPE</a>: u64 = 5;
</code></pre>



<a name="staking_pool_E_NOT_INITIALIZED"></a>

The pool has not been initialized.


<pre><code><b>const</b> <a href="pool.md#staking_pool_E_NOT_INITIALIZED">E_NOT_INITIALIZED</a>: u64 = 6;
</code></pre>



<a name="staking_pool_init"></a>

## Function `init`

A method that must be called by the pool creator in order to initialize the pool.<br>
As a type argument of this method, a type <code>T</code> of <code>Coin</code> is provided that will be used
for staking.<br> The method register the pool for the <code>Coin&lt;T&gt;</code>.


<pre><code><b>public</b> entry <b>fun</b> <a href="pool.md#staking_pool_init">init</a>&lt;T&gt;(creator: &<a href="">signer</a>)
</code></pre>



<a name="staking_pool_stake"></a>

## Function `stake`

Stakes amount of <code>Coin&lt;T&gt;</code> from <code>user</code> to <code><b>module</b></code> account.
Updates user's <code><a href="pool.md#staking_pool_PoolToken">PoolToken</a></code> (creates if not existent) and calls <code><a href="controller.md#staking_controller_notify">controller::notify</a>()</code>.


<pre><code><b>public</b> entry <b>fun</b> <a href="">stake</a>&lt;T&gt;(user: &<a href="">signer</a>, amount: u64)
</code></pre>



<a name="staking_pool_unstake"></a>

## Function `unstake`

Unstakes amount of <code>Coin&lt;T&gt;</code> from <code><b>module</b></code> to <code>user</code> account.
Updates user's <code><a href="pool.md#staking_pool_PoolToken">PoolToken</a></code> and calls <code><a href="controller.md#staking_controller_notify">controller::notify</a>()</code>.


<pre><code><b>public</b> entry <b>fun</b> <a href="pool.md#staking_pool_unstake">unstake</a>&lt;T&gt;(user: &<a href="">signer</a>, amount: u64)
</code></pre>



<a name="staking_pool_ping"></a>

## Function `ping`

Calls <code><a href="controller.md#staking_controller_notify">controller::notify</a>()</code> with user's current balance in order to register the user
to all available reward programs and/or update program rewards.


<pre><code><b>public</b> entry <b>fun</b> <a href="pool.md#staking_pool_ping">ping</a>&lt;T&gt;(user: &<a href="">signer</a>)
</code></pre>
