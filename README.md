# vps-traefik-proxy
Docker compose devops setup for a traefik proxy on a virtual private server

This repo is to do learning tests and technical documentation about how to setup a dockerised traefik proxy to serve web applications from a vps.


# Docker commands

Run base setup
```bash
docker compose -f docker/docker-compose.base.proxy.yml up

```
Test at `http://localhost:8080`




Get the proxy docker container ip address:
```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' test-app-stag-reverse-proxy-container
```

# Host setup for testing

Add the following lines to the hosts file. In linux `/etc/hosts`

```bash
# Traefik testing 
172.27.0.2  testlocalsetup.com
```

htpasswd -nb admin "test12345" | openssl base64

TODO:

- Test the proxy configuration locally.

  1. Prepare devcontainer with mkcert to generate certs.
  2. Add the CA certs for local testing to the base traefik docker compose
  3. Build up from the base:
    3.1 One setup for local dev with local certs
    3.2. One setup for cloudflare certs
    

- Implementa a small sample web app for testing.
- Add a second sample web site in another docker compose file
- Update the Readme file with all the technical details.
- Add a /docs as docs as code to this repo and use it as the 3rd web site for testing this setup.


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

### Key Changes from Production Setup
1. Replaced Let's Encrypt with mkcert certificates[7]
2. Removed Cloudflare DNS challenge requirements[1][4]
3. Simplified certificate management using static files[6][8]
4. Maintained IP whitelisting for local network access[3][5]

This configuration will provide browser-trusted HTTPS without certificate warnings while keeping all traffic local. The mkcert-issued certificates are valid for 2 years by default, making them ideal for development environments[7].

Citations:
[1] https://docs.docker.com/guides/traefik/
[2] https://community.traefik.io/t/traefik-on-docker-generating-service-pointing-to-localhost/24874
[3] https://www.reddit.com/r/Traefik/comments/k8g00d/docker_traefik_for_local_development_server/
[4] https://doc.traefik.io/traefik/routing/providers/docker/
[5] https://www.garygitton.fr/streamline-local-dev-with-traefik-3/
[6] https://doc.traefik.io/traefik/providers/docker/
[7] https://dev.to/agusrdz/setting-up-traefik-and-mkcert-for-local-development-48j5
[8] https://community.traefik.io/t/i-want-docker-to-listen-to-http-localhost-user-and-forward-to-http-portal-local-user-using-traefik/17631

---
Answer from Perplexity: pplx.ai/share