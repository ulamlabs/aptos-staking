#!/bin/bash

source env.sh

USERS=("default" "user1" "user2")
REWARD_PROGRAM_DURATION=3600 # 1 hour
REWARD_RATE=1
TIER_RETURN=0


function print_status() {
  IGreen='\033[0;92m'
  Color_Off='\033[0m'
  echo ""
  echo ""
  echo -e "$IGreen### $1$Color_Off"
  echo ""
}


print_status "Creating user profiles"
sleep 1
for PROFILE in ${USERS[@]}; do
  echo | aptos init --assume-yes --network local --profile $PROFILE
done


print_status "Publishing package"
sleep 6
aptos move create-resource-account-and-publish-package --assume-yes --seed 42 --named-addresses creator=default --address-name module_account


if [ -z "$SKIP_POOL_INITIALIZATION" ]; then
  print_status "Initializing pool"
  aptos move run --assume-yes --function-id $MODULE_ACCOUNT::pool::init --type-args $STAKE_COIN_TYPE
fi


if [ -z "$SKIP_REWARD_PROGRAM_CREATION" ]; then
  print_status "Creating reward program"
  CURRENT_TIME_US=$(aptos node show-epoch-info | grep unix_time | head -n 1 | awk '{print $2}' | sed 's/.$//')
  END_TIME=$(( $CURRENT_TIME_US / 1000000  + $REWARD_PROGRAM_DURATION ))
  aptos move run --assume-yes --function-id $MODULE_ACCOUNT::controller::create_reward_program --type-args $REWARD_COIN_TYPE --args u64:$END_TIME u64:$REWARD_RATE u64:$TIER_RETURN
fi
