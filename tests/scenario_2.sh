#!/bin/bash

source env.sh

# Time in seconds, parameterizes tests. Setting higher X would cause smaller relative error.
X=30


OTHER_COIN_TYPE=0x$MODULE_ACCOUNT::pool::PoolToken

CMD_IDX=0
function RUN() {
    CMD=$1
    CMD_IDX=$(( $CMD_IDX + 1 ))
    IGreen='\033[0;92m'
    Color_Off='\033[0m'
    echo ""
    echo -e "$IGreen### STEP: $CMD_IDX"
    echo -e "$CMD $Color_Off"
    if [ -z "$DO_NOT_RUN_BY_TEST_SH" ]; then ./test.sh $CMD
    else bash -c "$CMD"
    fi
}

function wait_and_show_updated() {
    RUN "wait $1"
    RUN "user1 ping"
    RUN "user2 ping"
    RUN "user1 show"
    RUN "user2 show"
}

function initialize_pool() {
    USER=$1
    DO_NOT_RUN_BY_TEST_SH=1 RUN "aptos move run --assume-yes --function-id $MODULE_ACCOUNT::pool::init --type-args $STAKE_COIN_TYPE --profile $USER"
}


DO_NOT_RUN_BY_TEST_SH=1 RUN "SKIP_POOL_INITIALIZATION=1 SKIP_REWARD_PROGRAM_CREATION=1 ./setup.sh"
RUN "default stake 1"   # Expected: fails
RUN "new 1 0 0"         # Can create reward programs for uninitialized pool
initialize_pool user1   # Expected: fails
initialize_pool default
initialize_pool default # Expected: fails
COIN_TYPE=$OTHER_COIN_TYPE RUN "user1 stake 1" # Expected: fails
RUN "user1 withdraw"    # Expected: fails
RUN "user1 ping"        # Expected: fails
RUN "user1 stake 1"
CREATOR=user1 RUN "new 1 1 1" # Expected: fails
RUN "new 3600 1 0"
RUN "user1 show"        # Expected: has one reward program account
RUN "user2 stake 1"
RUN "user2 show"        # Expected: has two reward program accounts
RUN "wait $((2*$X))"
RUN "user1 show"        # Expected: has one reward program account
RUN "user2 show_updated" # Expected: user2 earned X
RUN "user1 ping"

wait_and_show_updated $((2*$X))
# Expected: user1 earned X, user2 earned 2X

COIN_TYPE=$OTHER_COIN_TYPE RUN "user1 withdraw 1" # Expected: fails
RUN "user2 withdraw" # Expected: fails
