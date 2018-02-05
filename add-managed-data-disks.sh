#!/bin/bash

if command -v az > /dev/null
then
	read -p "Enter the name of the VM that we will be adding the managed disks to: " vmname
	read -p "Enter the name of the Resource Group in which the VM exists: " rg
	read -p "Enter the size in GB of each managed disk: " size
	read -p "Specify the storage type for these managed disks (Standard_LRS or Premium_LRS): " type
	read -p "How many managed data disks shall we add as part of this operation? Note the max number of disks per VM: " upper

	lower=0
	let disknum=$upper-1

	for i in $(seq $lower $disknum)
	do
		az vm disk attach --resource-group $rg --vm-name $vmname --disk $vmname-datadisk-$i --new --size $size --sku $type -lun $i		
		echo -e "\n\nThe VM now has these disks attached:\n" 
		az vm show --resource-group $rg --vm-name $vmname | grep diskSize
	done
else
	echo -e "This is a script that will run using the Azure CLI - it does not look as though this is installed.\n\nExiting...\n"
	exit
fi
