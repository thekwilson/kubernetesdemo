#!/bin/bash
#variables (constants) used in the scripts
aksrgname="kubebow2RG"
aksclustername="kubebow2"
aksdnsprefix="kubebow2"
aksvmsize="Standard_B2s"
akslocation="eastus2"
aadserverappid="f031e617-d7e5-411d-8b12-50fcd098a122"
aadserverappsecret="1iGaMy9IHy44bokiyT4s1E3uG0VPHuO3Kc/0tusg9N8="
aadclientappid="f98ba8a4-1d81-42a3-bfc0-3eea3fa40524"
aadtenantid="d3af6bc3-7ceb-4290-a5af-ffad9eaa7450"

echo "Create Resource Group for the Kubernetes cluster (AKS)"
az group create --name $aksrgname --location $akslocation

echo "Create the AKS Cluster with RBAC & Azure AD Properties in the new Resource Group"
az aks create --resource-group $aksrgname --name $aksclustername --node-count 1 --generate-ssh-keys --enable-rbac \
--node-vm-size $aksvmsize --dns-name-prefix $aksdnsprefix \
--aad-server-app-id $aadserverappid --aad-server-app-secret $aadserverappsecret \
--aad-client-app-id $aadclientappid --aad-tenant-id=$aadtenantid

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
