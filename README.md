# Traefik development environments setup

**This repo contains helping code to document and implement Traefik web proxies.**

I used docker compose to setup each traefik proxy that can be used to run this infrastructure locally on a virtual private server.

> [!NOTE] This is the setup that I use test and publish my online projects on my VPSs. For now, I am all about self hosting and minimise costs. 

<br/>

# Host machine notes

## Local configuration

> [!IMPORTANT] Required for local dev

For each development environment there is a `docker/{env}` folder where env is `local, staging, ...`
For each env we need to **copy the `docker/{env}/.env.dist` file into its `docker/{env}/.env`** and 
ammend the configuration as required, see the comments in the file.

## Hosts file
> [!IMPORTANT] Required for local dev

Setup the hosts file to point to the sample test domain. i.e in linux add the following line to the `/etc/hosts` file.

```bash
# Get the container ip address of the traefik service.
# i.e run the command `docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}} <container_name_or_id>`

172.27.0.2  tf-dashboard.testlocalsetup.com
```
<br/>

# Traefik notes

## Traefik local dev env

The traefik playground at `docker/traefik-local` is a configuration to test and learn traefik for a local dev with https using any test domain name that we want. 

**TLDR:**
1. We create the self signed certificates 
2. We add the CA certificate to the browser/s
3. We setup the DNS resolver on the network of on the hosts file.
4. We can work with our local https traefik proxy serving dev apps within our network or dev machine.

### Traefik Logs

Monitor the traefik logs at `docker/local/traefik/logs`. We can change the log level in the docker/local/traefik/traefil.yml 'log.level' key.

When the traefik.yml `api.insecure` is set to `true` test the Traefik dashboard at `http://localhost:8080`.

When the network dns/hosts file is pointing to the proxy container (see details below in the hosts notes), the basic auth is configured via labels and the `api.insecure` is set to `false` open at `https://tf-dashboard.testlocalsetup.com/`.

### Browser local trusted certificates.

We want to use self signed certificates that are managed by us as the Lets Encrypt certs will require us to have a public domain. For a local dev env on the dev machine or our local network we can have more freedom if we can define any 'test.local.domain.com' as we want. In my case I used `*.testlocalsetup.com`.

Therefore, we can create local trusted certificates from a local CA and avoid having to accept the risk warnings on the browsers, every time that we restart the local proxy dev env. 

For this we need to do the following:

1. Run the this command to generate the certificates.
```bash
docker compose -f docker/local/docker-compose.certs.yml run --rm mkcert
```
New certificates shold be created at the `docker/local/traefik/certs` folder.

> [!IMPORTANT]  For security we choose to run the mkcert tool inside its own container to only generate the certificate files and we avoid installing this tool on the host machine. 

2. Add the `/docker/local/certs/rootCA.pem` to the browser settings Certificate Authorities.
  The new certificate authority should appear with the Certificate Name `mkcert development CA`

> [!NOTE] We could automte this setp with a set of script for each OS. 


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

Local proxyied apps development environment:

```bash

# Start
docker compose -f docker/local/docker-compose.proxy.yml up
# or 
docker compose -f docker/local/docker-compose.proxy.yml up --force-recreate

# Stop
docker compose -f docker/local/docker-compose.proxy.yml stop

# For quick tests
docker compose -f docker/local/docker-compose.proxy.yml restart

# Stop and remove
docker compose -f docker/local/docker-compose.proxy.yml down
```

<br/>



# References:

* Traefik with Letsencrypt certs of a public domain using Cloudflare DNS. [Youtube: Christian Lempa: Simple HTTPs for Docker! // Traefik Tutorial (updated)](https://www.youtube.com/watch?v=-hfejNXqOzA)

<br/>

# NOTES:

## Key struggles:

* Setup self signed certs for local dev without a public domain. The key point is to setup the
tls.certificates into a dynamic config file, not in the static traefik.yml config file.
[text](docker/local/docker-compose.proxy.yml)
