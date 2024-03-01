#!/bin/sh

#To be filled with the Azure Subscription Details:

#AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
#AZURE_TENANT_ID=${AZURE_TENANT_ID}
#AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
#AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}

AZURE_SUBSCRIPTION_ID=291d7996-5ee1-42d7-b2c8-0c4f3b212c45
AZURE_TENANT_ID=64dc69e4-d083-49fc-9569-ebece1dd1408
AZURE_CLIENT_ID=a71ebc1e-c044-40e3-a826-9d95c24288c4
AZURE_CLIENT_SECRET=W6Z8Q~AheYx1cYl7RvKD62DYqWaAYV6n5CUcXaRv

echo -e "\n========================"
echo -e "Creating blob in Azure"
echo -e "==========================\n"

RESOURCE_GROUP=Velero_Backups
STORAGE_ACCOUNT="velero$(uuidgen | cut -d '-' -f5 | tr '[A-Z]' '[a-z]')"
CONTAINER=velero

echo -e "\nLogging into Azure"
az login

echo -e "\nCreating a custom resource group"
az group create  --name $RESOURCE_GROUP --location germanywestcentral

echo -e "\nCreating a storage account"
az storage account create --name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP  --sku Standard_GRS --location germanywestcentral --encryption-services blob --https-only true --kind BlobStorage  --access-tier Hot

echo -e "\nCreating a blob container"
az storage container create --account-name $STORAGE_ACCOUNT --name $CONTAINER  --public-access off

#Azure
echo -e "\nCreating an object storage secret "

ACCOUNT_KEY=$(az storage account keys list --account-name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --query "[?keyName == 'key1'].value" -o tsv)

echo -e "\nCreating a custom role with the minimun required permissions"

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

cat << EOF > ./credentials-velero
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
AZURE_RESOURCE_GROUP=${RESOURCE_GROUP}
AZURE_STORAGE_ACCOUNT_ACCESS_KEY=${ACCOUNT_KEY} 
AZURE_CLOUD_NAME=AzurePublicCloud
EOF


oc create secret generic cloud-credentials-azure -n openshift-adp --from-file cloud=credentials-velero
