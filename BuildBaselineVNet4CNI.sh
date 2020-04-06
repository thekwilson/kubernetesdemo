#!/bin/bash
#variables (constants) used in the scripts

aksrgname="bak8sRG"
vnetname="bak8sClusterVNET"
#IN Azure the first 4 and last 1 IP, total of 5 IPs are reserved per vnet
# /19 = 8,187 IPs
vnetprefix="10.0.0.0/19"
subnetname="bak8sClusterSubnet"
subnetid=""
#IN Azure the first 4 and last 1 IP, total of 5 IPs are reserved per subnet
# /23 = 507 IPs usable, note for Kubernetes this is also used by PODS! 
subnetprefix="10.0.0.0/23"
akslocation="eastus2"



echo "Create Resource Group for the Kubernetes cluster (AKS) == " $aksrgname
az group create --name $aksrgname --location $akslocation

echo "Creating the VNET & Subnet per variables defined == " $vnetname " | " $subnetname
az network vnet create -g $aksrgname -n $vnetname --address-prefix $vnetprefix \
    --subnet-name $subnetname --subnet-prefix $subnetprefix

echo "Retrieving the generated subnet's ID"
subnetid=$(az network vnet subnet list \
    --resource-group $aksrgname \
    --vnet-name $vnetname \
    --query "[0].id" --output tsv)

echo "Subnet ID = " $subnetid

