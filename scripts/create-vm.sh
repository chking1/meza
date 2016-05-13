#!/bin/sh
#
# Generate a VirtualBox VM

echo "This script creates a new virtual machine"

#
# Variables that can be set initially
#
clientOS="RedHat_64"
hostOS="$OSTYPE"
vram=12
username=`whoami`


#
# Prompt for VM name
#
while [ -z "$vmname" ]; do
	echo
	echo "Type your desired VM name"
	read vmname
done

#
# Check for host OS and set variables accordingly
#

# For Windows systems
if [ "$hostOS" = "msys" ]; then

	# vboxmanage command path
	vboxm="/c/Program Files/Oracle/VirtualBox/vboxmanage"
	# VirtualBox Guest Additions iso file
	guestadditions="/c/Program Files/Oracle/VirtualBox/VBoxGuestAdditions.iso"

	# VM directory and hard drive location
	vmdir="/c/users/$username/VirtualBox VMs/$vmname"
	harddrive="$vmdir/$vmname.vdi"

elif [ "$hostOS" = "mac" ]; then

	echo
	echo "Mac is not yet supported. I'm not sure what the hostOS variable even will be."
	exit 1

	### FIXME: GUESSING ON OSX CONFIG ###

	# vboxmanage command path
	vboxm="/Applications/VirtualBox.app/Contents/MacOS/VBoxManage"
	# VirtualBox Guest Additions iso file
	guestadditions="/Applications/VirtualBox.app/Contents/MacOS/VBoxGuestAdditions.iso"

	# VM directory and hard drive location
	vmdir="/c/Users/$username/VirtualBox VMs/$vmname"
	harddrive="$vmdir/$vmname.vdi"

else
	echo
	echo "Your host operating system is not supported."
	exit 1
fi


#
# Check if VM exists (now that we know the OS and know where to look)
#
if [ -d "$vmdir" ]; then
	echo
	echo "ERROR: VM name already exists."
	exit 1
fi


#
# Prompt for path to CentOS ISO file
#
user="/c/Users/$username"
isos="$user/*.iso"
echo
echo "Below is a list of ISO files in your user directory ($user)"
echo
echo "Please select the correct ISO for your install"
select FILENAME in $isos;
do
	echo
	echo "You picked ISO file:"
	echo "$FILENAME"
	iso=$FILENAME
	break
done


#
# Prompt: Hard Drive Size
#
default_storage=20
while [ -z "$storage" ]; do
	echo
	echo "How many gigabytes of storage do you want?"
	read -e -i $default_storage storage
	storage=${storage:-$default_storage}
done
storage="$(($storage * 1024))"


#
# Prompt: RAM
#
default_memory=1
while [ -z "$memory" ]; do
	echo
	echo "How many gigabytes of RAM do you want?"
	read -e -i $default_memory memory
	memory=${memory:-$default_memory}
done
memory="$(($memory * 1024))"


#
# Get Host-Only adapter name from vboxmanage command
#
hostonlyadapter=`"$vboxm" list hostonlyifs | grep "^Name:" | sed "s/^Name:[[:space:]]*//"`


#
# Now go forth and create a VM
#

# createhd creates a new virtual hard disk image
"$vboxm" createhd --filename "$harddrive" --size $storage

# createvm creates a new XML virtual machine definition file
"$vboxm" createvm --name "$vmname" --ostype "$clientOS" --register

# storagectl attaches/modifies/removes a storage controller
"$vboxm" storagectl "$vmname" --name "SATA Controller" --add sata --controller IntelAHCI

# storageattach attaches/modifies/removes a storage medium connected
# to a storage controller that was previously added with the storagectl command
"$vboxm" storageattach "$vmname" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$harddrive"

"$vboxm" storagectl "$vmname" --name "IDE Controller" --add ide
"$vboxm" storageattach "$vmname" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$iso"
"$vboxm" storageattach "$vmname" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "$guestadditions"
# modifyvm changes the properties of a registered virtual machine which is not running
# audio needs to be fixed
"$vboxm" modifyvm "$vmname" --ioapic on
"$vboxm" modifyvm "$vmname" --boot1 dvd --boot2 disk --boot3 none --boot4 none
"$vboxm" modifyvm "$vmname" --memory "$memory" --vram "$vram"
"$vboxm" modifyvm "$vmname" --nic1 nat
"$vboxm" modifyvm "$vmname" --nic2 hostonly --hostonlyadapter2 "$hostonlyadapter"
"$vboxm" modifyvm "$vmname" --natpf1 "[ssh],tcp,,3022,,22"
"$vboxm" modifyvm "$vmname" --audio null

# Do we want a shared folder?
# sharedfolder="/c/users/$username/desktop"
#"$vboxm" sharedfolder add "$vmname" --name "your_shared_folder" --hostpath "$sharedfolder"
