
ECU_ADDR="7E8"
SUPPORTED_PIDS_0=0x80000000

# Modes
MODE_CURRENT_DATA=0x22

# Mode Array
MODE_ARR[22]=$MODE_CURRENT_DATA  ; MODE_NAME_ARR[$MODE_CURRENT_DATA]="MODE_CURRENT_DATA"

## DID ##
## 0xF4 00 ##
PID_SUPPORTED_PIDS_0=0xF400
PID_IM_READINESS=0xF401
##
## 0xF8 00 ##
PID_PROTOCOL=0xFE10
PID_ARR_MODE_CURRENT_DATA[0]=$PID_SUPPORTED_PIDS_0    ; VALUE_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_0]=$SUPPORTED_PIDS_0       ; FUNC_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_0]="getSupportedPids"
PID_ARR_MODE_CURRENT_DATA[1000]=$PID_PROTOCOL ; VALUE_ARR_MODE_CURRENT_DATA[$PID_PROTOCOL]=0x1                ; FUNC_ARR_MODE_CURRENT_DATA[$PID_PROTOCOL]="getOBDonUDSProtocol"
PID_ARR_MODE_CURRENT_DATA[1001]=$PID_IM_READINESS ; VALUE_ARR_MODE_CURRENT_DATA[$PID_IM_READINESS]=0x8100FF00 ; FUNC_ARR_MODE_CURRENT_DATA[$PID_IM_READINESS]="getIMReadiness"

# ==========================================================
# Data Translation Functions
# ==========================================================
# These Functions need to do a few things:
#     - Convert the predefined value (See definitions above)
#       into the correct hex value
#     - Return the correct data in a string that is the correct
#       number of bytes.

getSupportedPids()
{
    # this is going to be 4 bytes of hex, so just remove the leading '0x'
    payload=$1
    echo ${payload:2:8}
}

getIMReadiness()
{
    echo "8100FF00"
}

getOBDonUDSProtocol()
{
    echo "01"
}

padLeadingZeroes()
{
    hexVal=$1
    numBytes=$2

    for((i=0; i<=$(($((numBytes*2)) - ${#hexVal})); i++))
    do
        hexVal="0${hexVal}"
    done
    echo $hexVal
}
checkCurrentMode()
{
        # check mode
        currentMode=$1
        if [ -v "MODE_ARR[$currentMode]" ]; then
            return 1
        fi
        return 0
}

checkCurrentPid()
{
    # check PID
    currentPid=$1
    currentMode=$2
    # if PID_ARR_$currentMode[$currentPid] is blank
    declare -n func=VALUE_ARR_${currentMode}
    func1=${func[$currentPid]}
    if [ "" = "$func1" ]; then
        return 1
    fi
    return 0
}

processDTCFrame()
{
    # TODO: we need to send back the DTCs, but right now there are none
    cansend $CAN_IFACE $ECU_ADDR#0443000055555555
    return 0
}

processFlowFrame()
{
    # TODO: we will need to parse this properly and use information
    #       determined here when responding with multi-frame messages,
    #       but for now we can just say okay
    if [ $IN_MULTIFRAME -eq 1 ]; then
        return 0
    else
        return -1
    fi
}

continueMultiFrameMessage()
{
    # TODO: make this a little more intelligent by abiding by the controls given in the flow frame
    # check how many bytes we have left. We will send 7 at a time, so determine how many frames we have left to send
    multiframeSize=${#MULTIFRAME_PAYLOAD}
    remainderBytes=$(($multiframeSize % 14))
    remainderFrames=$(($multiframeSize / 14))
    
    if [ $remainderBytes -ne 0 ]; then
        remainderFrames=$(($remainderFrames + 1))
    fi

    for(( frameNum=1; frameNum<$(($remainderFrames + 1)); frameNum++ ))
    do
        frameType=$CONSECUTIVE_FRAME
        firstByte="${frameType}${frameNum}"

        # if we have more than 14 characters left, then we will do a full frame, otherwise we do partial
        if [ ${#MULTIFRAME_PAYLOAD} -gt 14 ]; then
            currentFramePayload=${MULTIFRAME_PAYLOAD:0:14}

            # next seven bytes will be from the payload global variable
            canSendMsg="$ECU_ADDR#${firstByte}${currentFramePayload}"

            # trim multiframe message by the amount that we took
            MULTIFRAME_PAYLOAD=$(echo -n "${MULTIFRAME_PAYLOAD}" | cut -c 15-)
            # printf "Sending consecutive frame: $canSendMsg\n"
            cansend $CAN_IFACE $canSendMsg
        else
            remainingPayload=${#MULTIFRAME_PAYLOAD} 
            currentFramePayload=$MULTIFRAME_PAYLOAD
            # Add in 0x55 to the end of the message if necessary
            # msg will be 3 Bytes + numBytes
            padNum=$((8 - 1 - $(($remainingPayload / 2))))
            for(( i=0; i<$padNum; i++ )); do
                currentFramePayload="${currentFramePayload}55"
            done
            canSendMsg="$ECU_ADDR#${firstByte}${currentFramePayload}"
            cansend $CAN_IFACE $canSendMsg
        fi
    done
}

sendSingleFrameResponse()
{
    # TODO: This function actually handles multiframe responses; split it up in two
    # TODO: things like odometer, which are 4 bytes, need to have leading zeroes
    currentMode=$1
    currentPid=$2
    numBytes=
    serviceValue=$(printf "%x" $(($currentMode + 0x40)))
    # perform transformation to value, convert the value to hex, then count characters
    funcArrName=FUNC_ARR_$currentMode
    declare -n funcArr=$funcArrName
    func=${funcArr[$currentPid]}
    valueArrName=VALUE_ARR_$currentMode
    declare -n valueArr=$valueArrName
    tmpVal=$($func ${valueArr[$currentPid]})

    hexVal=$tmpVal
    msgLen=${#hexVal}
    remainder=$(($msgLen % 2))
    numBytes="$((($msgLen / 2) + $remainder))"

    # Assume this is a Single Frame
    outgoingFrameType=0

    # trimmedPid=$(echo "$currentPid" | cut -c 3-)
    trimmedPid=${currentPid:2:4}
    # Add leading zeroes if necessary
    if [ $remainder -eq 1 ]; then
        hexVal="0${hexVal}"
    fi
    
    # if the message is more than 4 Bytes, then we need to send
    # as a multi-frame message :)
    if [ $numBytes -gt 5 ]; then
        printf "Response is $numBytes long, need to send as multiple frames"
        # since we have a multiframe message, we need to add a few extra metadata items
        numBytes=$((numBytes + 3))
        numBytesHex=$(printf "%x" ${numBytes})
        numItems="01"

        # mark the start of multiframe message. We will send the first frame, then wait
        # for a flow frame before continuing
        IN_MULTIFRAME=1

        # Make this a first frame
        outgoingFrameType=10

        # 10    14    49     < payload >
        hexVal=${hexVal:0:6}
        canSendMsg="$ECU_ADDR#$outgoingFrameType$numBytesHex$serviceValue$trimmedPid$numItems$hexVal"
        MULTIFRAME_PAYLOAD=$(echo -n "${tmpVal}" | cut -c 7-)

    else
        # NOTE: It takes too much time to pad with 0x55 here, removing for now
        # Add in 0x55 to the end of the message if necessary
        # msg will be 3 Bytes + numBytes
        # time1="$(date +%3N)"
        # for i in $(seq 0 $((8 - 3 - $numBytes)))
        # do
        #     hexVal="${hexVal}55"
        # done
        # time2="$(date +%3N)"
        # printf "$(($time2 - $time1))\n"

        # now we need to change the numBytes to inclue the PID and the service ( +3 )
        numBytes=$(($numBytes + 3))
        canSendMsg="$ECU_ADDR#$outgoingFrameType$numBytes$serviceValue$trimmedPid$hexVal"
    fi

    # printf "Msg: $canSendMsg\n"
    cansend $CAN_IFACE $canSendMsg
}

runJ19792Mainloop()
{
    # J1979
    while [ "$PROTOCOL" = "J19792" ]
    do
        # source the database
        source values.sh

        # listen on FIFO and every time there is a line, check the mode and PID
        # if we care about the PID, then respond to it

        if read -e line; then
            # echo "Frame Received: $line\n"
            read recvdPayload recvdAddr < <(getFramePayload "$line")

            if [ "$recvdAddr" = "$ECU_ADDR" ]; then
                continue
            fi

            currentFrameType="${recvdPayload:0:2}"
            currentDid="0x${recvdPayload:4:4}"
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
            elif [ "$currentMode" = "0x22" ]; then
                # check mode
                modeName=${MODE_NAME_ARR[$currentMode]}
                # check PID
                checkCurrentPid $currentDid $modeName
                # if its found then form a response
                if [ $? -eq 0 ]; then
                    # printf "Found known PID [$currentPid] on Service [${!currentMode}]. Sending Reply...\n"
                    sendSingleFrameResponse $currentMode $currentDid
                else
                    # printf "Could not recognize PID\n"
                    :
                    # continue
                fi
            elif [ "$currentMode" = "0x03" ]; then
                processDTCFrame $currentFramePayload
                if [ $? -eq 0 ]; then
                    :
                else
                    continue
                fi
            fi
        fi
    done <"$CAN_FIFO"
}
