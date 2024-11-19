FROM debian:12

RUN apt-get update && \
  apt-get install -y iptables strongswan sed libstrongswan-standard-plugins libcharon-extra-plugins certbot cron && \
  apt-get clean

COPY sysctl.conf /etc/sysctl.conf

COPY ipsec.conf /etc/ipsec.conf

RUN mkdir -p /etc/strongswan/certs

COPY update_certs_and_restart.sh /update_certs_and_restart.sh
RUN chmod +x /update_certs_and_restart.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]