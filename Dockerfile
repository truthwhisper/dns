FROM mcr.microsoft.com/dotnet/aspnet:10-alpine-amd64 AS builder

WORKDIR /app

RUN apk -U upgrade \
    && apk add --no-cache \
    ca-certificates \
    tzdata \
    build-base \
    musl-dev \
    dotnet10-sdk \
    aspnetcore10-runtime \
    libmsquic \
    icu-dev \
    wget \
    curl \
    git \
    doggo

RUN git clone --depth=1 https://github.com/TechnitiumSoftware/TechnitiumLibrary.git TechnitiumLibrary
RUN git clone --depth=1 https://github.com/TechnitiumSoftware/DnsServer.git DnsServer

RUN dotnet build TechnitiumLibrary/TechnitiumLibrary.ByteTree/TechnitiumLibrary.ByteTree.csproj -c Release
RUN dotnet build TechnitiumLibrary/TechnitiumLibrary.Net/TechnitiumLibrary.Net.csproj -c Release
RUN dotnet build TechnitiumLibrary/TechnitiumLibrary.Security.OTP/TechnitiumLibrary.Security.OTP.csproj -c Release

RUN dotnet publish DnsServer/DnsServerApp/DnsServerApp.csproj -c Release

RUN mkdir -p /etc/dns /opt/technitium/dns /var/log/technitium/dns

FROM builder AS build

WORKDIR /opt/technitium/dns

COPY --link --from=builder ./DnsServer/DnsServerApp/bin/Release/publish /opt/technitium/dns

ENTRYPOINT ["/bin/sh", "-c", "dotnet", "/opt/technitium/dns/DnsServerApp.dll"]

CMD ["/etc/dns", "/opt/technitium/dns", "/var/log/technitium/dns"]

EXPOSE \
   53/udp 53/tcp \
   853/udp 853/tcp \
   443/udp 443/tcp \
   80/tcp 8053/tcp \
   5380/tcp 53443/tcp \
   67/udp

LABEL org.opencontainers.image.source="https://github.com/truthwhisper/dns"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.description="Fork of Technitium DNS"
LABEL org.opencontainers.image.authors="lucathar@gmail.com"
