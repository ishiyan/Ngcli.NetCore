FROM mcr.microsoft.com/dotnet/core/sdk:3.1-buster as builder  

# we could use alpine image for building, but there is no pre-compiled NodeJS for it.
# so we use debian image for building
# FROM mcr.microsoft.com/dotnet/core/sdk:3.0-alpine as builder  
# # set up curl
# RUN apk add --no-cache curl

# set up node
ENV NODE_VERSION 12.11.1
ENV NODE_DOWNLOAD_SHA ac6c76af7c13cc3688aba072c4c728cb6fa2c40b340b1dcc4795e2705b1869dc
RUN curl -SL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" --output nodejs.tar.gz \
    && echo "$NODE_DOWNLOAD_SHA nodejs.tar.gz" | sha256sum -c - \
    && tar -xzf "nodejs.tar.gz" -C /usr/local --strip-components=1 \
    && rm nodejs.tar.gz \
    && ln -s /usr/local/bin/node /usr/local/bin/nodejs

# copy csproj and restore as distinct layers
WORKDIR /app
COPY Ngcli.NetCore/Ngcli.NetCore.csproj ./Ngcli.NetCore/
COPY ./NuGet.Config ./Ngcli.NetCore/
RUN dotnet restore ./Ngcli.NetCore/Ngcli.NetCore.csproj 

COPY Ngcli.NetCore/. ./Ngcli.NetCore/
WORKDIR /app/Ngcli.NetCore
RUN dotnet publish -c Release -r linux-musl-x64 -o published --self-contained true /p:PublishTrimmed=true


FROM mcr.microsoft.com/dotnet/core/runtime-deps:3.1-alpine AS runtime

WORKDIR /app
COPY --from=builder /app/Ngcli.NetCore/published ./
ENTRYPOINT ["./Ngcli.NetCore"]
