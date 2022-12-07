#!/bin/bash

source env.sh

X=60 # Time in seconds, parameterizes tests. Setting higher X would cause smaller relative error.
WEEK=$((7 * 24 * 3600))
LARGE=1000000000 # Use both as a infinity time in seconds and as a large reward rate


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
    RUN "default ping"
    RUN "user1 ping"
    RUN "user2 ping"
    RUN "default show"
    RUN "user1 show"
    RUN "user2 show"
}


DO_NOT_RUN_BY_TEST_SH=1 RUN "SKIP_REWARD_PROGRAM_CREATION=1 ./setup.sh"

RUN "default stake 1"
RUN "new 0 $LARGE $LARGE"   # A program that would pay if it would run longer
RUN "user1 stake 2"
RUN "new $WEEK 100 5"       # Medium-duration program thay pays something
RUN "user2 stake 3"
RUN "new $LARGE 0 0"        # Endless program that pays nothing
RUN "default ping"
RUN "default withdraw"      # Expected: fails
RUN "default withdraw 2"    # Expected: fails
RUN "new $((4 * $X)) $LARGE 0" # Short-duration program that pays much
wait_and_show_updated $X 
# Expected for the 2nd program: default earned 100X/6, user1 earned 0, user2 earned 50X
# Expected for other programs: nobody earned anything

RUN "default unstake 1"
RUN "user1 stake 2"
RUN "user2 ping"

wait_and_show_updated $((3 * $X))
# Expected for the 2nd program: default earned >100X/6, user1 earned >170X, user2 earned around 180X
# Expected for the 4th program: default earned X*LARGE/6, user1 earned <12*X*LARGE/7, user2 earned <9*X*LARGE/7 
