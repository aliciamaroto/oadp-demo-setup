#!/bin/sh

#To be filled with the Azure Subscription Details:

AZURE_SUBSCRIPTION_ID=1ef10936-aa67-4214-97e8-416e07f5755b
AZURE_TENANT_ID=64dc69e4-d083-49fc-9569-ebece1dd1408
AZURE_CLIENT_ID=db8a6fb6-8dac-468c-b507-cb3007bec907
AZURE_CLIENT_SECRET=rg28Q~FJvSOTwbYjH9QXyxLGUkVadwfGK~yfCaDP

echo -e "\n========================"
echo -e "Creating blob in Azure"
echo -e "==========================\n"

RESOURCE_GROUP=Velero_Backups
STORAGE_ACCOUNT="velero$(uuidgen | cut -d '-' -f5 | tr '[A-Z]' '[a-z]')"
CONTAINER=velero

echo -e "\n1. Logging into Azure"
az login

echo -e "\n2. Creating a custom resource group"
az group create  --name $RESOURCE_GROUP --location germanywestcentral

echo -e "\n3. Creating a storage account"
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP  --sku Standard_GRS --location germanywestcentral --encryption-services blob --https-only true --kind BlobStorage  --access-tier Hot

echo -e "\n4. Creating a blob container"
az storage container create --account-name $STORAGE_ACCOUNT --name $CONTAINER  --public-access off

#Azure
echo -e "\n5. Creating an object storage secret "

ACCOUNT_KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query "[?keyName == 'key1'].value" -o tsv)

echo -e "\n6. Creating a custom role with the minimun required permissions"

AZURE_ROLE=Velero
az role definition create --role-definition '{
   "Name": "'$AZURE_ROLE'",
   "Description": "Velero related permissions to perform backups, restores and deletions",
   "Actions": [
       "Microsoft.Compute/disks/read",
       "Microsoft.Compute/disks/write",
       "Microsoft.Compute/disks/endGetAccess/action",
       "Microsoft.Compute/disks/beginGetAccess/action",
       "Microsoft.Compute/snapshots/read",
       "Microsoft.Compute/snapshots/write",
       "Microsoft.Compute/snapshots/delete",
       "Microsoft.Storage/storageAccounts/listkeys/action",
       "Microsoft.Storage/storageAccounts/regeneratekey/action"
   ],
   "AssignableScopes": ["/subscriptions/'$AZURE_SUBSCRIPTION_ID'"]
   }'

echo -e "\nCreate a credentials-velero file"

cat << EOF > ./operator-install/credentials-velero
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
AZURE_RESOURCE_GROUP=${RESOURCE_GROUP}
AZURE_STORAGE_ACCOUNT_ACCESS_KEY=${ACCOUNT_KEY} 
AZURE_CLOUD_NAME=AzurePublicCloud
EOF

sleep 10
echo -e "\nCreate secret in OpenShift with the storage credentials"
oc create secret generic cloud-credentials-azure -n openshift-adp --from-file cloud=operator-install/credentials-velero

#Create BackupStorageLocation variables file:
cat << EOF > ./operator-install/BackupStorageLocation-variables
export RESOURCE_GROUP=${RESOURCE_GROUP}
export STORAGE_ACCOUNT=${STORAGE_ACCOUNT}
export SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
export BUCKET_NAME=${CONTAINER}
EOF

source ./operator-install/BackupStorageLocation-variables
envsubst < operator-install/dpa-tmp.yaml > operator-install/dpa.yaml
