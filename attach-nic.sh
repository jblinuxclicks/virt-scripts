#!/bin/bash
# This script attach a live guest present NIC to a bridged interface

guest=$1
bridge=$2
type=bridge
parameters=$#

check_parameters () {
# Check the numbers of parameters required
if [ "$parameters" -ne 2  ] ; then
echo "Description : This script attach a live guest present NIC to a bridge"
echo "Usage       : $0 <guest name> <bridge_interface_name>"
echo "Example     : $0 guest1 virbr0"
echo "              to attach the live guest1 NIC to virbr0"
exit
fi
# Check if the guest name chosen is in live and display help to choose
guests_defined_live="$(virsh list --name)"
if grep -qvw "$guest" <<< ${guests_defined_live}  ; then
echo "Please provide a live guest name : exit"
echo "Guests avaible :"
echo "$(virsh list --name)"
exit
fi
# Check if the bridge interface is avaible
if grep -qvw "$bridge" <<< $(ls /sys/class/net) ; then
echo "This interface ${bridge} is not avaible"
echo "Please create a valid bridge or choose between : "
echo $(ls /sys/class/net)
exit
fi
}

check_mac_address () {
mac=""
while grep -qvw "$mac" <<< $(virsh domiflist $guest | tail -n +3 | head -n -1 | awk '{ print $5; }') ; do
virsh domiflist $guest
read -p  "Please choose a mac address to attach : " mac
done
}


define_nic () {
cat << EOF > /tmp/vnic.$mac.xml
<interface type="$type">
<mac address="$mac"/>
<source bridge="$bridge"/>
<model type='virtio'/>
</interface>
EOF
}

attach_nic () {
# Detach and attach the guest nic to the live guest
virsh detach-device $guest /tmp/vnic.$mac.xml --live --persistent
virsh attach-device $guest /tmp/vnic.$mac.xml --live --persistent
virsh domiflist $guest
}

check_parameters
check_mac_address
define_nic
attach_nic
