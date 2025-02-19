#!/bin/bash

# Variables
RESOURCE_GROUP="n8n-rg"
LOCATION="eastus"
VM_NAME="n8n-vm"
ADMIN_USERNAME="n8nadmin"
DNS_PREFIX="n8n-$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 5 | head -n 1)"
DOMAIN_NAME="your-domain.com"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/id_rsa_n8n ]; then
    ssh-keygen -t rsa -b 4096 -N "" -f ~/.ssh/id_rsa_n8n
fi

# Deploy the VM
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file n8n-vm-template.json \
  --parameters \
    vmName=$VM_NAME \
    adminUsername=$ADMIN_USERNAME \
    adminPasswordOrKey="$(cat ~/.ssh/id_rsa_n8n.pub)" \
    dnsLabelPrefix=$DNS_PREFIX \
    n8nDomain=$DOMAIN_NAME

# Get the VM's public IP
VM_IP=$(az vm show -d -g $RESOURCE_GROUP -n $VM_NAME --query publicIps -o tsv)

# Output connection information
echo "VM deployed successfully!"
echo "SSH connection: ssh $ADMIN_USERNAME@$VM_IP"
echo "DNS name: $DNS_PREFIX.$LOCATION.cloudapp.azure.com" 