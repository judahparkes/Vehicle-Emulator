

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
            printf "interface not up :(\n"
            exit -1
        fi
    fi


    if [ $RET -eq 0 ]; then
        printf "CAN interface is up!\n"
    else
        printf "CAN interface failed to come up :(\n"
        exit -1
    fi
}

