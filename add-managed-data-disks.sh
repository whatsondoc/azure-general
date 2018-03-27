#!/bin/bash

if command -v az > /dev/null
then
	echo -e "\n:::Adding managed data disks to an Azure VM:::\n"
	date
	echo ""

	read -p "Enter the name of the VM that we will be adding the managed disks to: " VMNAME
	read -p "Enter the name of the Resource Group in which the VM exists: " RGRP
	echo ""
	read -p "Enter the size in GB of each managed disk: " SIZE
	read -p "Specify the storage type for these managed disks (Standard_LRS or Premium_LRS): " SKU
	read -p "How many managed data disks shall we add as part of this operation? Note the max number of disks per VM: " UPPER
	read -p "What LUN should we start at: " LUNSTART

	let DISKNUM=$(( ($LUNSTART + $UPPER) - 1 ))

	for i in $(seq $LUNSTART $DISKNUM)
	do
		az vm disk attach --resource-group $RGRP --vm-name $VMNAME --disk $VMNAME-datadisk-$i --new --size-gb $SIZE --sku $SKU --lun $i		
	done

echo -e "\n\nThe VM now has these disks attached:\n" 
az vm show --resource-group $RGRP --name $VMNAME --query "storageProfile.dataDisks[*].managedDisk.id" -o tsv
echo -e "\n"

else
	echo -e "\nThis is a script that will run using the Azure CLI - it does not look as though this is installed.\n\nExiting...\n"
	exit
fi
