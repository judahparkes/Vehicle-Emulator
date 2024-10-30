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
    printf "\tp : (Required) protocol. \"J1939\" or \"J1979\"\n"
}

echo "STarting!"
# PROTOCOL="J1939"
# CAN_IFACE="can0"
# RUN_SCHEDULER=1
while getopts ":m:p:i:d:b:a:v" option; do
   case ${option} in
      i) # can interface name can0, can1, etc
         echo ${OPTARG}
         CAN_IFACE=${OPTARG}
         ;;
      b) # vehicle info file
         echo ${OPTARG}
         VEHICLE_INFO_FILE=${OPTARG}
         ;;
      a) # source address ( J1939 only )
         echo ${OPTARG}
         sourceAddress=${OPTARG}
         ;;
      m) # mode - physical or virtual
         echo ${OPTARG}
         MODE=${OPTARG}
         ;;
      d) # disable broadcast messages
         printf "broadcast messages are disabled\n"
         echo ${OPTARG}
         RUN_SCHEDULER=0
         ;;
      v) # verbose
         echo ${OPTARG}
         VERBOSE=true
         ;;
      p) # protocol
         echo ${OPTARG}
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
   esac
done
echo "done the args!!"

if [ "$RUN_SCHEDULER" = "" ]; then
    printf "broadcast messages are enabled\n"
    RUN_SCHEDULER=1
fi

printf "========================================\n"
printf "Starting Vehicle Emulator in $MODE Mode\n"
printf "========================================\n"

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

printf "========================================\n"
printf "Sourcing $PROTOCOL functions\n"
printf "========================================\n"

# Vehicle Info
source $VEHICLE_INFO_FILE
# VIN="1FT7W2B62LED60000" # Ford F-250

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

# ==========================================================
# A Couple Important Things
# ==========================================================

handle_sigint()
{
    # close the fifos and exit
    exec 3>$-
    exec 4>$-
    exit 1
}
trap handle_sigint SIGINT

# ==========================================================
# Bring up interface for DUT to query
# ==========================================================
# TODO: move this to an external file/ clean it up
# Bring up interface
bringUpCanIface $CAN_IFACE $MODE

# ==========================================================
# Create FIFO and start dumping can frames into it
# ==========================================================
[ -p $CAN_FIFO ] || mkfifo $CAN_FIFO
runCandump()
{
    # candump will fail if the interface is brought down, so just restart it
    exec 3<> "$CAN_FIFO"
    
    until $(candump $CAN_IFACE | tee $CAN_FIFO $CAN_LOGFILE > /dev/null); do
        printf "candump went down, restarting\n"
        sleep 1
        exec 3<> "$CAN_FIFO"
    done

}

runCanSend()
{
    # runCanSend will not actually care about scheduling; rather it will send everything on the
    # queue as fast as it can. It is up to the sender to schedule the sending of the messages

    # may need to send periodically
    # 100ms 10s

    exec 4<> "$SEND_FIFO"

    while true; do
        if read -e line; then
            printf "Sending on queue: $line\n"
            cansend $CAN_IFACE $line
        fi
    done <"$SEND_FIFO"

}

printf "running candump\n"

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

# J1979
while [ "$PROTOCOL" = "J1979" ]
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

        currentFrameType="${recvdPayload:0:2}"
        currentPid="0x${recvdPayload:4:2}"
        currentMode="0x${recvdPayload:2:2}"

        # check Frame type
        ## if this is a flow frame, then we don't really care about the pid or mode
        if [ "$currentFrameType" = "30" ]; then
            processFlowFrame $currentFrameType
            # if processed properly, continue sending the multiframe messages
            if [ $? -eq 0 ]; then
                continueMultiFrameMessage
            else
                continue
            fi
        elif [ "$currentMode" = "0x01" ]; then
            # check mode
            # isSupported=$(checkCurrentMode $currentMode)
            # if [ "$isSupported" = "0" ]; then
            #     continue
            # fi
            # printf "Mode Name: $modeName\n"
            modeName=${MODE_NAME_ARR[$currentMode]}
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
        elif [ "$currentMode" = "0x03" ]; then
            processDTCFrame $currentFramePayload
            if [ $? -eq 0 ]; then
                # printf "DTC Frame processed successfully\n"
                :
            else
                continue
            fi
        fi
        # flush fifo 
#         printf "flushing fifo\n"
#         echo "$line\n"
        # line=
    fi
done <"$CAN_FIFO"

[ -p $SEND_FIFO ] || mkfifo $SEND_FIFO
runCanSend &
# TODO: make sure we kill these processes when we kill the emulator
if [ $RUN_SCHEDULER -eq 1 ]; then
    runScheduler &
fi
# J1939
while [ "$PROTOCOL" = "J1939" ]
do
    # listen on FIFO and every time there is a line, check the PGN, SPN, and SA

    if read -e line; then

        echo "Frame Received: $line\n"
        read recvdPayload recvdAddr < <(getFramePayload "$line")
        echo $recvdAddr
        echo $recvdPayload
        if [ "${recvdAddr:6:2}" = "$sourceAddress" ]; then
            continue
        fi

        # handle requests here
        requestedPgn=${recvdPayload:0:6}
        requestedPgn=0x${requestedPgn:2:2}${requestedPgn:0:2}
        
        # check to see if PGN is supported
        if [ "${recvdAddr:2:2}" = "EA" ]; then
            checkCurrentPgn $requestedPgn
            if [ $? -ne 1 ]; then
                continue
            fi
        else
            printf "Not a request message: $recvdAddr#$recvdPayload\n"
            continue
        fi
        # send response
        # TODO: get pgn above to send to checkcurrentpgn and then use it here
        # to call sendmessage

        sendMessage $requestedPgn

    fi
done <"$CAN_FIFO"