

# This script attempts to:
# - creates a new dev namespae
# - creates a new role for devs and assign to that namespace
# - assigns a dev AAD Group to the restricted role created for the dev namespace
# - assigns an individual user account (dev) to the restricted role created for the dev namespace
# Based on this documentation: https://docs.microsoft.com/en-us/azure/aks/azure-ad-rbac

# AAD Group Name, we do a lookup on this name to pull the ObjectID for Kubernetes role assignment
devgroupname="k8sdev"
devgroupid="" #empty will be queried/populated in the script
# If you want to target a single user this should have the full UPN:  user@somedomain.onmicrosoft.com
devusernameupn=""
# The name you want to use for the Kubernetes Namespace you will create
devnamespacelabel="dev"
# The file name of the YAML manifest which defines your restricted role
# Kubernetes assumes deny by default, so in your rules you are enabling resources (in api groups) & verbs
devroledefinitionfile="RestrictdDevNamespaceRole.yml"
# This is the name value from the Role definition above and used during Role Binding (assignment)
devrolename="dev-user-restricted-access"
devrolebindingname=$devrolename"-binding"

SECONDS=0

starttime=`date +"%Y-%m-%d %T"`
echo "Process Starting: " $starttime

echo "Attempting to create the Namespace: " $devnamespacelabel
kubectl create namespace $devnamespacelabel

echo "Creating a new Kubernetes dev user role and assigning to the newly created Namespace: " $devnamespacelabel 
echo "Using the manifest file:" $devroledefinitionfile
kubectl auth reconcile -f $devroledefinitionfile 

echo "Looking up the object id for AAD group: $devgroupname"
devgroupid = $(az ad group show -g $devgroupname --query objectId -o tsv)
echo "Retrieved AAD Group Object ID: $devgroupid"

echo "Assigning the AAD Group: $devgroupname ($devgroupid) to the Kubernetes restricted dev role: $devrolename in the namespace: $devnamespacelabel"
# Rolebindings needs a binding name, a role name you are targeting and a subject (group or user)
kubectl create rolebinding $devrolebindingname --role=$devrolename --group=$devgroupid --namespace=$devnamespacelabel


stoptime=`date +"%Y-%m-%d %T"`
echo "Process Completed: " $stoptime
duration=$SECONDS
echo "$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

# TEST NOTES:
# To test the new role & role binding, log into Kubectl as a member of your dev AAD group
# first run: az aks get-credentials --resource-group myResourceGroup --name myAKSCluster --overwrite-existing
# then use kubectl commands to view/edit objects in your new namespace 
# Command to get all resources you have access to:
# kubectl get all --namespace=$devnamespacelabel
# Command to get services:
# kubectl get service --namespace=$devnamespacelabel
 