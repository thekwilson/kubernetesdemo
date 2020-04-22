# Kubernetes Scripting & Example Building Content

This is a collection of scripts and demo artifacts for working with/manipulating Azure Kubernetes Services (AKS)

Example #1:  Build an AKS Cluster that is:
* Deployed to a private VNet (Advanced Networking with CNI) 
* Integratd with Azure Active Directory (AAD) for RBAC Authorization
* The primary scripts to run are:
    * [BuildBaslineVNET4CNI.sh](BuildBaslineVNET4CNI.sh) (OPTIONAL) - script to automate creating an RG with a VNET & Subnet for hosting AKS.  You can skip this script if you have existing resources.
    * [CreateAADApps.sh](CreateAADApps.sh) (OPTIONAL) - script to automate the creation of AAD App Registrations & service principals needed to support the integration of AAD for Kubernetes RBAC security.  You can skip this if you want to use existing accounts registrations/sps or manually create these in AAD.
    * [buildADAKSCluster.sh](buildADAKSCluster.sh) - primary script to call the command to create the AKS Cluster

NOTE:  All bash script files use the Azure CLI for automation, you need at least version ###.  The top of every script file has variables you need to review and set accordingly.

Example #2: Secure Objects in Kubernetes with AAD by:
* Creating a Custom Role in Azure to support AAD User/Group Kubernetes credential access with reduced permissions
* Creating a new Namespace in Kubernetes
* Applying a new Kubernetes Role Definition manifest/yml file that enables whatever APIs and verbs that role needs 
* Applying a Kubernetes Role Binding to bind the role created to AAD object (users and groups)
* The primary scripts to run are:
    * [CreateDemoAADGroupsAndUsers.sh](CreateDemoAADGroupsAndUsers.sh) (Optional) - this script will automate the creation of a user and group in AAD for testing purposes and return the necessary object IDs.  It uses the Azure CLI (az ad) and requires some AAD permissions.  You can skip this step and just provide your own values in the next steps.
    * [somescript.sh](somescript.sh) (Optional) - When users log into AKS from kubectl they will need to pull down k8s credentials(certs) based on their AAD login.  To do that they by default need to have Contributor permissions on the AKS Cluster object in Azure.  Your can reduce those permissions to less than Contributor on the cluster by creating a more targeted Azure Custom Role and this script will walk you through those steps.
    * [BuildDevNamespaceControls.sh](BuildDevNamespaceControls.sh) - this is the primary script that creates a namespace, runs the manifest to create a custom role, runs the manifest to create the binding of the custom role to the targeted AAD Group/User.  

* To test you will need to log in to a terminal with the Azure CLI (You can use the Azure cloud shell, shell.azure.com) as the AAD user/group member you assigned.  The command to pull the user creds for the base k8s Config is:  az aks get-credentials --name YOURCLUSTERNAME --resource-group YOURCLUSTERRESOURCEGROUP Then you can validate with Kubectl that you only have access to the Namespace & role assigned.

Example #3: Provision a sample/example Kubernetes Application that:
* Uses an Internal Load Balancer for private IP ingress 
* Targets a specific Namespace (typically Namespace provisioned above)
* Deploys a basic web app that can be browsed on 80/442 over the private IP issued
* The primary scripts to run:
    * [DeploySampleILBApp.sh](DeploySampleILBApp.sh) -

Example #4: Provision a new AKS Cluster that is using the preview Private Cluster features to control Cluster Egress and use UDR routes verses the default Public IP and LB for Cluster Internet egress (outbound traffic)
* See this article & step by step guide: 

Example #5: Enable the Azure Policy for Azure Kubernetes Services Preview functionality to scan for the use of Public IPs in AKS and report their non-compliance 
* See this article & step by step guide: 


