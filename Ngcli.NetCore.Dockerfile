FROM microsoft/dotnet:2.2-sdk as builder  
 
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
COPY Ngcli.NetCore/Ngcli.NetCore.csproj Ngcli.NetCore/
COPY ./NuGet.Config Ngcli.NetCore/
RUN dotnet restore ./Ngcli.NetCore/Ngcli.NetCore.csproj 

COPY Ngcli.NetCore Ngcli.NetCore/
WORKDIR /root/src/app/netcoreapp/Ngcli.NetCore
RUN dotnet publish -c release -f netcoreapp2.2 -o published


FROM microsoft/dotnet:2.2-aspnetcore-runtime

WORKDIR /root/  
COPY --from=builder /root/src/app/netcoreapp/Ngcli.NetCore/published .
ENTRYPOINT ["dotnet", "Ngcli.NetCore.dll"]
