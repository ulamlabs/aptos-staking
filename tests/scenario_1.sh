#!/bin/bash

source env.sh

# Time in seconds, parameterizes tests. Setting higher X would cause smaller relative error.
X=30


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


DO_NOT_RUN_BY_TEST_SH=1 RUN "./setup.sh"

RUN "user1 stake 2"
RUN "wait $X"
RUN "user1 show_updated"
# Expected: user1 earned X

RUN "user2 stake 1"
wait_and_show_updated $((3*$X))
# Expected: user1 earned 3X, user2 earned X

RUN "user1 unstake 1"
wait_and_show_updated $((2*$X))
# Expected: user1 earned 4X, user2 earned 2X

RUN "user1 unstake 1"
wait_and_show_updated $X
# Expected: user1 earned 4X, user2 earned 3X

RUN "user2 unstake 1"
wait_and_show_updated $X
# Expected: user1 earned 4X, user2 earned 3X

RUN "fund 0 $((5*$X))"
RUN "user1 withdraw"
RUN "user1 show"
RUN "show 0"
# Expected: user1 earned 0, reward program balance is X

RUN "user2 withdraw"
RUN "user2 show"
RUN "show 0"
# Expected: user2 earned 2X, reward program balance is 0
