#!/bin/bash

## This script takes a prepared image and automates the custom image creation process

if command -v az > /dev/null
then 

echo ""
date
echo -e "\nStep 1: Deprovisioning the VM...\n"

read -p "Azure instance name of the VM: " AZUREVM
read -p "Resource Group of the VM: " AZURERG

read -p "Username for the VM: " SOURCEUSER

SOURCEIPADDR=$(az vm show -g vmss-custom-image -n bhwcci71hpc01 -d | grep -i publicips | awk '{print $2}' | sed 's/\"//g' | rev | sed 's/,//' | rev)

echo -e "\nConnecting to $AZUREVM to deprovision...\n"

ssh -t $SOURCEUSER@$SOURCEIPADDR sudo waagent -deprovision -force

sleep 5

echo -e "Step 2: Deallocating $AZUREVM...\n"
az vm deallocate --resource-group $AZURERG --name $AZUREVM

while [[ $state != deallocated ]]
do
        state=$(az vm show --resource-group vmss-custom-image --name $AZUREVM -d | grep -i powerState | awk '{print $3}' | sed 's/..$//')
        az vm show --resource-group vmss-custom-image --name $AZUREVM -d | grep -i powerState
        echo "Sleeping for 5 seconds: waiting for deallocation..."; sleep 5
done

echo "The VM -- $AZUREVM -- is now: $state"

echo -e "Step 3: Generalizing $AZUREVM...\n"
az vm generalize --resource-group $AZURERG --name $AZUREVM

sleep 2

AZUREIMAGE=$AZUREVM-image
az image create --resource-group $AZURERG --name $AZUREIMAGE --source $AZUREVM 

echo -e "\n...Custom image creation process completed...\n"
date
echo -e "\n"
else 

echo "...This script requires the Azure CLI - please run this on a machine with this installed..."
exit
fi
