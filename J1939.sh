#!/bin/bash

# SPNs

# 237 - VIN
SPN_VIN="$VIN"

# 244
TRIP_DISTANCE="22220000"
# 245
TOTAL_VEHICLE_DISTANCE="11110000"

SPN_VD="$TRIP_DISTANCE$TOTAL_VEHICLE_DISTANCE"

# PGNs - in hex format with decimal value commented above
# TODO: Add more PGNs here
# TP.CM
PGN_TPCM=0xEC00
# TP.DT
PGN_TPDT=0xEB00
# VI - 65260
PGN_VIN=0xFEEC
PGN_VD=0xFEE0

# PERIODS (MS)
PERIOD_100_MS=100
PERIOD_1_S=1000
PERIOD_10_S=10000

## PID_ARR will contain all of the supported          | Value array will contain the current values                                | Each PID will need its own translation function. 
## PIDs. The PID_ARR number is meaningless            | for each of the supported PIDs.
##### 0x00 #####
PGN_ARR[0]=$PGN_VIN                                   ; VALUE_ARR[$PGN_VIN]=$SPN_VIN                                               ; FUNC_ARR[$PGN_VIN]="getVIN"                      ; BROADCAST_PERIOD[$PGN_VIN]=$PERIOD_10_S
PGN_ARR[1]=$PGN_VD                                    ; VALUE_ARR[$PGN_VD]=$SPN_VD                                                 ; FUNC_ARR[$PGN_VD]="getVD"                        ; BROADCAST_PERIOD[$PGN_VD]=$PERIOD_1_S

# ==========================================================
# J1939-Specific Utility Functions
# ==========================================================

getVD()
{
    echo "$TRIP_DISTANCE$TOTAL_VEHICLE_DISTANCE"
}

getVIN()
{
    # TODO: There are different formats of VIN, but for now
    #       we are assuming those which are 17 characters long
    vinBytes=
    # Convert to ASCII Bytes 
    odOutput=$(echo -n $1 | od -x)
    # remove whitespace
    odOutput=$(echo -e "${odOutput}" | tr -d '[:space:]')
    # now we will have a long line that looks like this: 0000000543734483334543249484953415349560000020004e0000021
    # let's skip 7, then do four characters eight times
    odOutput=$(echo -n "${odOutput}" | cut -c 8-)
    # do next 16 bytes, swapping 
    for i in {1..8}; do
        # get first two, then next two
        a=${odOutput:0:2}
        b=${odOutput:2:2}
        # Swap them and add them to VIN Bytes
        vinBytes="${vinBytes}$b$a"
        # now cut off the first four
        odOutput=$(echo -n "${odOutput}" | cut -c 5-)
    done

    # let's skip 7, then do four characters once 
    odOutput=$(echo -n "${odOutput}" | cut -c 8-)

    # get first two, then next two
    b=${odOutput:2:2}
    # Swap them and add them to VIN Bytes
    vinBytes="${vinBytes}$b"
    echo $vinBytes
}

checkCurrentPgn()
{
    # convert value to little endian
    pgn=$1
    # check if pgn is in value array
    if [ -z ${VALUE_ARR[$pgn]} ]; then
        printf "PGN : $1 is not supported\n"
        return 0
    fi
    val=${VALUE_ARR[$pgn]}
    return 1
}

sendSingleFrame()
{
    numBytes=$1
    currentPgn=$2
    hexVal=$3

    # remove leading 0x
    currentPgn=${currentPgn:2:4}

    canSendMsg="$priority$currentPgn$sourceAddress#$hexVal"

    # printf "$canSendMsg\n"
    # cansend can0 $canSendMsg
    echo $canSendMsg > $SEND_FIFO
}

sendMultiFrame()
{
    # TODO: handle RTS
    numBytes=$1
    currentPgn=$2
    hexVal=$3
    priority="18"

    # printf "Response is $numBytes long, need to send as multiple frames\n"

    # We need the number of packets (not including the BAM)
    numPackets=$(($numBytes/7))
    if [ $(($numBytes % 7)) -gt 0 ]; then
        numPackets=$(($numPackets + 1))
    fi

    numPacketsHex=$(printf "%x" ${numPackets})
    # printf "numPacketsHex: $numPacketsHex\n"
    # add leading 00's
    numPacketsHex="0$numPacketsHex"

    # printf "numPacketsHex: $numPacketsHex\n"

    # get the number of bytes in hex
    numBytesHex="00$(printf "%x" ${numBytes})"
    # printf "numBytesHex: $numBytesHex\n"

    # first frame does not have any payload in it
    # CONNECTION MANAGEMENT PGN: EC00
    # BAM CTRL BYTE: 0x20
    bamByte="20"
    # get big endian of pgn
    # TODO: make a big endian conversion function
    bigEndianPgn="${currentPgn:4:2}${currentPgn:2:2}00"
    bigEndianNumBytes="${numBytesHex:2:2}${numBytesHex:0:2}"
    # 18   EC   <DA>    <SA> $ <CNTRL BYTE> <NUM BYTES (2 Byte)> <NUM PACKETS> FF <PGN (3 Byte)>
    bamMsg="${priority}${PGN_TPCM:2:2}FF${sourceAddress}#${bamByte}${bigEndianNumBytes}${numPacketsHex}FF$bigEndianPgn"
    
    # send the BAM right away, then start a thread for the data transfer messages
    echo $bamMsg > $SEND_FIFO

    # construct the TP.DT messages
    
    # put the payload into groups of 7 bytes. for the last one, pad with 0xFF
    # TODO: add consistent naming here; either "frames" or "packets"
    for(( frameNum=1; frameNum<=numPackets; frameNum++ ))
    do
        sleep 0.05
        dataTransferMsg="${priority}${PGN_TPDT:2:2}FF${sourceAddress}#0${frameNum}${hexVal:0:14}"
        # pop the 14 characters off of the front of the message
        # TODO: handle this properly and add in padding
        hexVal=${hexVal:14:100}
        # printf "TP.DT #$frameNum: $dataTransferMsg\n"
        echo $dataTransferMsg > $SEND_FIFO
    done
}

sendMessage()
{
    currentPgn=$1
    
    # assume consistent priority
    priority="18"
    numBytes=

    # perform transformation to value, convert the value to hex, switch to big endian, then count characters
    funcArrName=FUNC_ARR
    declare -n funcArr=$funcArrName
    func=${funcArr[$currentPgn]}

    valueArrName=VALUE_ARR
    declare -n valueArr=$valueArrName
    # printf "func: $func\n"
    # printf "val: ${valueArr[$currentPgn]}\n"
    tmpVal=$($func ${valueArr[$currentPgn]})

    # printf "tmpVal: $tmpVal\n"
    hexVal=$tmpVal
    msgLen=${#hexVal}
    remainder=$(($msgLen % 2))
    numBytes="$((($msgLen / 2) + $remainder))"

    # if the message is more than 8 Bytes, then we need to send
    # as a multi-frame message
    if [ $numBytes -gt 8 ]; then
        sendMultiFrame $numBytes $currentPgn $hexVal &
    else
        sendSingleFrame $numBytes $currentPgn $hexVal
    fi
}

runScheduler()
{
    # The purpose of this function is to schedule the sending of each value
    # perhaps we can have a 100ms queue, 1s queue, etc.
    # or perhaps we can have a list of items that need to be broadcast, and another with their time in ms

    oneHundredMsTime=$(date +%s%3N)
    oneSecondTime=$oneHundredMsTime
    tenSecondTime=$oneHundredMsTime
    startTime=$oneHundredMsTime

    # broadcast period arrays
    declare -n BROADCAST_ARR_100_MS
    declare -n BROADCAST_ARR_1_S
    declare -n BROADCAST_ARR_10_S

    for pgn in "${PGN_ARR[@]}"
    do
        printf "$pgn\n"
        if [ "${BROADCAST_PERIOD[$pgn]}" = "$PERIOD_100_MS" ]; then
            printf "Adding $pgn to 100ms set\n"
            BROADCAST_ARR_100_MS+=("$pgn")
        elif [ "${BROADCAST_PERIOD[$pgn]}" = "$PERIOD_1_S" ]; then
            printf "Adding $pgn to 1s set\n"
            BROADCAST_ARR_1_S+=("$pgn")
        elif [ "${BROADCAST_PERIOD[$pgn]}" = "$PERIOD_10_S" ]; then
            printf "Adding $pgn to 10s set\n"
            BROADCAST_ARR_10_S+=("$pgn")
        fi
    done

    currentTime=
    while true; do
        # get the current time
        currentTime=$(date +%s%3N)

        # after 100ms, send the 100ms itmes
        if [ "$(($currentTime - $oneHundredMsTime))" -gt "100"  ]; then
            # add items to queue
            # printf "Sending 100ms items!\n"
            for pgn in "${BROADCAST_ARR_100_MS[@]}"
            do
                sendMessage $pgn
            done
            # reset the time
            oneHundredMsTime=$currentTime
        fi
        # after 1s, send the 1s items
        if [ "$(($currentTime - $oneSecondTime))" -gt "1000"  ]; then
            # add items to queue
            # printf "Sending 1s items!\n"
            for pgn in "${BROADCAST_ARR_1_S[@]}"
            do
                sendMessage $pgn
            done
            # reset the time
            oneSecondTime=$currentTime
        fi
        # after 10s, send the 10s items
        if [ "$(($currentTime - $tenSecondTime))" -gt "10000"  ]; then
            # add items to queue
            # printf "Sending 10s items!\n"
            for pgn in "${BROADCAST_ARR_10_S[@]}"
            do
                sendMessage $pgn
            done
            # reset the time
            tenSecondTime=$currentTime
            # if one minute has passed, then remove VIN from the array
            # printf "Time since start: $(($currentTime - $startTime))\n"
            if [ "$(($currentTime - $startTime))" -gt "20000" ]; then
                # Remove VIN
                # printf "checking ${BROADCAST_ARR_10_S[index]}\n"
                for index in "${!BROADCAST_ARR_10_S[@]}"; do
                    # printf "we have ${index} with ${BROADCAST_ARR_10_S[index]}\n"
                    if [ "${BROADCAST_ARR_10_S[index]}" = "$PGN_VIN" ]; then
                        # printf "No longer broacasting VIN\n"
                        unset BROADCAST_ARR_10_S[index]
                    fi
                done
            fi

        fi
    done
}

# ==========================================================
# Data Translation Functions
# ==========================================================
# These Functions need to do a few things:
#     - Convert the predefined value (See definitions above)
#       into the correct hex value
#     - Return the correct data in a string that is the correct
#       number of bytes.
getVin()
{
    # TODO: There are different formats of VIN, but for now
    #       we are assuming those which are 17 characters long
    # TODO: Make this big endian
    vinBytes=
    # Convert to ASCII Bytes 
    odOutput=$(echo -n $1 | od -x)
    # remove whitespace
    odOutput=$(echo -e "${odOutput}" | tr -d '[:space:]')
    # now we will have a long line that looks like this: 0000000543734483334543249484953415349560000020004e0000021
    # let's skip 7, then do four characters eight times
    odOutput=$(echo -n "${odOutput}" | cut -c 8-)
    # do next 16 bytes, swapping 
    for i in {1..8}; do
        # get first two, then next two
        a=${odOutput:0:2}
        b=${odOutput:2:2}
        # Swap them and add them to VIN Bytes
        vinBytes="${vinBytes}$b$a"
        # now cut off the first four
        odOutput=$(echo -n "${odOutput}" | cut -c 5-)
    done

    # let's skip 7, then do four characters once 
    odOutput=$(echo -n "${odOutput}" | cut -c 8-)

    # get first two, then next two
    b=${odOutput:2:2}
    # Swap them and add them to VIN Bytes
    vinBytes="${vinBytes}$b"
    echo $vinBytes
}

runJ1939Mainloop()
{
    [ -p $SEND_FIFO ] || mkfifo $SEND_FIFO
    runCanSend &
    # TODO: make sure we kill these processes when we kill the emulator
    if [ $RUN_SCHEDULER -eq 1 ]; then
        runScheduler &
    fi
    # J1939
    while [ "$PROTOCOL" = "J1939" ]
    do
        if read -e line; then

            # echo "Frame Received: $line\n"
            read recvdPayload recvdAddr < <(getFramePayload "$line")
            # echo $recvdAddr
            # echo $recvdPayload
            if [ "${recvdAddr:6:2}" = "$sourceAddress" ]; then
                continue
            fi

            # handle requests here
            requestedPgn=${recvdPayload:0:6}
            requestedPgn=0x${requestedPgn:2:2}${requestedPgn:0:2}
        
            # check to see if PGN is supported
            # TODO: Right now we are only listening for request messages
            if [ "${recvdAddr:2:2}" = "EA" ]; then
                checkCurrentPgn $requestedPgn
                if [ $? -ne 1 ]; then
                    continue
                fi
            else
                continue
            fi
            sendMessage $requestedPgn
        fi
    done <"$CAN_FIFO"
}