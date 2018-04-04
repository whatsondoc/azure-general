#!/bin/bash

if command -v az > /dev/null
then

OUTPUT=/tmp/API-layer_VM-sizes.output

echo -e "\nThe following are all current Azure regions:\n"

az account list-locations | grep name | awk '{print $2 $3}' | sed 's/.$//' | sed 's/"//g' | sort -d

echo -e "...Or leave blank to include all\n"

read -p "Select Azure region: " REGION

echo -e "\n"

read -p "If you are interested in a specific VM SKU please enter it here, or leave blank to include all VM SKUs (you can enter a subset of the VM SKU name): " VMSKU

allvms() {

if [ -z $REGION ]
then
	OUTPUT=$OUTPUT.ALLREGIONS.ALLSKUs
        echo -e "\nCapturing details from all regions for all VM SKUs...\n"
	echo "----------------------------" >> $OUTPUT; date >> $OUTPUT; echo "----------------------------" >> $OUTPUT
	for i in $(az account list-locations | grep name | awk '{print $2 $3}' | sed 's/.$//' | sed 's/"//g')
        do
		echo -e "\nSTART: $i\n" >> $OUTPUT
                az vm list-sizes --location $i --output table >> $OUTPUT
                echo -e "\nFINISH: $i\n" >> $OUTPUT
	done
        	echo -e "\n<--COMPLETED-->\n"
		echo -e "\nThe output has been recorded here: `echo $OUTPUT.ALL`\n"

elif [ -n $REGION ]
then
	OUTPUT=$OUTPUT.$REGION.ALLSKUs
        if
		az account list-locations | grep name | awk '{print $2 $3}' | sed 's/.$//' | sed 's/"//g' | grep -wi $REGION > /dev/null
	then
		echo -e "\nCapturing details from $REGION for all VM SKUs...\n"
        	echo "----------------------------" >> $OUTPUT; date >> $OUTPUT; echo -e "----------------------------\n" >> $OUTPUT
		az vm list-sizes --location $REGION --output table >> $OUTPUT
		echo -e "\n<--COMPLETED-->\n"
		echo -e "\nThe output has been recorded here: $OUTPUT\n"
	else
		echo -e "\n$REGION isn't a recognised Azure region...\n"
	fi
fi

}

vmsku() {

if [ -z $REGION ]
then
	OUTPUT=$OUTPUT.ALLREGIONS.$VMSKU
        echo -e "\nCapturing details from all regions for the VM SKU: $VMSKU \n"
        echo "----------------------------" >> $OUTPUT; date >> $OUTPUT; echo -e "----------------------------\n" >> $OUTPUT
	echo "
MaxDataDiskCount    MemoryInMb    Name                    NumberOfCores    OsDiskSizeInMb    ResourceDiskSizeInMb
------------------  ------------  ----------------------  ---------------  ----------------  ----------------------" >> $OUTPUT
        for i in $(az account list-locations | grep name | awk '{print $2 $3}' | sed 's/.$//' | sed 's/"//g')
        do
                echo -e "\nSTART: $i\n" >> $OUTPUT
                az vm list-sizes --location $i --output table | grep -i $VMSKU >> $OUTPUT
                echo -e "\nFINISH: $i\n" >> $OUTPUT
        done
                echo -e "\n<--COMPLETED-->\n"
                echo -e "\nThe output has been recorded here: $OUTPUT\n"

elif [ -n $REGION ]
then
	OUTPUT=$OUTPUT.$REGION.$VMSKU
        if
                az account list-locations | grep name | awk '{print $2 $3}' | sed 's/.$//' | sed 's/"//g' | grep -wi $REGION > /dev/null
        then
                echo -e "\nCapturing details from $REGION for the VM SKU: $VMSKU \n"
                echo "----------------------------" >> $OUTPUT; date >> $OUTPUT; echo -e "----------------------------\n" >> $OUTPUT
		echo "
MaxDataDiskCount    MemoryInMb    Name                    NumberOfCores    OsDiskSizeInMb    ResourceDiskSizeInMb
------------------  ------------  ----------------------  ---------------  ----------------  ----------------------" >> $OUTPUT
                az vm list-sizes --location $REGION --output table | grep -i $VMSKU >> $OUTPUT
                echo -e "\n<--COMPLETED-->\n"
                echo -e "\nThe output has been recorded here: `echo $OUTPUT`\n"
        else
                echo -e "\n$REGION isn't a recognised Azure region...\n"
        fi
fi

}

if [ -z $VMSKU ]
then allvms
else vmsku
fi

else
echo -e "This is a script that will run using the Azure CLI - it does not look as though this is installed.\n\nExiting...\n"
exit
fi
