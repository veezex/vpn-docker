#!/bin/bash

sed -i "s/\$NET_INTERFACE/$NET_INTERFACE/g" /etc/sockd.conf

# Запуск dante-server
exec sockd -f /etc/sockd.conf