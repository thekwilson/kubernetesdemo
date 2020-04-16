#!/bin/bash


# This script can deploy an internal load balancer with a private IP by using the Kubernetes Service
# construct with some AKS specific annotations
# Based on this documentation: https://docs.microsoft.com/en-us/azure/aks/internal-lb
# NOTE:  This script has to be run by someone with rights in Azure to assign the RBAC role network 
# contributor

#variables (constants) used in the scripts
devnamespacelabel="dev"

#the name of the VNet where your AKS cluster is deployed (assumes CNI)
aksvnetname="bak8sClusterVNET"
#the resource group name for the kubernetes cluster
aksrgname="bak8sRG"
#the resource group name for the VNet (defaulted to the same as the AKS Cluster)
vnetrgname=$aksrgname
#the AKS cluster name
aksclustername="bak8sCluster"
#The AKS cluster service principal object id {GUID}, the script attempts to dynamically populate this
#You can instead just hard code it here
aksserviceprincipal=""
#The Azure subscription is needed for the role assignment, this is auto populated by the script
subscriptionid=""
#The name of of the out of the box RBAC role to use in assingment
vnetrbacrole="Network Contributor"

# The file name of the YAML manifest which defines your Kubernetes Service targeting an ILB
privatelbservicefile="privateLBDeployment.yml"


SECONDS=0

#SCRIPT HEADER
starttime=`date +"%Y-%m-%d %T"`
echo "Process Starting: " $starttime

#BEGIN PART 1 ASSIGN THE AKS SP ID WITH THE RIGHT RBAC PERMISSIONS/ROLE ON THE VNET USED BY AKS
echo "Looking up current active Azure Subscription ID"
subscriptionid=$(az account show --query "id" --output tsv)
echo "Subscription = $subscriptionid"

# YOU CAN COMMENT THIS SECTION OUT IF MANUALLY PROVIDING/HARD CODING THE SP OBJECT ID
echo "Looking up the AAD App ID for the AKS Cluster: $aksclustername in RG: $aksrgname"
appid=$(az aks show --resource-group $aksrgname --name $aksclustername --query "servicePrincipalProfile.clientId" --output tsv )

echo "Looking up the AAD Service Principal Object ID for the App ID $appid"
aksserviceprincipal=$(az ad sp list --filter "appId eq '$appid'" --query [].objectId --output tsv)
echo "SP Object ID = $aksserviceprincipal"

vnetresourceid="/subscriptions/$subscriptionid/resourceGroups/$vnetrgname/providers/Microsoft.Network/virtualNetworks/$aksvnetname"

echo "Setting AKS Cluster SP to have $vnetrbacrole on the VNET"
echo "Resource ID for Scope Assignment = $vnetresourceid"
az role assignment create --assignee-object-id $aksserviceprincipal --role "$vnetrbacrole" --scope $vnetresourceid
#END PART 1

#BEGIN PART 2 - DEPLOY A KUBERNETES YAML MANIFEST THAT CREATES AN AZURE INTERNAL LB AS A SERVICE
echo "Deploying the ILB Service manifest"
kubectl apply -f $privatelbservicefile

echo "Sleeping for 60 seconds while the ILB gets provisioned and setup"
sleep 60

echo "Querying All Services in the cluster, the private IP should be assigned to your internal-app under the EXTERNAL-IP column"
kubectl get service

#EXAMPLE OF AZURE CLI SCRIPT STEPS TO REMOVE ROLE ASSIGNMENT FOR THE CLUSTER SP
#az role assignment delete --assignee-object-id $aksserviceprincipal --role "$vnetrbacrole" --scope $vnetresourceid


#SCRIPT FOOTER
stoptime=`date +"%Y-%m-%d %T"`
echo "Process Completed: " $stoptime
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."


