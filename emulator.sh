#!/bin/bash

# ==========================================================
# ARGUMENTS 
# ==========================================================

Help()
{
    printf "./emulator.sh -m [physical|virtual] -p [J1939|J1979] -i [interface (can0, can1, etc)] [optional arguments]\n"
    printf "\t-m : (Required) mode. \"physical\" or \"virtual\"\n"
    printf "\t-a : (Required) ECU Address. For J1979, can be 7E0 - 7E8. For J1939 can be 0x00 - 0xFE.\n"
    printf "\t-p : (Required) protocol. \"J1939\" or \"J1979\"\n"
    printf "\t-d : (optional) disable broadcast messages. Useful for debugging request/response messages.\n"
    printf "\t-b : (optional) vehicle info file. File to overwrite default vehicle values such as VIN or ECU Address\n"
    printf "\t-h : display help message\n"
    printf "\t-v : verbose mode\n"
    printf "Examples:\n\tEmulate a J1979 ECU with Address 7E0 on a virtual can interface\n\n"
    printf "\t\t./emulator.sh -m virtual -p J1979 -i can0 -a 7E0\n\n"
    printf "\tEmulate a J1939 ECU with Address 0x21 on physical CAN interface can1\n\n"
    printf "\t\t./emulator.sh -m physical -p J1939 -i can1 -a 21\n\n"
}

banner()
{
    printf "========================================\n"
    printf "$1\n"
    printf "========================================\n"
}

while getopts ":m:p:i:db:a:v" option; do
   case ${option} in
      i) # can interface name can0, can1, etc
         CAN_IFACE=${OPTARG}
         ;;
      b) # vehicle info file
         VEHICLE_INFO_FILE=${OPTARG}
         ;;
      a) # source address ( J1939 only )
         sourceAddress=${OPTARG}
         ;;
      m) # mode - physical or virtual
         MODE=${OPTARG}
         ;;
      d) # disable broadcast messages
         printf "broadcast messages are disabled\n"
         RUN_SCHEDULER=0
         ;;
      v) # verbose
         VERBOSE=true
         ;;
      p) # protocol
         if [ "${OPTARG}" != "J1939" ] && [ "${OPTARG}" != "J1979" ]; then
            Help
         fi
         PROTOCOL=${OPTARG}
         ;;
      h) # display Help
         echo ${OPTARG}
         Help
         exit
         ;;
      *)
         printf "${OPTARG} is not an accepted option.\n"
         Help
         exit 1
         ;;
   esac
done

if [ $# -lt 7 ]; then
    printf "Not enough arguments passed.\n"
    Help
    exit 1
fi

if [ "$RUN_SCHEDULER" = "" ]; then
    printf "broadcast messages are enabled\n"
    RUN_SCHEDULER=1
fi

banner "Starting Vehicle Emulator in $MODE Mode"

# ==========================================================
# GLOBALS
# ==========================================================

# can msg FIFO
CAN_FIFO="/tmp/can_fifo_$(date +%N)"
SEND_FIFO="/tmp/send_fifo_$(date +%N)"
CAN_LOGFILE="/tmp/can_log.txt"

# Multi-Frame Messages
IN_MULTIFRAME=0
MULTIFRAME_PAYLOAD=

# Frame Types
SINGLE_FRAME=0
FIRST_FRAME=1
CONSECUTIVE_FRAME=2
FLOW_FRAME=3

CAN_IFACE_LEN=${#CAN_IFACE}

# ==========================================================
# Definitions
# ==========================================================

banner "Sourcing $PROTOCOL functions"

# Vehicle Info
if [ ! -z $VEHICLE_INFO_FILE ]; then
    source $VEHICLE_INFO_FILE
else
    VIN="1234ABCTHISISAVIN"
    printf "Vehicle Info File not specified, default VIN=$VIN\n"
fi

# Source the correct PID definitions
if [ "$PROTOCOL" = "J1979" ]; then
    printf "Sourcing J1979.sh\n"
    source ./J1979.sh
else
    printf "Sourcing J1939.sh\n"
    source ./J1939.sh
fi

source ./common.sh

# ==========================================================
# Print Information
# ==========================================================
printf  "VIN: $VIN\n"
printf  "ECU: $ECU_ADDR\n"

# ==========================================================
# A Couple Important Things
# ==========================================================

handle_sigint()
{
    # close the fifos and exit
    exec 3>$-
    exec 4>$-
    # remove fifo files
    rm -rf $CAN_FIFO $SEND_FIFO
    exit 1
}
trap handle_sigint SIGINT

# ==========================================================
# Bring up interface for DUT to query
# ==========================================================

banner "Bringing up $CAN_IFACE"

# Bring up interface
bringUpCanIface $CAN_IFACE $MODE

# ==========================================================
# Create FIFO and start dumping can frames into it
# ==========================================================

[ -p $CAN_FIFO ] || mkfifo $CAN_FIFO
runCandump &

# ==========================================================
# start mainloop
# ==========================================================

run${PROTOCOL}Mainloop
