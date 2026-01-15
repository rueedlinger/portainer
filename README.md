# Portainer

This repository contains a Docker Compose setup for Portainer, a lightweight management UI that allows you to easily manage your Docker environments. That can be used inside a home lab or small server environment, like Proxmox VE.

## Features
- Portainer for Docker management
- Nginx Proxy Manager for managing proxy hosts
- DNS Proxy for local domain resolution 
- Uptime Kuma for monitoring services


## Diagram
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

