#!/bin/bash

printf "Starting Vehicle Emulator...\n"

# ==========================================================
# GLOBALS
# ==========================================================

# can msg FIFO
CAN_FIFO="/tmp/can_fifo"

# Multi-Frame Messages
IN_MULTIFRAME=0
MULTIFRAME_PAYLOAD=

# Frame Types
SINGLE_FRAME=0
FIRST_FRAME=1
CONSECUTIVE_FRAME=2
FLOW_FRAME=3

# ==========================================================
# Definitions
# ==========================================================

# Vehicle Info
VIN="ABC1234THISISAVIN"

# PID 0x00
SUPPORTED_PIDS_0=0x08180003 # only odometer at this point
ENG_COOLANT_TEMP=75 # Degrees celsius
ENG_SPEED=2000 # RPM
VEHICLE_SPEED=40 # Km/h
RUNTIME_SINCE_START=3600 # seconds
# PID 0x20
SUPPORTED_PIDS_1=0x00008001
DISTANCE_SINCE_CODES_CLEARED=200 # km
# PID 0x40
SUPPORTED_PIDS_2=0x00000001 # only odometer at this point
# PID 0x60
SUPPORTED_PIDS_3=0x00000001 # only odometer at this point
# PID 0x80
SUPPORTED_PIDS_4=0x00000001 # only odometer at this point
# PID 0xA0
SUPPORTED_PIDS_5=0x04000000 # only odometer at this point
ODOMETER=299999 # 299,999
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
###  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
###        0 0             0 0             8 0             0 1
###
PID_SUPPORTED_PIDS_1=0x20 # this needs to be updated as more PIDS are added
PID_DSCC=0x31

### |       A       |       B       |       C       |       D       |
###  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
###        0 0             0 0             0 0             0 1
###
PID_SUPPORTED_PIDS_2=0x40 # this needs to be updated as more PIDS are added

### |       A       |       B       |       C       |       D       |
###  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1
###        0 0             0 0             0 0             0 1
###
PID_SUPPORTED_PIDS_3=0x60 # this needs to be updated as more PIDS are added

### |       A       |       B       |       C       |       D       |
###  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
###        0 0             0 0             0 0             0 0
###
PID_SUPPORTED_PIDS_4=0x80 # this needs to be updated as more PIDS are added

### |       A       |       B       |       C       |       D       |
###  0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
###        0 4             0 0             0 0             0 0
###
PID_SUPPORTED_PIDS_5=0xA0 # this needs to be updated as more PIDS are added

PID_ODOMETER=0xA6

### |       A       |       B       |       C       |       D       |
###  0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
PID_SUPPORTED_PIDS_6=0xC0 # this needs to be updated as more PIDS are added
PID_DUMMY=0xFF

## PID_ARR will contain all of the supported | Value array will contain the current values 
## PIDs. The PID_ARR number is meaningless   | for each of the supported PIDs.
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
PID_ARR_MODE_CURRENT_DATA[200]=$PID_DUMMY      ; VALUE_ARR_MODE_CURRENT_DATA[$PID_DUMMY]=0xFFFFFFFF   ; FUNC_ARR_MODE_CURRENT_DATA[$PID_DUMMY]="getDummyVal"

## VEHICLE INFO
PID_VIN=0x02

PID_ARR_MODE_VEHICLE_INFO[0]=$PID_VIN        ; VALUE_ARR_MODE_VEHICLE_INFO[$PID_VIN]=$VIN           ; FUNC_ARR_MODE_VEHICLE_INFO[$PID_VIN]="getVin"


printf "MODE Indices: ${!MODE_ARR[*]}\n"
printf "PID Indices: ${!PID_ARR_MODE_CURRENT_DATA[*]}\n"

# ==========================================================
# Print Information
# ==========================================================
printf  "VIN: $VIN\n"

# ==========================================================
# Bring up interface for DUT to query
# ==========================================================

# Bring up interface
ip a show can0 up 2&>1
CHECK=$?
if [ $CHECK = 0 ]; then
    printf "putting can interface down...\n"
    ifconfig can0 down 2&>1
fi

modprobe vcan || ip link add dev can0 type vcan || ifconfig can0 up 2&>1

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
    
    until $(candump can0 > $CAN_FIFO); do
        printf "candump went down, restarting\n"
        sleep 1
        exec 3<> "$CAN_FIFO"
    done

}

runCandump &

# ==========================================================
# Data Translation Functions
# ==========================================================

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

getDscc()
{
    # 2 bytes
    # 256A + B
    hexVal=$(printf "%X" $1)
    echo $hexVal
}
getSupportedPids()
{
    # this is going to be 4 bytes of hex, so just remove the leading '0x'
    echo $(echo -n $1 | cut -c 3-)
}
getOdometerPayload()
{
    # conver the odometer value to the correct format
    # 10*ODOMETER -> hex
    hexVal=$(printf "%X" $(($1*10)))
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

# ==========================================================
# Frame Processing Functions
# ==========================================================

getFramePayload()
{
    # TODO: we should really have a better way of parsing this.
    # look at the id and the data and determine whether or not we
    # want to keep this info
    line=$1
    # Ex. can0  7E8   [8]  00 FF AA 55 01 02 03 04\n
    dataStr=$(echo $line | awk '{print substr($0, 14, 28)}' | tr -d '[:space:]')
    echo "$dataStr"
}

checkCurrentMode()
{
        # check mode
        currentMode=$1
        for mode in ${MODE_ARR[*]}
        do
            # printf "Current Mode: $currentMode, MODE_ARR: $mode\n"
            if [ "$mode" = "$currentMode" ]; then
                # we found a match
                # leave the loop
                # printf "Match Found! Mode $currentMode\n"
                tmpName=${MODE_NAME_ARR[$mode]}
                echo ${tmpName}
                return 0 
            fi
        done

        # we did not find a recognizable mode
        return 1
}

checkCurrentPid()
{
        # check PID
        currentPid=$1
        currentMode=$2
        var=PID_ARR_$currentMode[@]
        for pid in ${!var}
        do
            if [ "$pid" = "$currentPid" ]; then
                # we found a match
                # leave the loop
                # printf "Match Found! PID $currentPid, current value ${VALUE_ARR[$currentPid]}\n"
                return 0 
            fi
        done

        # We did not find a recognizable PID
        return 1
}

processFlowFrame()
{
    # process the flow frame. Going to be pretty simple for now
    # TODO: we will need to parse this properly and use information
    #       determined here when responding with multi-frame messages,
    #       but for now we can just say okay
    printf "Flow Frame processed!\n"
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
    # printf "multiframe_payload: $MULTIFRAME_PAYLOAD\n"
    multiframeSize=${#MULTIFRAME_PAYLOAD}
    # printf "multiframeSize: $multiframeSize\n"
    remainderBytes=$(($multiframeSize % 14))
    remainderFrames=$(($multiframeSize / 14))
    # printf "We are going to send $remainderFrames full frames\n"
    
    if [ $remainderBytes -ne 0 ]; then
        remainderFrames=$(($remainderFrames + 1))
    fi

    for(( frameNum=0; frameNum<${remainderFrames}; frameNum++))
    do
        frameType=$CONSECUTIVE_FRAME
        firstByte="${frameType}${frameNum}"

        # if we have more than 14 characters left, then we will do a full frame, otherwise we do partial
        if [ ${#MULTIFRAME_PAYLOAD} -gt 14 ]; then
            currentFramePayload=${MULTIFRAME_PAYLOAD:0:14}

            # next seven bytes will be from the payload global variable
            canSendMsg="7E8#${firstByte}${currentFramePayload}"

            # trim multiframe message by the amount that we took
            MULTIFRAME_PAYLOAD=$(echo -n "${MULTIFRAME_PAYLOAD}" | cut -c 15-)
            printf "Sending consecutive frame: $canSendMsg\n"
            cansend can0 $canSendMsg

            # flush fifo 
            read line <$CAN_FIFO

        else
            remainingPayload=${#MULTIFRAME_PAYLOAD} 
            currentFramePayload=$MULTIFRAME_PAYLOAD
            # Add in 0x55 to the end of the message if necessary
            # msg will be 3 Bytes + numBytes
            padNum=$((8 - 1 - $(($remainingPayload / 2))))
            for(( i=0; i<$padNum; i++ )); do
                currentFramePayload="${currentFramePayload}55"
            done
            canSendMsg="7E8#${firstByte}${currentFramePayload}"
            printf "Sending consecutive frame: $canSendMsg\n"
            cansend can0 $canSendMsg
            # flush fifo 
            read line <$CAN_FIFO
        fi

    done
    
    
}

sendSingleFrameResponse()
{
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
    # printf "value before transformation: ${valueArr[$currentPid]}\n"
    # printf "function call: $func ${valueArr[$currentPid]}\n"
    $func ${valueArr[$currentPid]}
    tmpVal=$($func ${valueArr[$currentPid]})
    # printf "value after transformation: $tmpVal\n"

    hexVal=$tmpVal
    msgLen=${#hexVal}
    remainder=$(($msgLen % 2))
    numBytes="$((($msgLen / 2) + $remainder))"
    # printf "numBytes: $numBytes\n"

    # Assume this is a Single Frame
    outgoingFrameType=0

    trimmedPid=$(echo "$currentPid" | cut -c 3-)
    # Add leading zeroes if necessary
    if [ $remainder -eq 1 ]; then
        hexVal="0${hexVal}"
    fi
    
    # if the message is more than 4 Bytes, then we need to send
    # as a multi-frame message :)
    if [ $numBytes -gt 5 ]; then
        printf "Response is $numBytes long, need to send as multiple frames"

        # mark the start of multiframe message. We will send the first frame, then wait
        # for a flow frame before continuing
        IN_MULTIFRAME=1

        # Make this a first frame
        outgoingFrameType=10

        # 10    14    < payload >
        hexVal=${hexVal:0:12}
        # printf "Payload for VIN : ${hexVal}\n"
        canSendMsg="7E8#$outgoingFrameType$numBytes$hexVal"
        MULTIFRAME_PAYLOAD=$(echo -n "${tmpVal}" | cut -c 13-)
        # printf "after first send : $MULTIFRAME_PAYLOAD\n" 

    else
        # Add in 0x55 to the end of the message if necessary
        # msg will be 3 Bytes + numBytes
        for i in $(seq 0 $((8 - 3 - $numBytes)))
        do
            hexVal="${hexVal}55"
        done

        # now we need to change the numBytes to inclue the PID and the service ( +2 )
        numBytes=$(($numBytes + 2))
        canSendMsg="7E8#$outgoingFrameType$numBytes$serviceValue$trimmedPid$hexVal"
    fi

    printf "Msg: $canSendMsg\n"
    cansend can0 $canSendMsg
}

# ==========================================================
# start mainloop
# ==========================================================

while true 
do
    # listen on FIFO and every time there is a line, check the mode and PID
    # if we care about the PID, then respond to it
    if read line <$CAN_FIFO; then
        echo "Frame Received: $line\n"
        recvdPayload=$(getFramePayload "$line")
        # find the PID in list of supported pids
        currentFrameType="0x$(echo $recvdPayload | awk '{print substr($0, 1, 2)}')"
        currentPid="0x$(echo $recvdPayload | awk '{print substr($0, 5, 2)}')"
        currentMode="0x$(echo $recvdPayload | awk '{print substr($0, 3, 2)}')"
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
        else
            # check mode
            modeName=$(checkCurrentMode $currentMode)
            # printf "Mode Name: $modeName\n"
            # check PID
            checkCurrentPid $currentPid $modeName
            # if its found then form a response
            if [ $? -eq 0 ]; then
                printf "Found known PID [$currentPid] on Service [${!currentMode}]. Sending Reply...\n"
                sendSingleFrameResponse $currentMode $currentPid
            else
                printf "Could not recognize PID\n"
            fi
        fi
        # flush fifo 
        read line <$CAN_FIFO
    fi
    
done