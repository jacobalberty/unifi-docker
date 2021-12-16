# Unifi controller with traefik version 2

To run this, create a .env file, look at the .env.example for example values.

Then start the service with
`docker-compose up -d`

## Traefik & HTTPS

Since the unifi controller runs on HTTPS, traefik will generate an error if not the following value is provided with the traefik container.
`serverstransport.insecureskipverify=true`

This ignores the unsecure HTTPS protocol from the container

Read more about this here: https://doc.traefik.io/traefik/reference/static-configuration/cli/
