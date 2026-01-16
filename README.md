# Home Lab Setup with Portainer and Proxmox VE

In this article we will describe how to set up a Docker environment using [Portainer](https://www.portainer.io/) and [Proxmox VE](https://www.proxmox.com/en/proxmox-ve) for a simple home lab setup.

The main idea is to have a Proxmox VE host running a single VM that hosts the Docker containers. The VM is connected to the local network via a virtual bridge. The Docker containers are managed using Portainer, and a DNS Proxy is used for local domain resolution with domain `.interal` and for external DNS resolution to the Docker containers with domains `.portainer`. Additionally, Nginx Proxy Manager is used as a reverse proxy to manage external access to the services running in the Docker containers.

> __Note__: This setup is intended for educational purposes and may require adjustments based on your specific hardware and network configuration. 

The golal is to have a Proxmox VE host running with a static IP address on your local network, ready to create virtual machines. Below is a simplified diagram of the setup:

```
                     Local Network (192.168.1.0/24)
        ───────────────────────────────────────────────────

                 +--------------------------------+
                 |        Proxmox VE Host         |
                 |--------------------------------|
                 |  Management Interface          |
                 |  IP: 192.168.1.10              |
                 |                                |
                 |  +--------------------------+  |
                 |  |        VM Lab            |  |
                 |  |--------------------------|  |
                 |  |  Guest OS / Services     |  |
                 |  |  IP: 192.168.1.50        |  |
                 |  +--------------------------+  |
                 |                                |
                 +--------------------------------+
                              |
                              |
                        Virtual Bridge (vmbr0)
                              |
                              |
                   +----------v-----------+
                   |   Router 192.168.1.1 |
                   |  (Gateway, DNS, DHCP)|
                   +----------+-----------+
                              |
                              |
                   +----------v-----------+
                   |      Internet        |
                   +----------+-----------+
```



## Setup Overview

The folloiwng setps will be covered in the next sections:
1. Proxmox VE Setup
2. Create Virtual Machine for Docker Containers
3. Docker Compose Setup

### Proxmox VE Setup
Here is a basic overview of the Proxmox VE setup, for a detailed installation guide, please refer to the [Proxmox VE Installation Guide](https://pve.proxmox.com/wiki/Installation) or [Proxmox Beginner’s Guide: Everything You Need to Get Started (YouTube)](https://www.youtube.com/watch?v=lFzWDJcRsqo) by WunderTech.

- Download Proxmox VE from [here](https://www.proxmox.com/en/downloads/category/iso-images-pve) and install it on your server hardware.
- Install from USB
  - set static IP for Proxmox host. Make sure to make DHCP reservations for the Proxmox host IP when your host network uses DHCP to avoid IP conflicts between.
  - After the installation was complete access Proxmox web interface `https://<proxmox-ip>:8006` from your web browser.
  - Next run the [`post-pve-install`](https://community-scripts.github.io/ProxmoxVE/scripts?id=post-pve-install) script to automate post-installation tasks.


### Create Virtual Machine for Docker Containers

Follow these steps to create a virtual machine (VM) in Proxmox VE that will host the Docker containers:
- In this example we will use a fully virtualized machine (VM) to host the Docker containers setup.
- Create a new VM in Proxmox VE with the desired specifications (CPU, RAM, Disk).
- Install a Ubuntu Server on the VM.
    - Download the Ubuntu Server ISO from [here](https://ubuntu.com/download/server) and upload it to Proxmox VE.
    - Mount the ISO to the VM and start the installation process.
    - Follow the installation prompts to set up the OS.




### Docker Compose Setup

#### Conatiners
The Docker Compose setup includes the following services:
- Portainer for Docker management
- Nginx Proxy Manager for managing proxy hosts
- DNS Proxy for local domain resolution 
- Uptime Kuma for monitoring services

#### Architecture
The setup consists of the following components:
- The DNS Proxy manages DNS entries `*.internal` for all containers and `*.portal` for external access. The internal DNS entries are automatically created. External access must be configured manually through the DNS Proxy admin interface.  
- The Reverse Proxy (Nginx Proxy Manager) can be configured to forward external requests (ports 80/443) from `*.portal` to the corresponding containers. For example, `uptime.kuma.portal` can be forwarded to `uptime-kuma.internal`.


```
                     ┌──────────────────────┐
                     │         HOST         │
                     │     192.168.1.50     │
                     │  (Access from LAN).  │
                     └──────────────┬───────┘
                                    │
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                           │                           │
        ▼                           ▼                           ▼
┌───────────────┐           ┌──────────────-─┐           ┌────────────────┐
│ Portainer     │           │ DNS Proxy      │           │ Reverse Proxy  │
│ portainer.intl│           │ dns-proxy.intl │           │ proxy.internal │
│ 9443:9443     │           │ 5380:5380      │           │ 80:80          │
│               │           │ 5354:53 TCP/UDP│           │ 443:443        │
└───────────────┘           └──────────────-─┘           │ 81:81 Admin    │
                                                         └─────┬──────────┘
                                                               │
                                                               ▼
                                                    ┌───────────────-─┐
                                                    │ Uptime-Kuma     │
                                                    │ uptime-kuma.intl│
                                                    │ (default port)  │
                                                    └───────────────-─┘

```



### DNS Proxy
The DNS Proxy service (DPS) is configured to resolve specific local domains to designated IP addresses. This is particularly useful for accessing services running in Docker containers using friendly domain names.

> __Note:__ I had to use the latest image because the previous one was not working > with the docker version 29.x.x

```yaml
  dns-proxy:
    image: defreitas/dns-proxy-server:latest
    container_name: dns-proxy    
    restart: unless-stopped
    ports:
      - "5380:5380"
      - "5354:53/tcp"
      - "5354:53/udp"
    environment:      
      TZ: "UTC"
      HOSTNAMES: "dns1.internal,dns2.internal" # Optional custom hostnames for the DNS server
      #MG_LOG_LEVEL: "DEBUG"     
      MG_DOMAIN: "internal"
      MG_REGISTER_CONTAINER_NAMES: "true"
    networks:
      - portainer_network
```


The option `MG_DOMAIN` and `MG_REGISTER_CONTAINER_NAMES` set to true allows the DNS Proxy to automatically register Docker container names under the specified domain. For example, if you have a container named `proxy` running, it can be accessed via `proxy.internal`.

From the host the DNS port can be accessed on port 5354 (both TCP and UDP). You can configure your system or other devices to use this DNS server for resolving local domains.

To set a custom DNS entry you can set the environment variable `HOSTNAMES: "foo1.internal, foo2.internal"`.

### Nginx Proxy Manager
Nginx Proxy Manager is set up to manage reverse proxy configurations for your Docker containers. It provides a user-friendly web interface to create and manage proxy hosts, SSL certificates, and other related settings.

Over the Port 81 web interface, you can create proxy hosts that forward requests from external domains (e.g., `service.portal`) to the corresponding internal Docker containers (e.g., `service.internal`).

### Setup Host DNS
To use the DNS Proxy for local domain resolution, you need to configure your host system to use the DNS Proxy server. This can typically be done by adding the HOST's IP address (e.g., 192.168.1.59:5354) as a DNS server in your network settings.


#### Example /etc/systemd/resolved.conf 

- DNS=127.0.0.1:5354 → Use local DNS server on port 5354.
- Domains=~internal ~portainer → Send queries for internal and portainer domains only to that local DNS.
- FallbackDNS=8.8.8.8 → All other queries go to Google DNS if local DNS can’t resolve them.

Essentially, it’s a split DNS setup: local DNS for internal domains, public DNS for everything else.

```
[Resolve]
DNS=127.0.0.1:5354
Domains=~internal ~portainer
FallbackDNS=8.8.8.8
```

