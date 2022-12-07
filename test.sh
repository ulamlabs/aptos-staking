#!/bin/bash
# The following script assumes that a MODULE_ACCOUNT environment variable has been set by `setup.sh`.
# For testing, we use `AptosCoin` for both staking and rewards.

# If the last argument for `withdraw` is not provided, the first reward program will be used.

# The `compile` command is there to check if the program compiles (if we do modify the source code).
# However, it does not publish the new version of the package to the chain.

source env.sh

if [ -z "$CREATOR" ]; then CREATOR=default; fi
if [ -z "$COIN_TYPE" ]; then COIN_TYPE=0x1::aptos_coin::AptosCoin; fi


function stake() {
    USER=$1
    AMOUNT=$2
    aptos move run --assume-yes --function-id $MODULE_ACCOUNT::pool::stake --profile $USER --type-args $COIN_TYPE --args u64:$AMOUNT
}

function unstake() {
    USER=$1
    AMOUNT=$2
    aptos move run --assume-yes --function-id $MODULE_ACCOUNT::pool::unstake --profile $USER --type-args $COIN_TYPE --args u64:$AMOUNT
}

function ping() {
    USER=$1
    aptos move run --assume-yes --function-id $MODULE_ACCOUNT::pool::ping --profile $USER --type-args $COIN_TYPE
}

function withdraw_reward() {
    USER=$1
    REWARD_PROGRAM_INDEX=$2
    if [ -z "$2" ]; then REWARD_PROGRAM_INDEX=0; fi
    aptos move run --assume-yes --function-id $MODULE_ACCOUNT::controller::withdraw_reward_from_program --profile $USER --type-args $COIN_TYPE --args u64:$REWARD_PROGRAM_INDEX
}

function check_compile() {
    aptos move compile --named-addresses creator=$CREATOR,module_account=$CREATOR
}

function show_user() {
    USER=$1
    IN=$(aptos account list --account $USER)
    if [[ "$IN" == *"RewardProgramsUser"* ]]; then
        OUT1=$(echo "$IN" | head -n 7)
        OUT2=$(echo "$IN" | sed -n '/RewardProgramsUser/,// p')
        echo "$OUT1"
        echo "$OUT2"
        return
    fi
    OUT=$(echo "$IN" | sed -n '/AptosCoin/,// p')
    echo "$OUT"
}

function show_pool() {
    IN=$(aptos account list --query resources --account $MODULE_ACCOUNT)
    OUT1=$(echo "$IN" | head -n 15 | tail -n 13)
    OUT2=$(echo "$IN" | sed -n '/ControllerData/,// p')
    echo "$OUT1"
    echo "$OUT2"
}

function new_reward_program() {
    REWARD_PROGRAM_DURATION=$1
    REWARD_RATE=$2
    TIER_RETURN=$3
    CURRENT_TIME_US=$(aptos node show-epoch-info | grep unix_time | head -n 1 | awk '{print $2}' | sed 's/.$//')
    END_TIME=$(( $CURRENT_TIME_US / 1000000 + $REWARD_PROGRAM_DURATION ))
    aptos move run --assume-yes --function-id $MODULE_ACCOUNT::controller::create_reward_program --profile $CREATOR --type-args $COIN_TYPE --args u64:$END_TIME u64:$REWARD_RATE u64:$TIER_RETURN
}

function fund_reward_program() {
    REWARD_PROGRAM_INDEX=$1
    REWARD_PROGRAM=REWARD_PROGRAM_$REWARD_PROGRAM_INDEX
    REWARD_PROGRAM_ADDRESS=${!REWARD_PROGRAM}
    AMOUNT=$2
    aptos account fund-with-faucet --account $REWARD_PROGRAM_ADDRESS --amount $AMOUNT
}

function show_reward_program() {
    REWARD_PROGRAM_INDEX=$1
    REWARD_PROGRAM=REWARD_PROGRAM_$REWARD_PROGRAM_INDEX
    REWARD_PROGRAM_ADDRESS=${!REWARD_PROGRAM}
    IN=$(aptos account list --query resources --account $REWARD_PROGRAM_ADDRESS)
    OUT=$(echo "$IN" | sed -n '/RewardProgram/,// p')
    echo "$OUT"
}


if [ $# -eq 4 ] && [ $1 = new ]; then new_reward_program $2 $3 $4
elif [ $# -eq 2 ] && [ $1 = show ]; then show_reward_program $2
elif [ $# -eq 3 ] && [ $1 = fund ]; then fund_reward_program $2 $3
elif [ $# -eq 1 ] && [ $1 = compile ]; then check_compile
elif [ $# -eq 1 ] && [ $1 = show ]; then show_pool
elif [ $# -eq 2 ] && [ $1 = wait ]; then sleep $2
elif [ $2 = stake ]; then stake $1 $3
elif [ $2 = unstake ]; then unstake $1 $3
elif [ $2 = ping ]; then ping $1
elif [ $2 = show ]; then show_user $1
elif [ $2 = show_updated ]; then ping $1; show_user $1
elif [ $2 = withdraw ]; then withdraw_reward $1 $3
else echo Unrecognized command
fi
