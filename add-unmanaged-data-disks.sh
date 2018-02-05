#!/bin/bash

if command -v az > /dev/null
then
	read -p "Enter the name of the VM that we will be adding disks to: " vmname
	read -p "Enter the name of the Resource Group in which the VM exists: " rg
	read -p "Enter the size in GB of each disk: " size
	read -p "How many data disks shall we add as part of this operation? Note the max number of disks per VM: " upper

	lower=0
	for i in $(seq $lower $upper)
	do
		az vm unmanaged-disk attach --new --vm-name $vmname --resource-group $rg --lun $i --size $size --name $vmname-datadisk-$i

		echo -e "\n\nThe VM now has these disks attached:\n"
                az vm show --resource-group $rg --vm-name $vmname | grep diskSize 	

	done
else
	echo -e "This is a script that will run using the Azure CLI - it does not look as though this is installed.\n\nExiting...\n"
	exit
fi
