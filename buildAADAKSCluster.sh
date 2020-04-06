#!/bin/bash
#variables (constants) used in the scripts

aksrgname="bak8sRG"
aksclustername="bak8sCluster"
aksdnsprefix="bak8s"
aksvmsize="Standard_B2s"
akslocation="eastus2"
aadserverappid="2f617261-0ca1-448a-b0a9-3aadfe265671"
aadserverappsecret="640aae5d-f002-491d-a814-b63dca693990"
aadclientappid="ff0cd904-4fc1-41d3-bbf0-1d79c157c312"
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



echo "Create Resource Group for the Kubernetes cluster (AKS)"
az group create --name $aksrgname --location $akslocation

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

echo "Get AKS credentials for the newly allocated cluster to setup Kubectl"
az aks get-credentials --resource-group $aksrgname --name $aksclustername --admin

echo "Run manifest to setup the cluster admins from the AAD directory group"
kubectl apply -f AADClusterAdmins-rb.yml

#install Helm Tiller - this assumes HELM CLI already in place
#helm init
#helm repo update


#echo "Start the SSH tunnel for the Kubernetes management website"
#az aks browse --name $aksclustername --resource-group $aksrgname
#az aks get-credentials --resource-group $aksrgname --name $aksclustername

#ORIGINAL
#echo "Create Resource Group for the Kubernetes cluster (AKS)"
#az group create --name kubebow2RG --location eastus
#echo "Create the AKS Cluster in the new Resource Group"
#az aks create --resource-group kubebow2RG --name KubeBow2 --node-count 1 --generate-ssh-key --node-vm-size Standard_B2s --dns-name-prefix kubebow2
#echo "Start the SSH tunnel for the Kubernetes management website"
#az aks browse --name KubeBow2 --resource-group kubebow2R
