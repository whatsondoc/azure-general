#!/bin/bash
set -e 

#### Script syntax: ./downloadupload.sh <SOURCE_STORAGE_ACCOUNT_NAME> <TARGET_STORAGE_ACCOUNT_NAME>

SOURCESA=$1
TARGETSA=$2


## Capturing required binaries:

if ! command -v az > /dev/null
then echo -e "The Azure CLI is required for this script to run, and it is not installed (or not in $PATH)\n\n"; exit 1
fi

if ! command -v azcopy > /dev/null
then echo -e "AzCopy is not installed on this local machine (or is not in $PATH), and is needed for this script to function\n\n"; exit 1
fi 

## Functions:

BRK() {
    echo -e "\n\n"
}


## Script body:

#az login

BRK

# Exporting Storage Account variables:
if [ $(az storage account list -o table | grep ${SOURCESA} | awk '{print $9}') = "available" ]
then export SOURCE_RG=$(az storage account list -o table | grep ${SOURCESA} | awk '{print $8}')
else export SOURCE_RG=$(az storage account list -o table | grep ${SOURCESA} | awk '{print $9}')
fi

if [ $(az storage account list -o table | grep ${TARGETSA} | awk '{print $9}') = "available" ]
then export TARGET_RG=$(az storage account list -o table | grep ${TARGETSA} | awk '{print $8}')
else export TARGET_RG=$(az storage account list -o table | grep ${TARGETSA} | awk '{print $9}')
fi

export AZURE_STORAGE_ACCOUNT=${SOURCESA}
export AZURE_STORAGE_KEY=$(az storage account keys list --account-name ${AZURE_STORAGE_ACCOUNT} --resource-group ${SOURCE_RG} -o table | grep key1 | awk '{print $3}')

export TARGET_AZURE_STORAGE_ACCOUNT=${TARGETSA}
export TARGET_AZURE_STORAGE_KEY=$(az storage account keys list --account-name ${TARGET_AZURE_STORAGE_ACCOUNT} --resource-group ${TARGET_RG} -o table | grep key1 | awk '{print $3}')

# Collecting container names:
CONTAINERS=( $(az storage container list --account-name $AZURE_STORAGE_ACCOUNT --account-key $AZURE_STORAGE_KEY -o table | awk '{print $1}' | grep -v Name | grep -v ^---) )

# Downloading all contents from all containers in the source storage account:
DOWNLOAD_UPLOAD_DIR=/mnt/downloadupload
DULOGS=/mnt/downloaduploadlogs
mkdir ${DOWNLOAD_UPLOAD_DIR}
mkdir ${DULOGS}

for i in ${CONTAINERS[*]}
do
    mkdir ${DOWNLOAD_UPLOAD_DIR}/$i
    azcopy --source https://${AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/$i --destination ${DOWNLOAD_UPLOAD_DIR}/$i --source-key ${AZURE_STORAGE_KEY} --resume ${DULOGS}/journal-down-$i --recursive >> $DULOGS/$i.azcopy.download.log &
done

# Allowing some time for the AzCopy processes to download some data
echo "Downloads initiated - sleeping"
sleep 60
echo -e "\nAwakened - uploads starting..."

# Uploading the downloaded data from the source storage account to the new storage account:  
for q in $(ls ${DOWNLOAD_UPLOAD_DIR})
do
    az storage container create --name $q --public-access off --fail-on-exist --account-name ${TARGET_AZURE_STORAGE_ACCOUNT} --account-key ${TARGET_AZURE_STORAGE_KEY} >> ${DULOGS}/container-creation.log
    azcopy --source ${DOWNLOAD_UPLOAD_DIR}/$q --destination "https://${TARGET_AZURE_STORAGE_ACCOUNT}.blob.core.windows.net/$q" --dest-key ${TARGET_AZURE_STORAGE_KEY} --blob-type block --resume ${DULOGS}/journal-up-$q --recursive >> $DULOGS/$q.azcopy.upload.log &
done