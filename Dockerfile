FROM microsoft/dotnet:2.1-sdk as builder  
 
RUN mkdir -p /root/src/app/netcoreapp
WORKDIR /root/src/app/netcoreapp


# set up node
ENV NODE_VERSION 10.9.0
ENV NODE_DOWNLOAD_SHA d061760884e4705adfc858eb669c44eb66cd57e8cdf6d5d57a190e76723af416
RUN curl -SL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" --output nodejs.tar.gz \
    && echo "$NODE_DOWNLOAD_SHA nodejs.tar.gz" | sha256sum -c - \
    && tar -xzf "nodejs.tar.gz" -C /usr/local --strip-components=1 \
    && rm nodejs.tar.gz \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# copy just the project file over
# this prevents additional extraneous restores
# and allows us to re-use the intermediate layer
# This only happens again if we change the csproj.
# This means WAY faster builds!
COPY Ngcli.NetCore.csproj .
RUN dotnet restore Ngcli.NetCore.csproj

COPY * ./
RUN dotnet publish -c release -f netcoreapp2.1 -o published Ngcli.NetCore

FROM microsoft/dotnet:2.1-aspnetcore-runtime

WORKDIR /root/  
COPY --from=builder /root/src/app/netcoreapp/published .
ENTRYPOINT ["dotnet", "Ngcli.NetCore.dll"]
