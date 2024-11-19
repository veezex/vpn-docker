# Project Overview

This project provides configurations for deploying a VPN using StrongSwan and an HTTPS proxy on a Debian 12 host system. It includes all necessary settings and scripts to set up and manage the required network infrastructure.

## Tested Environment

- **Host System**: Debian 12  
  Please note that the project has been tested only in this environment. Compatibility with other systems is not guaranteed.

## Project Structure

The project is organized into two main directories:

### 1. `strongswan-vpn`

This folder contains the configuration files and settings required to deploy a VPN using StrongSwan.

- **Required Ports**:
  - `80` (HTTP)
  - `4500` (IPSec NAT Traversal)
  - `500` (IKE)

### 2. `proxy`

This folder contains the configuration files and settings needed to deploy an HTTPS proxy.

- **Required Ports**:
  - `80` (HTTP)
  - `51822` (Custom HTTPS Proxy Port)

## IPTables Configuration

To facilitate proper network routing and firewall rules for the services, an example IPTables configuration script is provided:

- **Script**: `setup_iptables.sh`  
  Use this script to configure the required IPTables rules on the host system.

## Usage Instructions

1. **Clone the Repository**:

   ```bash
   git clone <repository_url>
   cd <repository_folder>
   ```

2. **Configure VPN**:

   - Navigate to the `strongswan-vpn` directory.
   - Follow the included instructions or customize the configuration files as needed.
   - Ensure that ports `80`, `4500`, and `500` are open and properly forwarded.

3. **Configure HTTPS Proxy**:

   - Navigate to the `proxy` directory.
   - Set up the proxy service using the provided configuration files.
   - Ensure that ports `80` and `51822` are open and properly forwarded.

4. **Set Up IPTables**:

   - Execute the provided script:
     ```bash
     sudo bash setup_iptables.sh
     ```

## Installation Steps

1. **Update System Packages**:

   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install Make**:

   ```bash
   sudo apt install make
   ```

3. **Install Docker**:

   To install Docker, execute the following commands:

   ```bash
   chmod +x install_docker.sh
   ./install_docker.sh
   ```

4. **Configure Environment Variables**:

   Copy the `.env.example` file to `.env`:

   ```bash
   cp .env.example .env
   ```

   Edit the `.env` file as needed to configure your setup.

## Usage

- **Start the Server**:

  ```bash
  make start
  ```

- **Stop the Server**:

  ```bash
  make stop
  ```

## Notes

- This project assumes a clean Debian 12 host system for deployment.
- Ensure you have the necessary privileges to configure services and IPTables rules on the host.
- Check for potential conflicts with other services using the specified ports.
