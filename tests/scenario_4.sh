#!/bin/bash

source env.sh

INF=1000000000
X=$(($TIER_DURATION / 3))


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


DO_NOT_RUN_BY_TEST_SH=1 RUN "SKIP_REWARD_PROGRAM_CREATION=1 ./setup.sh"

RUN "user1 stake 100"
RUN "new $INF 1 10"
RUN "user2 stake 100"
wait_and_show_updated $((2 * $X))
# Expected: user1 earned 0, user2 earned X

wait_and_show_updated $((2 * $X))
# Expected: user1 earned X, user2 earned 2X + 10

wait_and_show_updated $((4 * $X))
# Expected: user1 earned 3X + 21, user2 earned 4X + 20
