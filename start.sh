#!/bin/bash

NEWTORK_NAME="test_traefik_proxy"

# Create the external network if it doesn't exist
docker network ls | grep -q "$NEWTORK_NAME" || \
docker network create --driver bridge "$NEWTORK_NAME"

# Start Docker Compose
docker compose -f docker/docker-compose.proxy.yml up -d
