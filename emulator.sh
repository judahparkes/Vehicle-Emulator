#!/bin/bash

# ==========================================================
# ARGUMENTS 
# ==========================================================

Help()
{
    printf "./emulator.sh -m [physical|virtual] [optional arguments]\n"
    printf "\th : display help message\n"
    printf "\tv : verbose mode\n"
    printf "\tm : (Required) mode. \"physical\" or \"virtual\"\n"
}

while getopts ":hm:v" option; do
   case $option in
      m) # mode - physical or virtual
         MODE=$OPTARG;;
      v) # verbose
         VERBOSE=true;;
      h) # display Help
         Help
         exit;;
   esac
done
printf "========================================\n"
printf "Starting Vehicle Emulator in $MODE Mode\n"
printf "========================================\n"

# ==========================================================
# GLOBALS
# ==========================================================

# can msg FIFO
CAN_FIFO="/tmp/can_fifo"
CAN_LOGFILE="/tmp/can_log.txt"

# Multi-Frame Messages
IN_MULTIFRAME=0
MULTIFRAME_PAYLOAD=

# Frame Types
SINGLE_FRAME=0
FIRST_FRAME=1
CONSECUTIVE_FRAME=2
FLOW_FRAME=3

CAN_IFACE="can0"
CAN_IFACE_LEN=${#CAN_IFACE}

# ==========================================================
# Definitions
# ==========================================================

# Vehicle Info
VIN="1FT7W2B62LED60000" # Ford F-250

# Source the correct PID definitions
printf "Sourcing J1979.sh\n"
source ./J1979.sh

# TODO: Add J1939 definitions

# ==========================================================
# Print Information
# ==========================================================
printf  "VIN: $VIN\n"

# ==========================================================
# A Couple Important Things
# ==========================================================

handle_sigint()
{
    # close the fifo and exit
    exec 3>$-
    exit 1
}
trap handle_sigint SIGINT

# ==========================================================
# Bring up interface for DUT to query
# ==========================================================

# TODO: move this to an external file/ clean it up
# Bring up interface
ip a show can0 up 2&>1
CHECK=$?
if [ $CHECK = 0 ]; then
    printf "putting can interface down...\n"
    ip link set can0 down
    printf "deleting can0 interface\n"
    ip link delete can0 
fi

if [ "$MODE" = "physical" ]; then
    printf "Setting up physical CAN interface\n"
    ip link set can0 down
    ip link set can0 type can bitrate 500000 && ip link set can0 up
    if [ $? -eq 0 ]; then
        printf "interface up!\n"
    else
        printf "interface not up :(\n"
        exit -1
    fi
else
    printf "Setting up virtual CAN interface\n"
    modprobe vcan && ip link add dev can0 type vcan loopback on && ip link set can0 up
    if [ $? -eq 0 ]; then
        printf "interface up!\n"
    else
        printf "interface not up :(\n"
        exit -1
    fi
fi

# modprobe vcan || ip link add dev can0 type vcan || 
ifconfig can0 up 2&>1

RET=$?
if [ $RET -eq 0 ]; then
    printf "CAN interface is up!\n"
else
    printf "CAN interface failed to come up :(\n"
    exit -1
fi

# ==========================================================
# Create FIFO and start dumping can frames into it
# ==========================================================
[ -p $CAN_FIFO ] || mkfifo $CAN_FIFO
runCandump()
{
    # candump will fail if the interface is brought down, so just restart it
    exec 3<> "$CAN_FIFO"
    
    until $(candump can0 | tee $CAN_FIFO $CAN_LOGFILE > /dev/null); do
        printf "candump went down, restarting\n"
        sleep 1
        exec 3<> "$CAN_FIFO"
    done

}

runCandump &

# ==========================================================
# Frame Processing Functions
# ==========================================================

getFramePayload()
{
    # Ex. can0  7E8   [8]  00 FF AA 55 01 02 03 04\n
    # Ex. can0  1F334455   [3]  02 01 02\n
    # Ex. can0       7E8   [8]  02 41 55 55 55 55 55 55\n
    # NOTE: it looks like there is equal space between the last character of the address and the 
    #       number of bytes [X]. maybe parse between the interface and the numBytes and strip
    #       whitespace to get the address.

    line=$1
    # parse out address
    ## remove interface

    no_if=${line:$CAN_IFACE_LEN}
    delimiter="["
    payload=${no_if#*$delimiter}
    delimiter_pos=$(( ${#no_if} - ${#payload} - ${#delimiter} ))
    addr=$(echo ${no_if::delimiter_pos})
    payload="${payload:4:2}${payload:7:2}${payload:10:2}${payload:13:2}${payload:16:2}${payload:19:2}${payload:22:2}${payload:25:2}"

    # now that we have removed address, get the 
    echo "$payload" "$addr" # h${line:17:2}${line:20:2}${line:23:2}${line:26:2}${line:29:2}${line:32:2}${line:35:2}${line:38:2}
}

# ==========================================================
# start mainloop
# ==========================================================

while true 
do
    # listen on FIFO and every time there is a line, check the mode and PID
    # if we care about the PID, then respond to it
    # printf "top of line\n"

    # echo $line
    if read -e line; then

        # echo "Frame Received: $line\n"
        read recvdPayload recvdAddr < <(getFramePayload "$line")

        if [ "$recvdAddr" = "$ECU_ADDR" ]; then
            # printf "this frame is from this ECU, continuing\n"
            continue
        fi

        # echo "received payload : \"$recvdPayload\"\n"
        # find the PID in list of supported pids
        # currentFrameType="0x$(echo $recvdPayload | awk '{print substr($0, 1, 2)}')"
        currentFrameType="0x${recvdPayload:0:2}"
        # currentPid="0x$(echo $recvdPayload | awk '{print substr($0, 5, 2)}')"
        currentPid="0x${recvdPayload:4:2}"
        # currentMode="0x$(echo $recvdPayload | awk '{print substr($0, 3, 2)}')"
        currentMode="0x${recvdPayload:2:2}"
        # check Frame type
        ## if this is a flow frame, then we don't really care about the pid or mode
        if [ "$currentFrameType" = "0x30" ]; then
            processFlowFrame $currentFrameType
            # if processed properly, continue sending the multiframe messages
            if [ $? -eq 0 ]; then
                continueMultiFrameMessage
            else
                continue
            fi
        elif [ "$currentMode" = "0x03" ]; then
            processDTCFrame $currentFramePayload
            if [ $? -eq 0 ]; then
                # printf "DTC Frame processed successfully\n"
                :
            else
                continue
            fi
        else
            # check mode
            modeName=$(checkCurrentMode $currentMode)
            # printf "Mode Name: $modeName\n"
            # check PID
            checkCurrentPid $currentPid $modeName
            # if its found then form a response
            if [ $? -eq 0 ]; then
                # printf "Found known PID [$currentPid] on Service [${!currentMode}]. Sending Reply...\n"
                sendSingleFrameResponse $currentMode $currentPid
            else
                # printf "Could not recognize PID\n"
                :
                # continue
            fi
        fi
        # flush fifo 
#         printf "flushing fifo\n"
#         echo "$line\n"
        # line=
    fi
done <"$CAN_FIFO"