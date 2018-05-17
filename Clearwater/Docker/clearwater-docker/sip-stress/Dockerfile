FROM clearwater/base

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes clearwater-sip-stress nano tcpdump wget

EXPOSE 5052 5054 5082

WORKDIR "/usr/share/clearwater/bin"
