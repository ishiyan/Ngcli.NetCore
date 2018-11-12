# AKS how-to
## Azure Container Registry
### Create ACR
```bash
>az login
>az account set --subscription "6dd7..."

# create a Resource Group
>az group create --name myResourceGroup --location westeurope
>az group create --name mbrane --location westeurope

# create an Azure Container Registry instance
>az acr create --resource-group myResourceGroup --name myAcrName --sku Basic
>az acr create --resource-group mbrane --name mbrane --sku Basic

# to use the ACR instance, you must first log in
>az acr login --name myAcrName
>az acr login --name mbrane

>az acr list --resource-group mbrane
[
  {
    "adminUserEnabled": true,
    "creationDate": "2018-10-30T22:38:28.678804+00:00",
    "id": "/subscriptions/.../resourceGroups/mbrane/providers/Microsoft.ContainerRegistry/registries/mbrane",
    "location": "westeurope",
    "loginServer": "mbrane.azurecr.io",
    "name": "mbrane",
    "provisioningState": "Succeeded",
    "resourceGroup": "mbrane",
    "sku": {
      "name": "Basic",
      "tier": "Basic"
    },
    "status": null,
    "storageAccount": null,
    "tags": {},
    "type": "Microsoft.ContainerRegistry/registries"
  }
]

```
### Push images to ACR
```bash
# get the login server address to be used for image tagging
>az acr list --resource-group myResourceGroup --query "[].{acrLoginServer:loginServer}" --output table
>az acr list --resource-group mbrane --query "[].{acrLoginServer:loginServer}" --output table
AcrLoginServer
-----------------
mbrane.azurecr.io

# push a tagged image to the ACR instance
>docker push <acrLoginServer>/myImage:tag
>docker push mbrane.azurecr.io/myImage:tag

# list images in registry
>az acr repository list --name myAcrName --output table
>az acr repository list --name mbrane --output table
Result
---------------------
ishiyan/ngcli.netcore

# to see the tags for a specific image, use
>az acr repository show-tags --name myAcrName --repository myImage --output table
>az acr repository show-tags --name mbrane --repository ishiyan/ngcli.netcore --output table
Result
--------
94
95

```
## Azure Kubernetes Service (AKS) cluster
### Service Principal
```bash
# to allow an AKS cluster to interact with other Azure resources,
# an Azure Active Directory service principal is used
>az ad sp create-for-rbac --skip-assignment
{
  "appId": "92da3c45-2e76-4e14-bd62-f99881aaed05",
  "displayName": "azure-cli-2018-11-10-12-14-05",
  "name": "http://azure-cli-2018-11-10-12-14-05",
  "password": "ab45a99c-6b56-4445-8de8-616feb98576a",
  "tenant": "8da2da14-8165-45ea-b36e-56c1e6bbc278"
}
# make a note of the appId and password

# to access images stored in ACR, you must grant the AKS service principal
# the correct rights to pull images from ACR
>az acr show --resource-group myResourceGroup --name myAcrName --query "id" --output tsv
>az acr show --resource-group mbrane --name mbrane --query "id"
"/subscriptions/.../resourceGroups/mbrane/providers/Microsoft.ContainerRegistry/registries/mbrane"

# to grant the correct access for the AKS cluster to use images stored in ACR,
# create a role assignment
>az ad sp create-for-rbac --skip-assignment
```
### Create an AKS cluster
```bash
# use the appId and password you noted when created Service Principal
>az aks create --resource-group myResourceGroup --name myAksCluster --node-count 1 --service-principal appId  --client-secret password --generate-ssh-keys
>az aks create --resource-group mbrane --name mbrane1 --node-count 1 --service-principal 92da...  --client-secret ab45... --generate-ssh-keys
```
Probably it is better to create a cluster in an Azure User Interface.
- Select `Create a resource`, then `Kubernetes cluster`
- Select `Western europe` as region
- Service Principal: use the appId and password you noted before
- Select node size `Standard B2s` (2 vcpus, 4 GB memory)
- Select node count `1`
- Enable RBAC
- Basic network (?)
```bash
# to connect to the Kubernetes cluster from your local computer, install `kubectl`
# this will take several minutes
>az aks install-cli

# get credentials from AKS
>az aks get-credentials --resource-group myResourceGroup --name myAksCluster
>az aks get-credentials --resource-group mbrane --name mbrane1

# install helm before going further

>kubectl create -f clusterrole.yaml --validate=false
>kubectl create serviceaccount -n kube-system tiller
>kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
>kubectl create clusterrolebinding kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount=kube-system:kubernetes-dashboard
>helm init --upgrade --service-account tiller
>helm ls
```
where the `clusterrole.yaml` file is
```json
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
    annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
    labels:
    kubernetes.io/bootstrapping: rbac-defaults
    name: cluster-admin
rules:
    - apiGroups: ['*']
      resources: ['*']
      verbs: ['*']
    - nonResourceURLs: ['*']
      verbs: ['*']
```
Grant AKS access to ACR
```bash
# get the id of the service principal configured for AKS
>az aks show --resource-group myResourceGroup --name myAksCluster --query "servicePrincipalProfile.clientId" --output tsv
CLIENT_ID
>az aks show --resource-group mbrane --name mbrane1 --query "servicePrincipalProfile.clientId" --output tsv
92da...

# get the ACR registry resource id
az acr show --name myAcrName --resource-group myResourceGroup --query "id" --output tsv
ACR_ID
az acr show --name mbrane --resource-group mbrane --query "id" --output tsv
/subscriptions/6dd.../resourceGroups/mbrane/providers/Microsoft.ContainerRegistry/registries/mbrane

# create role assignment
az role assignment create --assignee CLIENT_ID --role Reader --scope ACR_ID
az role assignment create --assignee 92da... --role Reader --scope /subscriptions/6dd.../resourceGroups/mbrane/providers/Microsoft.ContainerRegistry/registries/mbrane
```
Now you are ready to start Kubernetes explorer.
```bash
>az aks browse --resource-group myResourceGroup --name myAksCluster
>az aks browse --resource-group mbrane --name mbrane1
```
