# VPN StrongSwan Setup for Debian 12

This project provides a VPN setup using StrongSwan, designed to run on Debian 12 systems. **Note:** This setup has only been tested on Debian 12.

## Requirements

Ensure the following ports are open:

- **Port 80**: Required for Certbot.
- **Ports 500 and 4500**: Required for StrongSwan.

## Installation Steps

1. **Update System Packages**

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install Make**

   ```bash
   sudo apt install make
   ```

3. **Install Docker**

   To install Docker, execute the following commands:

   ```bash
   chmod +x install_docker.sh
   ./install_docker.sh
   ```

4. **Configure Environment Variables**

   Copy the `.env.example` file to `.env`:

   ```bash
   cp .env.example .env
   ```

   Edit the `.env` file as needed to configure your setup.

## Usage

- **Start the Server**

  ```bash
  make start
  ```

- **Stop the Server**
  ```bash
  make stop
  ```
