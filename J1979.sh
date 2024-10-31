
ECU_ADDR="7E8"

# TODO: find a way to make some of these values variable during execution
# PID 0x00
SUPPORTED_PIDS_0=0x08180003
ENG_COOLANT_TEMP=75 # Degrees celsius
ENG_SPEED=2000 # RPM
VEHICLE_SPEED=40 # Km/h
RUNTIME_SINCE_START=3600 # seconds
# PID 0x20
SUPPORTED_PIDS_1=0x00008001 
DISTANCE_SINCE_CODES_CLEARED=200 # km
# PID 0x40
SUPPORTED_PIDS_2=0x00000001 # only PIDs [61 - 80] at this point
# PID 0x60
SUPPORTED_PIDS_3=0x00000001 # only PIDs [81 - A0] at this point
# PID 0x80
SUPPORTED_PIDS_4=0x00000001 # only PIDS [A1 - C0] at this point
# PID 0xA0
SUPPORTED_PIDS_5=0x04000000 # only odometer at this point

ODOMETER=238359 # 123,456 
# Modes
MODE_CURRENT_DATA=0x01
MODE_VEHICLE_INFO=0x09

# Mode Array
MODE_ARR[0]=$MODE_CURRENT_DATA ; MODE_NAME_ARR[$MODE_CURRENT_DATA]="MODE_CURRENT_DATA"
MODE_ARR[8]=$MODE_VEHICLE_INFO ; MODE_NAME_ARR[$MODE_VEHICLE_INFO]="MODE_VEHICLE_INFO"

# PIDs
## CURRENT DATA
###
### |       A       |       B       |       C       |       D       |
###  0 0 0 0 1 0 0 0 0 0 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1
###        0 8             1 8             0 0             0 3
###
PID_SUPPORTED_PIDS_0=0x00 # this needs to be updated as more PIDS are added
PID_ENG_COOLANT_TEMP=0x05 # Degrees Celsius
PID_ENG_SPEED=0x0C # RPM
PID_VEHICLE_SPEED=0x0D # Km/h
PID_RUNTIME_SINCE_START=0x1F # Seconds

### |       A       |       B       |       C       |       D       |
### |0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|1 0 0 0|0 0 0 0|0 0 0 0|0 0 0 1|
###        0 0             0 0             8 0             0 1
###
PID_SUPPORTED_PIDS_1=0x20 # this needs to be updated as more PIDS are added
PID_DSCC=0x31

### |       A       |       B       |       C       |       D       |
### |0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 1|
###        0 0             0 0             0 0             0 1
###
PID_SUPPORTED_PIDS_2=0x40 # this needs to be updated as more PIDS are added

### |       A       |       B       |       C       |       D       |
### |0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 1|
###        0 0             0 0             0 0             0 1
###
PID_SUPPORTED_PIDS_3=0x60 # this needs to be updated as more PIDS are added

### |       A       |       B       |       C       |       D       |
### |0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|
###        0 0             0 0             0 0             0 0
###
PID_SUPPORTED_PIDS_4=0x80 # this needs to be updated as more PIDS are added

### |       A       |       B       |       C       |       D       |
### |0 0 0 0|0 1 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|
###        0 4             0 0             0 0             0 0
###
PID_SUPPORTED_PIDS_5=0xA0 # this needs to be updated as more PIDS are added

PID_ODOMETER=0xA6

### |       A       |       B       |       C       |       D       |
### |0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|0 0 0 0|
PID_SUPPORTED_PIDS_6=0xC0 # this needs to be updated as more PIDS are added

## PID_ARR will contain all of the supported          | Value array will contain the current values                                | Each PID will need its own translation function. 
## PIDs. The PID_ARR number is meaningless            | for each of the supported PIDs.
##### 0x00 #####
PID_ARR_MODE_CURRENT_DATA[0]=$PID_SUPPORTED_PIDS_0    ; VALUE_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_0]=$SUPPORTED_PIDS_0       ; FUNC_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_0]="getSupportedPids"
PID_ARR_MODE_CURRENT_DATA[1]=$PID_ENG_COOLANT_TEMP    ; VALUE_ARR_MODE_CURRENT_DATA[$PID_ENG_COOLANT_TEMP]=$ENG_COOLANT_TEMP       ; FUNC_ARR_MODE_CURRENT_DATA[$PID_ENG_COOLANT_TEMP]="getEngineCoolantTemp"
PID_ARR_MODE_CURRENT_DATA[2]=$PID_ENG_SPEED           ; VALUE_ARR_MODE_CURRENT_DATA[$PID_ENG_SPEED]=$ENG_SPEED                     ; FUNC_ARR_MODE_CURRENT_DATA[$PID_ENG_SPEED]="getEngineSpeed"
PID_ARR_MODE_CURRENT_DATA[3]=$PID_VEHICLE_SPEED       ; VALUE_ARR_MODE_CURRENT_DATA[$PID_VEHICLE_SPEED]=$VEHICLE_SPEED             ; FUNC_ARR_MODE_CURRENT_DATA[$PID_VEHICLE_SPEED]="getVehicleSpeed"
PID_ARR_MODE_CURRENT_DATA[4]=$PID_RUNTIME_SINCE_START ; VALUE_ARR_MODE_CURRENT_DATA[$PID_RUNTIME_SINCE_START]=$RUNTIME_SINCE_START ; FUNC_ARR_MODE_CURRENT_DATA[$PID_RUNTIME_SINCE_START]="getRuntimeSinceEngineStart"
##### 0x20 #####
PID_ARR_MODE_CURRENT_DATA[32]=$PID_SUPPORTED_PIDS_1   ; VALUE_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_1]=$SUPPORTED_PIDS_1       ; FUNC_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_1]="getSupportedPids"
PID_ARR_MODE_CURRENT_DATA[49]=$PID_DSCC               ; VALUE_ARR_MODE_CURRENT_DATA[$PID_DSCC]=$DISTANCE_SINCE_CODES_CLEARED       ; FUNC_ARR_MODE_CURRENT_DATA[$PID_DSCC]="getDscc"
##### 0x40 #####
PID_ARR_MODE_CURRENT_DATA[64]=$PID_SUPPORTED_PIDS_2 ; VALUE_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_2]=$SUPPORTED_PIDS_2 ; FUNC_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_2]="getSupportedPids"
##### 0x60 #####
PID_ARR_MODE_CURRENT_DATA[96]=$PID_SUPPORTED_PIDS_3 ; VALUE_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_3]=$SUPPORTED_PIDS_3 ; FUNC_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_3]="getSupportedPids"
##### 0x80 #####
PID_ARR_MODE_CURRENT_DATA[128]=$PID_SUPPORTED_PIDS_4 ; VALUE_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_4]=$SUPPORTED_PIDS_4 ; FUNC_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_4]="getSupportedPids"
##### 0xA0 #####
PID_ARR_MODE_CURRENT_DATA[164]=$PID_SUPPORTED_PIDS_5 ; VALUE_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_5]=$SUPPORTED_PIDS_5 ; FUNC_ARR_MODE_CURRENT_DATA[$PID_SUPPORTED_PIDS_5]="getSupportedPids"

PID_ARR_MODE_CURRENT_DATA[170]=$PID_ODOMETER   ; VALUE_ARR_MODE_CURRENT_DATA[$PID_ODOMETER]=$ODOMETER ; FUNC_ARR_MODE_CURRENT_DATA[$PID_ODOMETER]="getOdometerPayload"
##### 0xC0 #####

## VEHICLE INFO
PID_VIN=0x02

PID_ARR_MODE_VEHICLE_INFO[0]=$PID_VIN        ; VALUE_ARR_MODE_VEHICLE_INFO[$PID_VIN]=$VIN           ; FUNC_ARR_MODE_VEHICLE_INFO[$PID_VIN]="getVin"

# ==========================================================
# Data Translation Functions
# ==========================================================
# These Functions need to do a few things:
#     - Convert the predefined value (See definitions above)
#       into the correct hex value
#     - Return the correct data in a string that is the correct
#       number of bytes.

getEngineCoolantTemp()
{
    # should be 1 byte
    # A - 40 = temp  --> A = temp + 40
    hexVal=$(printf "%X" $(($1 + 40)))
    echo $hexVal
}

getEngineSpeed()
{
    # 2 bytes
    # (256A + B) / 4 = engine speed   --> ((engine speed)*4 = A<<8 + B
    hexVal=$(printf "%X" $((($1*4))))
    echo $hexVal
}

getVehicleSpeed()
{
    # 1 byte
    # A (no change)
    hexVal=$(printf "%X" $1)
    echo $hexVal
}

getRuntimeSinceEngineStart()
{
    # 2 bytes
    # 256A + B
    hexVal=$(printf "%X" $1)
    echo $hexVal
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

getDscc()
{
    # 2 bytes
    numBytes=2
    # 256A + B
    hexVal=$(printf "%X" $1)
    # pad with leading zeros
    if [ ${#hexVal} -ne 4 ]; then
        hexVal=$(padLeadingZeroes $hexVal 2)
    fi
    echo $hexVal
}

getSupportedPids()
{
    # this is going to be 4 bytes of hex, so just remove the leading '0x'
    payload=$1
    echo ${payload:2:8}
}

getOdometerPayload()
{
    # 4 bytes
    # conver the odometer value to the correct format
    # 10*ODOMETER -> hex
    hexVal=$(printf "%X" $(($1*10)))
    # length should be 8
    if [ ${#hexVal} -ne 8 ]; then
        hexVal=$(padLeadingZeroes $hexVal 4)
    fi
    echo $hexVal
}

getVin()
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
    trimmedPid=${currentPid:2:2}
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

        # now we need to change the numBytes to inclue the PID and the service ( +2 )
        numBytes=$(($numBytes + 2))
        canSendMsg="$ECU_ADDR#$outgoingFrameType$numBytes$serviceValue$trimmedPid$hexVal"
    fi

    # printf "Msg: $canSendMsg\n"
    cansend $CAN_IFACE $canSendMsg
}

runJ1979Mainloop()
{
    # J1979
    while [ "$PROTOCOL" = "J1979" ]
    do
        # listen on FIFO and every time there is a line, check the mode and PID
        # if we care about the PID, then respond to it

        if read -e line; then
            # echo "Frame Received: $line\n"
            read recvdPayload recvdAddr < <(getFramePayload "$line")

            if [ "$recvdAddr" = "$ECU_ADDR" ]; then
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
            elif [ "$currentMode" = "0x01" ] || [ "$currentMode" = "0x09" ]; then
                # check mode
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
                    :
                else
                    continue
                fi
            fi
        fi
    done <"$CAN_FIFO"
}
