#!/bin/bash

OUTPUT=/tmp/API-layer_VM-sizes.output

echo -e "\nThe following are all current Azure regions:\n"

az account list-locations | grep name | awk '{print $2 $3}' | sed 's/.$//' | sed 's/"//g'

echo -e "...Or leave blank to include all\n"

read -p "Select Azure region: " REGION

if [ -z $REGION ]
then
        echo -e "\nCapturing details from all regions...\n"
	echo "----------------------------" >> $OUTPUT.ALL; date >> $OUTPUT.ALL; echo "----------------------------" >> $OUTPUT.ALL
	for i in $(az account list-locations | grep name | awk '{print $2 $3}' | sed 's/.$//' | sed 's/"//g')
        do
		echo -e "\nSTART: $i\n" >> $OUTPUT.ALL
                az vm list-sizes --location $i --output table >> $OUTPUT.ALL
                echo -e "\nFINISH: $i\n" >> $OUTPUT.ALL
	done
        	echo -e "\n<--COMPLETED-->\n"
		echo -e "\nThe output has been recorded here: `echo $OUTPUT.ALL`\n"

elif [ -n $REGION ]
then
        if
		az account list-locations | grep name | awk '{print $2 $3}' | sed 's/.$//' | sed 's/"//g' | grep -w $REGION > /dev/null
	then
		echo -e "\nCapturing details from $REGION...\n"
        	echo "----------------------------" >> $OUTPUT.$REGION; date >> $OUTPUT.$REGION; echo "----------------------------" >> $OUTPUT.$REGION
		az vm list-sizes --location $REGION --output table >> $OUTPUT.$REGION
		echo -e "\n<--COMPLETED-->\n"
		echo -e "\nThe output has been recorded here: `echo $OUTPUT.REGION`\n"
	else
		echo -e "\n$REGION isn't a recognised Azure region...\n"
	fi
fi                         
