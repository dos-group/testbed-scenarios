#############################
## UNDER DEVELOPMENT
#############################

FROM clearwater/base


#clearwater-sip-stress-coreonly is recommended, which is used to stress test sprout. clearwater-sip-stress is used to stress test bono.

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes clearwater-sip-stress-coreonly

WORKDIR "/usr/share/clearwater/bin"
