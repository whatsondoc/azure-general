#!/bin/bash

if command -v az > /dev/null
then

echo -e "\n\n:::Virtual Machine & artifact deletion:::\n"
date

if ! touch ./VMARTDELETIONTEST.FILE 2&> /dev/null
then	
echo -e "\n\nTemporary files will be created in this working directory as part of the script and are critical to its operation. 

However, we cannot write here --- please move to a directory where you have write privileges, and re-run this script.\n\n" 
exit 1
else
rm ./VMARTDELETIONTEST.FILE
fi

echo -e "\n"
read -p "Enter the VM name: " VMName
read -p "Enter the Resource Group name: " RGName

OUTPUT=./$VMName-deletion.tmp

echo -e "\nThese are the resources being deleted: \n"

az vm show -g $RGName -n $VMName --query "id" -o tsv

# Identifying the OS disk:
OSDiskid=$(az vm show -n $VMName -g $RGName --query "{OSDisk:storageProfile.osDisk.managedDisk.id}" -o tsv)
echo $OSDiskid

# Identifying any data disks:
DATADISKS=( $(az vm show -g $RGName -n $VMName --query "storageProfile.dataDisks[*].managedDisk.id" -o tsv) )
if [[ ${#DATADISKS[@]} != 0 ]]
then
	DISKSNUMBER="$((`echo ${#DATADISKS[*]}` - 1))" # Reducing by 1 as disk numbering starts at 0

	for i in `seq 0 $DISKSNUMBER`
	do
		DATADISK[$i]=$(echo ${DATADISKS[$i]})
		echo ${DATADISKS[$i]} >> $OUTPUT.DATADISK
	done
cat $OUTPUT.DATADISK
fi

# Identifying any NICs:
NICS=( $(az vm show -g $RGName -n $VMName --query "networkProfile.networkInterfaces[*].id" -o tsv) )
if [[ ${#NICS[@]} != 0 ]]
then
	NICSNUMBER=$(expr `echo ${#NICS[*]}` - 1) # Reducing by 1 as NIC number starts at 0

	for j in `seq 0 $NICSNUMBER`
	do
		NIC[$j]=$(echo ${NICS[$j]})
		echo ${NIC[$j]} >> $OUTPUT.NIC
		
		NSG[$j]=$(az resource show --id ${NIC[$j]} --query "properties.networkSecurityGroup.id" -o tsv)
		if [[ ${#NSG[$j]} != 0 ]]
		then
			echo ${NSG[$j]} >> $OUTPUT.NSG
		fi
		
		PIP[$j]=$(az resource show --id ${NIC[$j]} --query "properties.ipConfigurations[$j].properties.publicIPAddress.id" -o tsv)
		if [[ ${#PIP[$j]} != 0 ]]
		then
			echo ${PIP[$j]} >> $OUTPUT.PIP
		fi
	done

if [ -f $OUTPUT.NIC ]; then cat $OUTPUT.NIC; fi
if [ -f $OUTPUT.NSG ]; then cat $OUTPUT.NSG; fi
if [ -f $OUTPUT.PIP ]; then cat $OUTPUT.PIP; fi

fi

# Preparing for deletion:

echo -e "\n"
read -p "Please press enter to continue with this operation >>>"
echo -e "\n"

# Deleting the VM:
echo -e "Deleting: Virtual Machine (VM):"
az vm delete -n $VMName -g $RGName --yes -y > /dev/null
echo -e "Complete\n"

# Deleting the OS disk:
echo -e "Deleting: OS Disk:"
az resource delete --ids $OSDiskid
echo -e "Complete\n"

# Delete data disks:
if [ -f $OUTPUT.DATADISK ]
then
	echo -e "Deleting: Data Disks"
	while read -r datadisk
	do
		DELETEDATADISK="$datadisk"
		az resource delete --ids $DELETEDATADISK
	done < $OUTPUT.DATADISK
	echo -e "Complete\n"
fi

# Deleting the NIC(s):
if [ -f $OUTPUT.NIC ]
then
	echo -e "Deleting: Network Interface Cards (NICs)"
	while read -r nic
	do
		DELETENIC="$nic"
		az resource delete --ids $nic
	done < $OUTPUT.NIC
	echo -e "Complete\n"
fi

# Deleting the NSG:
if [ -f $OUTPUT.NSG ]
then
	echo -e "Deleting: Network Security Groups (NSGs)"
	while read -r nsg
	do
		DELETENSG="$nsg"
		az resource delete --ids $nsg
	done < $OUTPUT.NSG
	echo -e "Complete\n"
fi

# Deleting the public IP:
if [ -f $OUTPUT.PIP ]
then
	echo -e "Deleting: Public IP Addresses (PIPs)"
	while read -r pip
	do
		DELETEPIP="$pip"
		az resource delete --ids $pip
	done < $OUTPUT.PIP
	echo -e "Complete\n\n"
fi

rm $OUTPUT.*

else
	echo -e "\nThe Azure CLI is required for this script, and it is not present on this system.\n

	Exiting...\n"
fi
