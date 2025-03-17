# Traefik development environments setup

**This repo contains helping code to document and implement Traefik web proxies.**

I used docker compose to setup each traefik proxy that can be used to run this infrastructure locally on a virtual private server.

> This is the setup that I use test and publish my online projects on my VPSs. For now, I am all about self hosting and minimise costs. 

<br/>

# Host machine notes

## Local configuration

> Required for local dev

For each development environment there is a `docker/{env}` folder where env is `local, staging, ...`
For each env we need to **copy the `docker/{env}/.env.dist` file into its `docker/{env}/.env`** and 
ammend the configuration as required, see the comments in the file.

## Hosts file
> Required for local dev

Setup the hosts file to point to the sample test domain. i.e in linux add the following line to the `/etc/hosts` file.

```bash
# Get the container ip address of the traefik service.
# i.e run the command `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} <container_name_or_id>`

172.27.0.2  tf-dashboard.testlocalsetup.com
```
<br/>

# Traefik notes

## Traefik local dev env

The traefik configuration at `docker/traefik-local` is a configuration to test and learn traefik on a local dev env.

### Observability

Monitor the traefik logs at `docker/local/traefik/logs`

When the traefik.yml `api.insecure` is set to `true` open the Traefik dashboard at `http://localhost:8080`.

When the hosts file is pointing to the proxy container (see details below in the hosts notes), the basic auth is configured via labels and the `api.insecure` is set to `false` open at `https://tf-dashboard.testlocalsetup.com/`.


## Basic Auth for traefik dashboard.

To create the basic credentials for the dashboard use this command and copy paste the generated line as the value for the proxy container label "traefik.http.middlewares.auth.basicauth.users"
```bash
# Install htpasswd package if needed. 
# sudo apt-get install apache2-utils
echo $(htpasswd -nb admin 'test12345') | sed -e s/\\$/\\$\\$/g
# i.e admin:$$apr1$$LEDbM....
```

<br/>

# Docker notes

Use this command to observer the running containers.
```bash
docker stats
```

Local development environment:

```bash
# Start
docker compose -f docker/local/docker-compose.proxy.yml up

# Stop
docker compose -f docker/local/docker-compose.proxy.yml stop

# For quick tests
docker compose -f docker/local/docker-compose.proxy.yml restart

# Stop and remove
docker compose -f docker/local/docker-compose.proxy.yml down
```








<br/><br/><br/><br/><br/><br/><br/>

----
----
> Content Pending review


# Create CA and certificates
Run this manually to test

```bash
mkdir -p traefik/certs
mkcert -install
mkcert -cert-file traefik/certs/cert.pem -key-file traefik/certs/key.pem "tf-dashboard.testlocalsetup.com" "*.testlocalsetup.com" localhost 127.0.0.1 ::1
```


Here's how to configure Traefik for local development with trusted HTTPS certificates:

### 1. Local Certificate Setup with mkcert
```bash
# Install mkcert
sudo apt install libnss3-tools
curl -sSL https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64 -o mkcert
chmod +x mkcert
sudo mv mkcert /usr/local/bin/

# Create CA and certificates
mkdir -p traefik/certs
mkcert -install
mkcert -cert-file traefik/certs/cert.pem -key-file traefik/certs/key.pem "tf-dashboard.testlocalsetup.com" "*.testlocalsetup.com" localhost 127.0.0.1 ::1
```

### 2. Required Docker Compose Modifications
```yaml
services:
  reverse-proxy:
    volumes:
      - ./traefik/certs:/certs  # Add this volume
    command:
      - "--providers.file.filename=/traefik.yml"
      - "--entrypoints.https.tls.certificates=[{certFile:/certs/cert.pem,keyFile:/certs/key.pem}]"
```

### 3. Essential Traefik Configuration (traefik.yml)
```yaml
entryPoints:
  https:
    address: ":443"
    http:
      tls:
        certificates:
          - certFile: /certs/cert.pem
            keyFile: /certs/key.pem

# Remove cloudflare certresolver for local setup
certificatesResolvers: {}  
```

### 4. Service Label Configuration
```yaml
labels:
  - traefik.http.routers.tf_dashboard.tls=true
  - traefik.http.routers.tf_dashboard.entrypoints=https
  - traefik.http.routers.tf_dashboard.rule=Host(`tf-dashboard.testlocalsetup.com`)
  - traefik.http.routers.tf_dashboard.service=api@internal
  - traefik.http.routers.tf_dashboard.middlewares=traefik-auth
```

### 5. Verification Steps
```bash
# Check certificate chain
openssl s_client -connect localhost:443 -showcerts

# Test HTTPS access
curl -vk --resolve tf-dashboard.testlocalsetup.com:443:127.0.0.1 \
  https://tf-dashboard.testlocalsetup.com
```

