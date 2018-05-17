FROM clearwater/base

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --force-yes clearwater-sip-stress nano tcpdump wget

COPY sip-stress /usr/share/clearwater/bin/sip-stress
RUN chmod +x /usr/share/clearwater/bin/sip-stress

COPY ../../../Ansible/files/continous-stress-testing.sh /usr/share/clearwater/bin/continous-stress-testing
RUN chmod +x /usr/share/clearwater/bin/continous-stress-testing

EXPOSE 5052 5054 5082

WORKDIR "/usr/share/clearwater/bin"
