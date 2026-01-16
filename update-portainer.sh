#!/usr/bin/env bash

set -e

sudo docker compose -f portainer-compose.yaml down
git pull
sudo docker compose -f portainer-compose.yaml up -d
