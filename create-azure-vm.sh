#!/bin/bash


echo -e "\n:::Azure Virtual Machine Creation:::\n"
date
echo -e "\n"

read -p "Please specify the name for the Virtual Machine we will create: " VMNAME

OUTDIR="AZURE-CREATION-OUTPUT-$VMNAME"
if [ ! -d ./AZURE-CREATION-OUTPUT-$VMNAME ]
then
    mkdir $OUTDIR
fi
OUTFILE="AZURE-CREATION-OUTPUT"
OUT="$OUTDIR/$OUTFILE"

############################ START: FUNCTION DEFINITIONS ############################

create_rg() {
RGNAME="$OPTRGRP"
echo -e "\nCreating a new RG:\n"

until [ "$RGLOCVALID" = "true" ]
do
    read -p "In which Azure region will the Resource Group be created: " RGLOC
    if [[ $(az account list-locations --query "[*].name" -o tsv | grep -w $RGLOC) ]]
    then RGLOCVALID="true"
    fi
done

az group create --resource-group $RGNAME --location $RGLOC > $OUT.RG

if [[ $(az group show --resource-group $RGNAME) ]]
then
    echo -e "\nCREATED: Resource Group\n\n"
else
    echo -e "\nOdd... Our Resource Group hasn't created.\n\nExiting...\n\n"
    exit 1
fi
}


create_vnet() {
VNETNAME="$OPTVNET"
echo -e "\nCreating a new VNET:\n"

read -p "Virtual Network IP Address prefix (e.g. 10.0.0.0/8): " VNETPREFIX
echo ""
read -p "Subnet name (to be created within $VNETNAME): " SUBNETNAME
read -p "Subnet IP Address prefix (e.g. 10.0.1.0/24): " SUBNETPREFIX

az network vnet create --resource-group $RGNAME --name $VNETNAME --address-prefix $VNETPREFIX --subnet-name $SUBNETNAME --subnet-prefix $SUBNETPREFIX > $OUT.VNETSUBNET

if [[ $(az network vnet show --resource-group $RGNAME --name $VNETNAME) ]] && [[ $(az network vnet subnet show --resource-group $RGNAME --vnet-name $VNETNAME --name $SUBNETNAME) ]]
then
    echo -e "\nCREATED: Virtual Network & Subnet\n\n"
else
    echo -e "\nOdd... Our Virtual Network and/or subnet hasn't created.\n\nExiting...\n\n"
    exit 1
fi
}


create_nsg() {
NSGNAME="$OPTNSG"
echo -e "\nCreating a new NSG:\n"

az network nsg create --resource-group $RGNAME --name $NSGNAME > $OUT.NSG

echo -e "A basic rule will be created to allow access from the internet to all IP addresses over TCP using port 22"

az network nsg rule create --resource-group $RGNAME --nsg-name $NSGNAME --name Allow-SSH-Internet --access allow --protocol tcp --direction inbound --priority 100 --source-address-prefix Internet --source-port-range "*" --destination-address-prefix "*" --destination-port-range 22 >> $OUT.NSG

echo -e "...Done\n"

if [[ $(az network nsg show --resource-group $RGNAME --name $NSGNAME) ]]
then
    echo -e "\nCREATED: Network Security Group\n\n"
else
    echo -e "\nOdd... Our NSG hasn't created.\n\nExiting...\n\n"
    exit 1
fi
}


create_pip() {
PIPNAME="$OPTPIP"
echo -e "\nCreating a new PIP:\n"

az network public-ip create --name $PIPNAME --resource-group $RGNAME > $OUT.PIP

if [[ $(az network public-ip show --resource-group $RGNAME --name $PIPNAME) ]]
then
    echo -e "\nCREATED: Public IP\n\n"
else
    echo -e "\nOdd... Our PIP hasn't created.\n\nExiting...\n\n"
    exit 1
fi
}


create_nic() {
echo -e "\nCreating a new NIC:\n"
NICNAME="$OPTNIC"
read -p "Enable Accelerated Networking (true or false): " ACCNET

az network nic create --resource-group $RGNAME --name $NICNAME --vnet-name $VNETNAME --subnet $SUBNETNAME --accelerated-networking $ACCNET --public-ip-address $PIPNAME --network-security-group $NSGNAME > $OUT.NIC

if [[ $(az network nic show --resource-group $RGNAME --name $NICNAME) ]]
then
    echo -e "\nCREATED: Network Interface Card\n\n"
else
    echo -e "\nOdd... Our NIC hasn't created.\n\nExiting...\n\n"
    exit 1
fi
}


create_vm() {
unset ADMINUSER
read -p "Enter the admin username for the VM: " ADMINUSER
echo -n "How do you want to use ssh or a password for authentication: "
while :
do
    read AUTH
    case $AUTH in
        [Ss][Ss][Hh])
            AUTH="ssh" 
            echo -e "ssh keys will be generated for '$VMNAME'\n" 
            break ;;
        [Pp][Aa][Ss][Ss][Ww][Oo][Rr][Dd])
            AUTH="password" 
            unset ADMINPASSWORD
            echo -n "Enter the desired admin user password: "; stty -echo; read ADMINPASSWORD; stty echo; echo
            break ;;
        *)
            echo -ne "\nPlease specify either ssh or password: " ;;
    esac
done

echo
read -p "Enter the name of the image for the VM ('centos'; 'debian'; 'ubuntults'; or, enter the name of your own custom image): " VMIMAGE

until [ "$VMVALID" = "true" ]
do
    echo -ne "\nEnter the desired size of the VM (or enter 'showall' for a list of all VM sizes for the '$RGLOC' region): "
  	read CHECKVM
	case $CHECKVM in
		[Ss][Hh][Oo][Ww][Aa][Ll][Ll]|SHOW|show) 
			echo -e "\n"
			az vm list-sizes --location $RGLOC -o table ;;
        [Ss][Tt][Aa][Nn][Dd][Aa][Rr][Dd]*|[Bb][Aa][Ss][Ii][Cc]*)
            if [[ $(az vm list-sizes --location $RGLOC --query "[*].name" -o tsv | grep -wi $CHECKVM) ]]
            then
                VMSIZE="$CHECKVM"
                VMVALID="true"
            fi ;;
		*)
			echo -e "\nVM size not recognised - please re-enter, or use 'showall' to list all available VM size options\n" ;;
	esac
done

if [[ $AUTH = "ssh" ]]
then
    az vm create --resource-group $RGNAME --name $VMNAME --image $VMIMAGE --size $VMSIZE --authentication-type ssh --admin-username $ADMINUSER --generate-ssh-keys --nics $NICNAME > $OUT.VM
    unset ADMINUSER
elif [[ $AUTH = "password" ]]
then
    az vm create --resource-group $RGNAME --name $VMNAME --image $VMIMAGE --size $VMSIZE --authentication-type password --admin-username $ADMINUSER --admin-password $ADMINPASSWORD --nics $NICNAME > $OUT.VM
    unset ADMINUSER
    unset ADMINPASSWORD
fi

if [[ $(az vm show --resource-group $RGNAME --name $VMNAME) ]]
then
    echo -e "\nCREATED: Virtual Machine\n"
else
    echo -e "\nOdd... Our VM hasn't created.\n\nExiting...\n\n"
    exit 1
fi

az vm show --name $VMNAME --resource-group $RGNAME -o table

echo -e "\n\nThe VM has a public IP address of: `az network public-ip show --name $PIPNAME --resource-group $RGNAME --query ipAddress -o tsv` \n"
}


############################ END: FUNCTION DEFINITIONS ############################


echo -e "\n
##############################################
# Defining resources for the Virtual Machine #
##############################################
"

echo -e "\nPlease enter the desired names for the following resources. Existing resources will be used if the names match, otherwise we will create them:\n"

### START: RESOURCE GROUP ###

read -p "Resource Group (RG) name: " OPTRGRP

if [[ $(az group show --resource-group $OPTRGRP) ]]
then
	RGNAME="$OPTRGRP"
	RGLOC=$(az group show --resource-group $RGNAME --query location -o tsv)
	echo -e "\n"
else
	create_rg
fi

### END: RESOURCE GROUP ###



### START: VIRTUAL NETWORK ###

read -p "Virtual Network (VNET) name: " OPTVNET

if [[ $(az network vnet show --name $OPTVNET --resource-group $RGNAME) ]]
then 
	VNETNAME="$OPTVNET"
	SUBNETS=$(az network vnet show --resource-group $RGNAME --name $VNETNAME --query "subnets[*].name" -o tsv)
	if [[ ${#SUBNETS[@]} = 0 ]]
	then 
		echo -e "No subnets exist\n"
		read -p "Please create a subnet. This script will wait, please hit enter to continue >> "
	elif [[ ${#SUBNETS[@]} = 1 ]]
	then
		SUBNETNAME=$SUBNETS
        echo -e "Subnet '`echo $SUBNETS`' selected\n"
	elif [[ ${#SUBNETS[@]} > 1 ]]
	then
		SUBNETNOS="$((`echo ${#SUBNETS[@]}` - 1))"
		echo -e "Multiple subnets discovered:\n"
		for i in `seq 0 $SUBNETS`
		do
			echo ${SUBNETS[$i]}
		done
		read -p "Please specify the subnet name: " SUBNETNAME
		echo -e "\n"
	fi
else
	create_vnet
fi

### END: VIRTUAL NETWORK ###



### START: NETWORK SECURITY GROUP ###

read -p "Network Security Group (NSG) name: " OPTNSG

if [[ $(az network nsg show --name $OPTNSG --resource-group $RGNAME) ]]
then
	NSGNAME="$OPTNSG"
    echo
else
	create_nsg
fi

### END: NETWORK SECURITY GROUP ###


### START: PUBLIC IP ###

read -p "Public IP Address (PIP) name: " OPTPIP

if [[ $(az network public-ip show --name $OPTPIP --resource-group $RGNAME) ]]
then
	PIPNAME="$OPTPIP"
    echo
else
	create_pip
fi

### END: PUBLIC IP ###



### START: NETWORK INTERFACE CARD ###

read -p "Network Interface Card (NIC) name: " OPTNIC

if [[ $(az network nic show --name $OPTNIC --resource-group $RGNAME) ]]
then
	NICNAME="$OPTNIC"
    echo
else
	create_nic
fi

### END: NETWORK INTERFACE CARD ###



### START: VIRTUAL MACHINE ###

create_vm

### END: VIRTUAL MACHINE



### FINAL BITS AND PIECES ###

echo -e "\nThe output from the VM creation stages were written to the following files: \n"
find $OUTDIR -name "$OUTFILE*"

echo -ne "\nWould you like to retain these output files? "
while :
do
	read DELOUTPUT
	case $DELOUTPUT in
		[Yy][Ee][Ss])
            echo
            break ;;
		[Nn][Oo])
            find $OUTDIR -name "$OUTFILE*" -type f -exec rm {} \;
            rmdir $OUTDIR
			echo -e "\nDeleted output files\n" 
            break ;;
		*)
			echo -ne "\nPlease enter 'Yes' or 'No': " ;;
	esac
done

echo -e "\n"