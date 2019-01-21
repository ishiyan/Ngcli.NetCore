# Ngcli.NetCore

[![Build Status](https://mbrane.visualstudio.com/IvanShiyan/_apis/build/status/Ngcli.NetCore%20-%20Azure%20Kubernetes%20Service%20-%20CI)](https://mbrane.visualstudio.com/IvanShiyan/_build/latest?definitionId=10)

An [Angular7](https://blog.angular.io/) playground to play with [MathJax](https://www.mathjax.org/) and [D3](https://d3js.org/)-related things hosted in a minimalistic ASP.NET Core project.

Also shows how to:
- deploy the project to a Docker container.
- deploy a Docker container to an Azure Kubernetes Service (AKS) cluster using Azure pipelines.

Try it live at [http://ngclinetcore.westeurope.cloudapp.azure.com](http://ngclinetcore.westeurope.cloudapp.azure.com).

To run docker image locally, use
```bash
docker build -t foo/bar -f Ngcli.Netcore.Dockerfile .

docker image list
# REPOSITORY          TAG                      IMAGE ID            CREATED             SIZE
# foo/bar             latest                   c887461c1e2a        6 days ago          298MB

# this will wait Control+C to be stopped
docker run -p 5000:80 foo/bar

# this will run in the background
docker run -d -p 5000:80 foo/bar

# to stop container running in background
docker container ls -all
# CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
# a227db67c27e        foo/bar             "dotnet Ngcli.NetCor…"   22 seconds ago      Up 20 seconds       0.0.0.0:5000->80/tcp   eager_mccarthy
docker container stop a22
# a22
```
