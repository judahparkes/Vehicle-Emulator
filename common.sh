bringUpCanIface()
{
    # bring up the can or vcan interface with given name
    iface_name=$1
    interface_type=$2
    
    ip a show $iface_name up
    if [ $? -eq 0 ]; then
        printf "putting can interface down...\n"
        ip link set $iface_name down
        printf "deleting $iface_name interface\n"
        ip link delete $iface_name 
    fi

    if [ "$interface_type" = "physical" ]; then
        printf "Setting up physical CAN interface\n"
        # ip link set $iface_name down
        ip link set $iface_name type can bitrate 500000  &&  ip link set $iface_name txqueuelen 1000 && ip link set $iface_name up
        if [ $? -eq 0 ]; then
            printf "interface up!\n"
            RET=0
        else
            printf "interface not up :(\n"
            exit -1
        fi
    else
        printf "Setting up virtual CAN interface\n"
        modprobe vcan && ip link add dev $iface_name type vcan loopback on && ip link set $iface_name txqueuelen 1000 && ip link set $iface_name up 
        if [ $? -eq 0 ]; then
            printf "interface up!\n"
            RET=0
        else
            printf "interface not up\n"
            exit -1
        fi
    fi


    if [ $RET -eq 0 ]; then
        printf "CAN interface is up!\n"
    else
        printf "CAN interface failed to come up\n"
        exit -1
    fi
}

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
    exec 4<> "$SEND_FIFO"
    while true; do
        if read -e line; then
            # printf "Sending on queue: $line\n"
            cansend $CAN_IFACE $line
        fi
    done <"$SEND_FIFO"
}

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
