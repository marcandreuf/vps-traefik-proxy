#!/bin/bash

NEWTORK_NAME="test_traefik_proxy"


# Start Docker Compose
docker compose -f docker/docker-compose.proxy.yml down
