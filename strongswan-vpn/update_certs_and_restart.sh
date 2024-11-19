#!/bin/bash

# Copy certificates to the required directory for StrongSwan
cp /etc/letsencrypt/live/$VPN_DOMAIN/fullchain.pem /etc/strongswan/certs/server-cert.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/privkey.pem /etc/strongswan/certs/server-key.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/chain.pem /etc/ipsec.d/cacerts/ca-cert.pem

# Check permissions on certificates
chmod 600 /etc/strongswan/certs/server-cert.pem /etc/strongswan/certs/server-key.pem
chown root:root /etc/strongswan/certs/server-cert.pem /etc/strongswan/certs/server-key.pem

# Restart StrongSwan
ipsec restart