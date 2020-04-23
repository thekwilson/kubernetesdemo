#!/bin/bash
# SAMPLE CODE

#variables (constants) used in the scripts
aksrgname="bak8sRG"
aksclustername="bak8sCluster"
aksdnsprefix="bak8s"
aksvmsize="Standard_B2s"
akslocation="eastus2"
aadserverappid="2f617261-0ca1-448a-b0a9-3aadfe265671"
aadserverappsecret="111aae1a-a111-111a-a111-a11aaa111111" #Replace this fake secret with a real one
aadclientappid="ff0cd904-1111-1111-1111-111111111111"
aadtenantid="d3af6bc3-7ceb-4290-a5af-ffad9eaa7450"
#You need to provide the Subnet ID of the existing subnet or one you create
#See other bash file for creating vnet/subnet quickly for a lab
subnetid="/subscriptions/4fa141ee-5558-4bf3-b338-27e747b044a5/resourceGroups/bak8sRG/providers/Microsoft.Network/virtualNetworks/bak8sClusterVNET/subnets/bak8sClusterSubnet"
# You need to identify 1 ip in the Subnet range used by the cluster for DNS traffic
# should not be the 1st IP.  The IP below matches/sits in the lab range.
dnsserviceip="192.0.3.10"
servicecidr="192.0.3.0/24"
dockerbridgeaddress="172.17.0.1/16"
# Guidance - https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni
# use --outbound-type = userDefinedRouting when you want to avoid Public IP & LB for outbound COMS

# This is a bash internal function that will increment every second onto the value assigned (handy)
# So we can set it to 0 and it will tally all the seconds for the commands to run
SECONDS=0

starttime=`date +"%Y-%m-%d %T"`
echo "Process Starting: " $starttime
echo "Create Resource Group for the Kubernetes cluster (AKS)"
az group create --name $aksrgname --location $akslocation

#NOTE: This command can take from 10 - 40 minutes to run
echo "Create the AKS Cluster with RBAC & Azure AD Properties in the new Resource Group"
az aks create --resource-group $aksrgname --name $aksclustername --node-count 2 --generate-ssh-keys \
--network-plugin azure \
--service-principal $aadserverappid \
--client-secret $aadserverappsecret \
--node-vm-size $aksvmsize --dns-name-prefix $aksdnsprefix \
--aad-server-app-id $aadserverappid --aad-server-app-secret $aadserverappsecret \
--aad-client-app-id $aadclientappid --aad-tenant-id=$aadtenantid \
--vnet-subnet-id $subnetid \
--dns-service-ip $dnsserviceip \
--docker-bridge-address $dockerbridgeaddress \
--service-cidr $servicecidr \

#This section retrieves the full cluster Admin credentials via certificate (note bypasses AAD)
echo "Get AKS credentials for the newly allocated cluster to setup Kubectl"
az aks get-credentials --resource-group $aksrgname --name $aksclustername --admin

# THIS Section is optional it is an example of a call to a YAML manifest to assign security to a user or group in AAD
#echo "Run manifest to setup the cluster admins from the AAD directory group"
#kubectl apply -f AADClusterAdmins-rb.yml

stoptime=`date +"%Y-%m-%d %T"`
echo "Process Completed: " $stoptime
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

