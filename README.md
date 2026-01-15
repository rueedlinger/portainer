# portainer

This repository contains a Docker Compose setup for Portainer, a lightweight management UI that allows you to easily manage your Docker environments. That can be used inside a home lab or small server environment, like Proxmox VE.

## Features
- Portainer for Docker management
- Nginx Proxy Manager for managing proxy hosts
- DNS Proxy for local domain resolution 
- Uptime Kuma for monitoring services

## Example
To test the DNS resolution for the local domain `proxy.local`, you can use the `dig` command as follows:

```bash
dig @127.0.0.1 -p 53 proxy.local

; (1 server found)
;; global options: +cmd
;; Got answer:
;; WARNING: .local is reserved for Multicast DNS
;; You are currently testing what happens when an mDNS query is leaked to DNS
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 29213
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;proxy.local.			IN	A

;; ANSWER SECTION:
proxy.local.		30	IN	A	172.20.0.3

;; Query time: 80 msec
;; SERVER: 127.0.0.1#53(127.0.0.1)
;; WHEN: Tue Jan 13 23:43:18 CET 2026
;; MSG SIZE  rcvd: 56
```

Test the custom dns entry for portainer.docker:

```bash
@127.0.0.1 -p 53 api.portainer.docker
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 16325
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;api.portainer.docker.		IN	A

;; ANSWER SECTION:
api.portainer.docker.	255	IN	A	192.168.0.1

;; Query time: 48 msec
;; SERVER: 127.0.0.1#53(127.0.0.1)
;; WHEN: Wed Jan 14 00:20:03 CET 2026
;; MSG SIZE  rcvd: 65
```


## Configure Proxmox VE
tbd

https://docs.docker.com/engine/install/ubuntu/
```
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
````

```
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

```
sudo systemctl status docker

sudo systemctl start docker

sudo docker run hello-world
````

```
sudo docker compose -f portainer-compose.yaml up -d
```


sudo vim /etc/systemd/resolved.conf 

[Resolve]
DNS=127.0.0.1
Domains=~docker
DNSStubListener=no

sudo systemctl restart systemd-resolved