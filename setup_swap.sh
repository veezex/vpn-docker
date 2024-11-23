#!/bin/bash

# Create a 2GB swap file
fallocate -l 2G /swapfile

# Set the correct permissions
chmod 600 /swapfile

# Set up the swap area
mkswap /swapfile

# Enable the swap file
swapon /swapfile

# Make the swap file permanent
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# Verify the swap file is active
free -h