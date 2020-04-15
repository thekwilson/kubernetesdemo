

# This script attempts to:
# - creates a ...
# Based on this documentation: https://docs.microsoft.com/en-us/azure/aks/azure-ad-rbac

# AAD Group Name, we do a lookup on this name to pull the ObjectID for Kubernetes role assignment
devAADGroupName="k8sdev"
devAADGroupID=""
# If you want to target a single user this should have the full UPN:  user@somedomain.onmicrosoft.com
devAADUserUPN=""
# The name you want to use for the namespace you will create
devnamespacelabel="dev"
# The file name of the YAML manifest which defines your restricted role
# Kubernetes assumes deny and in your rules you are enabling resources (in api groups) & verbs
devroledefinitionfile="RestrictdDevNamespaceRole.yml"
# This is the name value from the Role definition above and used during Role Binding (assignment)
devrolename="dev-user-restricted-access"
devrolebindingname=$devrolename"-binding"

SECONDS=0

starttime=`date +"%Y-%m-%d %T"`
echo "Process Starting: " $starttime