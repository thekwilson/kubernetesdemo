# SAMPLE CODE
# This script attempts to:
# - creates an Azure Active Directory (AAD) Group for Developers
# - assign the Developers AAD Group the Kubernetes Cluster User Role (built in Azure RBAC role for AKS)
# - create a new AAD User that represents a developer
# - assign the new AAD User to the Developers AAD Group
# Based on this documentation: https://docs.microsoft.com/en-us/azure/aks/azure-ad-rbac

# NOTE:  This script REQUIRES AZURE AD PERMISSIONS to manipulate users, groups and the AKS Cluster 


#Variables or Constants used in the script:
devgroupname="k8sdevg4"
devgroupid="" #empty will be generated in the script
devusername="kubernetesdev4"
aaddomainname="kwilson.onmicrosoft.com"
devusernameupn=$devusername"@"$aaddomainname
devuserid="" #empty will be generated in the script
devuserpwd="Kub3rn3t3$"
aksrgname="bak8sRG" #the name of the Resource Group fo ryour AKS Cluster
aksclustername="bak8sCluster" #the name of your AKS Cluster
aksid="" #empty will be queried in the script
azurerbacclusterrolename="Azure Kubernetes Service Cluster User Role"
removeobjects=true

SECONDS=0

starttime=`date +"%Y-%m-%d %T"`
echo "Process Starting: " $starttime

echo "Querying for the AKS Cluster Resource ID..."
aksid=$(az aks show \
    --resource-group $aksrgname \
    --name $aksclustername \
    --query id -o tsv)
echo "AKS Cluster Resource ID = $aksid"

#Checks to see if the remove argument was passed in
if [[ $# -eq 0 ]] || [[ $1 != 'remove' ]]
then 
    echo "Attempting to create AAD Group: $devgroupname"
    devgroupid=$(az ad group create --display-name $devgroupname --mail-nickname $devgroupname --query objectId -o tsv)
    echo "AAD Group ID = $devgroupid"

    echo "Sleeping for 30 seconds for new AAD Group propagation..."
    sleep 30

    echo "Assigning the role: $azurerbacclusterrolename to the AAD Group: $devgroupname "
    az role assignment create \
    --assignee $devgroupid \
    --role "$azurerbacclusterrolename" \
    --scope $aksid

    echo "Creating user: $devusernameupn"
    devuserid=$(az ad user create \
    --display-name $devusername \
    --user-principal-name $devusernameupn \
    --password $devuserpwd \
    --query objectId -o tsv)
    echo "User ID for $devusernameupn = $devuserid"

    echo "Assigning user ID $devuserid to the Group ID $devgroupname"
    az ad group member add --group $devgroupname --member-id $devuserid

else

    #OPTIONAL STEPS TO TEAR DOWN RESOURCES 
    #Triggered by passing the string "remove" as an argument the script

    echo "Removing objects created"
    echo "Removing user $devusernameupn"
    az ad user delete --id $devusernameupn
    echo "Fetching ID for group $devgroupname"
    devgroupid=$(az ad group show --group $devgroupname --query objectId -o tsv)
    echo "Removing role assignment for group: $devgroupname"
    echo "...with id: $devgroupid"
    echo "...with role: $azurerbacclusterrolename"
    
    az role assignment delete \
    --assignee $devgroupid \
    --role "$azurerbacclusterrolename" \
    --scope $aksid
    echo "Removing AAD Group $devgroupname with ID: $devgroupid"
    az ad group delete --group $devgroupid
fi

stoptime=`date +"%Y-%m-%d %T"`
echo "Process Completed: " $stoptime
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."



