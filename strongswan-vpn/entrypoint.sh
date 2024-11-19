#!/bin/bash

##### Strongswan settings update #####
sed -i "s/\$VPN_DOMAIN/$VPN_DOMAIN/g" /etc/ipsec.conf

# Configure credentials in ipsec.secrets
echo ": ECDSA \"/etc/strongswan/certs/server-key.pem\"" > /etc/ipsec.secrets
echo "$VPN_USERNAME : EAP \"$VPN_PASSWORD\"" >> /etc/ipsec.secrets
########################################

##### Setup certificates #####
if [ ! -f /etc/letsencrypt/live/$VPN_DOMAIN/fullchain.pem ]; then
  certbot certonly --standalone --non-interactive --agree-tos --email "$CERTBOT_EMAIL" -d "$VPN_DOMAIN"
fi

# Set up automatic certificate renewal with cron
echo "0 0 * * * certbot renew --quiet --deploy-hook '/update_certs_and_restart.sh'" | crontab -

# Start cron in the background
cron

# Copy certificates to the required directory for StrongSwan
cp /etc/letsencrypt/live/$VPN_DOMAIN/fullchain.pem /etc/strongswan/certs/server-cert.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/privkey.pem /etc/strongswan/certs/server-key.pem
cp /etc/letsencrypt/live/$VPN_DOMAIN/chain.pem /etc/ipsec.d/cacerts/ca-cert.pem

# Check permissions on certificates
chmod 600 /etc/strongswan/certs/server-cert.pem /etc/strongswan/certs/server-key.pem
chown root:root /etc/strongswan/certs/server-cert.pem /etc/strongswan/certs/server-key.pem
########################################

exec ipsec start --nofork