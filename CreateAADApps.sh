#!/bin/bash
#variables (constants) used in the scripts
aksrgname="bak8sRG"
aksclustername="bak8sCluster"
aksdnsprefix="bak8s"
aksvmsize="Standard_B2s"
akslocation="eastus2"
aadserverappid=""
aadserverappsecret=""
aadclientappid=""
aadtenantid="d3af6bc3-7ceb-4290-a5af-ffad9eaa7450"



# This is a bash internal function that will increment every second onto the value assigned (handy)
# So we can set it to 0 and it will tally all the seconds for the commands to run
SECONDS=0

starttime=`date +"%Y-%m-%d %T"`
echo "Process Starting: " $starttime


# Phase 1 Script the Creation of AAD objects.  This is optional if you already have the values.
# This phase is also optional if you want to manually create in a seperate process.
# These scripts require the user to have Azure AD Tenant Administrative permissions
# Create the Azure AD application
echo "SERVER APP: Creating an new App Registration for the new Kubernetes Cluster in Azure AD"
aadserverappid=$(az ad app create \
    --display-name "${aksclustername}Server" \
    --identifier-uris "https://${aksclustername}Server" \
    --query appId -o tsv)
echo $aadserverappid

# Update the application group memebership claims
echo "SERVER APP: Updating the Group Membership Claim of the Server App for the Cluster"
az ad app update --id $aadserverappid --set groupMembershipClaims=All

echo "SERVER APP: Create a service principal in AAD for the new App Registration"
# Create a service principal for the Azure AD application
az ad sp create --id $aadserverappid

echo "SERVER APP: Retrieve the newly created service principal secret"
# Get the service principal secret
foo="AKSPassword"
aadserverappsecret=$(az ad sp credential reset \
    --name $aadserverappid \
    --credential-description $foo --query password -o tsv)
echo "SERVER APP: password = " $aadserverappsecret

# The AKS Cluster App Registration needs permissions to read directory data (users & groups)
# and to sign in an read user profile information
echo "SERVER APP: Assigning AAD Permissions to the App Registration for the AKS Cluster to read directory data and sign in and read user profile"

az ad app permission add \
    --id $aadserverappid \
    --api 00000003-0000-0000-c000-000000000000 \
    --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope 06da0dbc-49e2-44d2-8312-53f166ab848a=Scope 7ab1d382-f21e-4acd-a863-ba3e13f7da61=Role

# The previous command added the permissions but did not apply/persist them
# In this command we grant (persist) the permissions and give admn-consent for the SP
# Note: This step must be run as a Tenant Admin
echo "SERVER APP: Granting permissions that were added and giving Admin-Consent to the App Registration for the AKS Cluster"
az ad app permission grant --id $aadserverappid --api 00000003-0000-0000-c000-000000000000
az ad app permission admin-consent --id  $aadserverappid
echo "SERVER APP Process Completed"

# Setup the Client App in AAD with SP & Perms
echo "CLIENT APP Process Started"
echo "CLIENT APP: Create an AAD Application that will represent the clients/users who are requesting access"
echo " to the Kubernetes Cluster resources. "
aadclientappid=$(az ad app create \
    --display-name "${aksclustername}Client" \
    --native-app \
    --reply-urls "https://${aksclustername}Client" \
    --query appId -o tsv)

echo "CLIENT APP:  Client App Id = " $aadclientappid
echo "CLIENT APP: Creating a service principle for the AKS Cluster Client App Registration"
az ad sp create --id $aadclientappid

# Retrieve the oAuth2 ID for the Server APP created above 
echo "CLIENT APP: Getting the oAuth2 ID value for the Cluster Server App"
oauthquery="oauth2Permissions[0].id"
oAuthPermissionId=$(az ad app show --id $aadserverappid --query $oauthquery -o tsv)

echo "CLIENT APP: oAuthPermission ID = " $oAuthPermissionId

# Add permissions for the client App to communicate with the server app via oAuth2 flow
# Grant/persist the permissions
echo "CLIENT APP: Adding permissions to Client to communicate with Server App via oAuth2 Flow API"
az ad app permission add --id $aadclientappid --api $aadserverappid --api-permissions ${oAuthPermissionId}=Scope
az ad app permission grant --id $aadclientappid --api $aadserverappid

echo "CLIENT APP Provisioning Process Completed"
# END OPTIONAL Phase 1

stoptime=`date +"%Y-%m-%d %T"`
echo "Process Completed: " $stoptime
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."
