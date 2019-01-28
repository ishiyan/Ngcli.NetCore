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
  "appId": "01713f2c-802d-46e6-91bc-9463d9545a01",
  "displayName": "azure-cli-2019-01-26-22-04-52",
  "name": "http://azure-cli-2019-01-26-22-04-52",
  "password": "8647c4b1-566c-46ad-8d23-6b8ac375c6c5",
  "tenant": "8da2da14-8165-45ea-b36e-56c1e6bbc278"
}
/////////
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
## Create NGINX ingress controller with static IP address
```bash
# get the resource group name of the AKS cluster
>az aks show --resource-group myResourceGroup --name myAksCluster --query nodeResourceGroup -o tsv
>az aks show --resource-group mbrane --name mbrane1 --query nodeResourceGroup -o tsv
MC_mbrane_mbrane1_westeurope

# create a public IP address with the static allocation method
>az network public-ip create --resource-group MC_mbrane_mbrane1_westeurope --name mbrane1_public_IP --allocation-method static
{
  "publicIp": {
    "dnsSettings": null,
    "etag": "W/\"d7b68971-7b85-4592-b225-a785aa0a229b\"",
    "id": "/subscriptions/.../resourceGroups/MC_mbrane_mbrane1_westeurope/providers/Microsoft.Network/publicIPAddresses/mbrane1_public_IP",
    "idleTimeoutInMinutes": 4,
    "ipAddress": "13.73.228.22",
    "ipConfiguration": null,
    "ipTags": [],
    "location": "westeurope",
    "name": "mbrane1_public_IP",
    "provisioningState": "Succeeded",
    "publicIpAddressVersion": "IPv4",
    "publicIpAllocationMethod": "Static",
    "publicIpPrefix": null,
    "resourceGroup": "MC_mbrane_mbrane1_westeurope",
    "resourceGuid": "b32b1eb1-826b-49ee-a231-fb3ee59eb3e5",
    "sku": {
      "name": "Basic",
      "tier": "Regional"
    },
    "tags": null,
    "type": "Microsoft.Network/publicIPAddresses",
    "zones": null
  }
}

>az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '13.73.228.22')].[id]" --output tsv
/subscriptions/.../resourceGroups/MC_mbrane_mbrane1_westeurope/providers/Microsoft.Network/publicIPAddresses/mbrane1_public_IP

# update public IP address with DNS name
az network public-ip update --ids /subscriptions/.../resourceGroups/MC_mbrane_mbrane1_westeurope/providers/Microsoft.Network/publicIPAddresses/mbrane1_public_IP --dns-name mbrane1
{
  "dnsSettings": {
    "domainNameLabel": "mbrane1",
    "fqdn": "mbrane1.westeurope.cloudapp.azure.com",
    "reverseFqdn": null
  },
  "etag": "W/\"a5c89439-3a3b-4113-8944-e066dfff783b\"",
  "id": "/subscriptions/.../resourceGroups/MC_mbrane_mbrane1_westeurope/providers/Microsoft.Network/publicIPAddresses/mbrane1_public_IP",
  "idleTimeoutInMinutes": 4,
  "ipAddress": "13.73.228.22",
  "ipConfiguration": {
    "etag": null,
    "id": "/subscriptions/.../resourceGroups/MC_mbrane_mbrane1_westeurope/providers/Microsoft.Network/loadBalancers/kubernetes/frontendIPConfigurations/ad226b7f4e8c111e883fb0ea911a4edf",
    "name": null,
    "privateIpAddress": null,
    "privateIpAllocationMethod": null,
    "provisioningState": null,
    "publicIpAddress": null,
    "resourceGroup": "MC_mbrane_mbrane1_westeurope",
    "subnet": null
  },
  "ipTags": [],
  "location": "westeurope",
  "name": "mbrane1_public_IP",
  "provisioningState": "Succeeded",
  "publicIpAddressVersion": "IPv4",
  "publicIpAllocationMethod": "Static",
  "publicIpPrefix": null,
  "resourceGroup": "MC_mbrane_mbrane1_westeurope",
  "resourceGuid": "b32b1eb1-826b-49ee-a231-fb3ee59eb3e5",
  "sku": {
    "name": "Basic",
    "tier": "Regional"
  },
  "tags": null,
  "type": "Microsoft.Network/publicIPAddresses",
  "zones": null
}

# deploy the nginx-ingress chart with Helm and specify the public IP address created in the previous step
>helm install stable/nginx-ingress --name "my" --namespace kube-system --set rbac.create=true --set controller.service.loadBalancerIP="13.73.228.22"

>kubectl get service -l app=nginx-ingress --namespace kube-system
NAME                               TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                      AGE
my-nginx-ingress-controller        LoadBalancer   10.0.109.147   13.73.228.22   80:30814/TCP,443:30946/TCP   3m
my-nginx-ingress-default-backend   ClusterIP      10.0.65.55     <none>         80/TCP                       3m

# install the cert-manager controller
>helm install stable/cert-manager --namespace kube-system --set ingressShim.defaultIssuerName=letsencrypt-prod --name cert-manager --set ingressShim.defaultIssuerKind=ClusterIssuer --set rbac.create=true
```
Create the `cluster-issuer.yaml` file:
```yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ivan.shiyan@gmail.com
    privateKeySecretRef:
      name: letsencrypt-prod
    http01: {}
```
Create the `certificates.yaml` file.
Update the `dnsNames` and `domains` to the DNS name you created before.
```yaml
apiVersion: certmanager.k8s.io/v1alpha1
kind: Certificate
metadata:
  name: tls-secret
spec:
  secretName: tls-secret
  dnsNames:
  - mbrane1.westeurope.cloudapp.azure.com
  acme:
    config:
    - http01:
        ingressClass: nginx
      domains:
      - mbrane1.westeurope.cloudapp.azure.com
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
```
Create the `mbrane1-ingress.yaml`
```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: mbrane1-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    certmanager.k8s.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  tls:
  - hosts:
    - mbrane1.westeurope.cloudapp.azure.com
    secretName: tls-secret
  rules:
  - host: mbrane1.westeurope.cloudapp.azure.com
    http:
      paths:
      - path: /ngclinetcore
        backend:
          serviceName: ngclinetcore
          servicePort: 80
      - path: /hello-world-two
        backend:
          serviceName: ingress-demo
          servicePort: 80
```
Then execute
```bash
>kubectl apply -f cluster-issuer.yaml
clusterissuer.certmanager.k8s.io "letsencrypt-prod" created

>kubectl apply -f certificates.yaml
certificate.certmanager.k8s.io "tls-secret" created

>kubectl apply -f mbrane1-ingress.yaml
ingress.extensions "mbrane1-ingress" created
```

```bash
>kubectl get pod
NAME                         READY     STATUS    RESTARTS   AGE
ngclinetcore-7c6777c-lq4fh   1/1       Running   0          34m

>kubectl exec -ti ngclinetcore-7c6777c-lq4fh bash
root@ngclinetcore-7c6777c-lq4fh:~#
```

## Add a second static IP address
```bash
# create a public IP address with the static allocation method
>az network public-ip create --resource-group MC_mbrane_mbrane1_westeurope --name mbrane1_public_IP_2 --allocation-method static
{
  "publicIp": {
    "dnsSettings": null,
    "etag": "W/\"f01afcf4-4565-4b9a-a650-862655326138\"",
    "id": "/subscriptions/6dd7b982-533a-45d0-b6c7-5dc5bbeaed46/resourceGroups/MC_mbrane_mbrane1_westeurope/providers/Microsoft.Network/publicIPAddresses/mbrane1_public_IP_2",
    "idleTimeoutInMinutes": 4,
    "ipAddress": "104.40.182.64",
    "ipConfiguration": null,
    "ipTags": [],
    "location": "westeurope",
    "name": "mbrane1_public_IP_2",
    "provisioningState": "Succeeded",
    "publicIpAddressVersion": "IPv4",
    "publicIpAllocationMethod": "Static",
    "publicIpPrefix": null,
    "resourceGroup": "MC_mbrane_mbrane1_westeurope",
    "resourceGuid": "fb888db1-55bb-4b59-91b1-558c2467eb03",
    "sku": {
      "name": "Basic",
      "tier": "Regional"
    },
    "tags": null,
    "type": "Microsoft.Network/publicIPAddresses",
    "zones": null
  }
}
>az network public-ip list --query "[?ipAddress!=null]|[?contains(ipAddress, '104.40.182.64')].[id]" --output tsv
/subscriptions/6dd7b982-533a-45d0-b6c7-5dc5bbeaed46/resourceGroups/MC_mbrane_mbrane1_westeurope/providers/Microsoft.Network/publicIPAddresses/mbrane1_public_IP_2

# update public IP address with DNS name
>az network public-ip update --ids /subscriptions/.../resourceGroups/MC_mbrane_mbrane1_westeurope/providers/Microsoft.Network/publicIPAddresses/mbrane1_public_IP_2 --dns-name ngclinetcore-mbrane1
tcore-mbrane1
{
  "dnsSettings": {
    "domainNameLabel": "ngclinetcore-mbrane1",
    "fqdn": "ngclinetcore-mbrane1.westeurope.cloudapp.azure.com",
    "reverseFqdn": null
  },
  "etag": "W/\"0bf4819a-db77-4c76-8afe-27dd76c298f6\"",
  "id": "/subscriptions/6dd7b982-533a-45d0-b6c7-5dc5bbeaed46/resourceGroups/MC_mbrane_mbrane1_westeurope/providers/Microsoft.Network/publicIPAddresses/mbrane1_public_IP_2",
  "idleTimeoutInMinutes": 4,
  "ipAddress": "104.40.182.64",
  "ipConfiguration": null,
  "ipTags": [],
  "location": "westeurope",
  "name": "mbrane1_public_IP_2",
  "provisioningState": "Succeeded",
  "publicIpAddressVersion": "IPv4",
  "publicIpAllocationMethod": "Static",
  "publicIpPrefix": null,
  "resourceGroup": "MC_mbrane_mbrane1_westeurope",
  "resourceGuid": "fb888db1-55bb-4b59-91b1-558c2467eb03",
  "sku": {
    "name": "Basic",
    "tier": "Regional"
  },
  "tags": null,
  "type": "Microsoft.Network/publicIPAddresses",
  "zones": null
}
```
