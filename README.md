## Sparkles Umbrel Community App Store

This store contains custom umbrelOS packages:

- **AIOStreams** (`sparkles-aiostreams`) — combines Stremio addons, debrid services, and Usenet sources into one configurable stream.
- **Caddy** (`sparkles-caddy`) — reverse proxy that sits in front of AIOStreams and serves it over HTTPS with a publicly trusted Let's Encrypt certificate.

### Add the store

Add this repository's Git URL in umbrelOS under **App Store → Community App Stores**.

Install **AIOStreams** first. Caddy declares it as a dependency, so umbrelOS will not offer Caddy until AIOStreams is installed.

## Configuration

umbrelOS 2.x exposes per-app settings under the app's **Settings → Environment variables**. Saving a value restarts the app with the new value applied.

### AIOStreams

| Variable | Default | Purpose |
| --- | --- | --- |
| `BASE_URL` | `http://<device>.local:4000` | Public URL of the instance, including protocol and port. Used to build installation links. |
| `AIOSTREAMS_AUTH` | empty | Operator accounts as comma-separated `username:password` pairs. |
| `AIOSTREAMS_AUTH_PERMISSIONS` | empty | Operator permissions as comma-separated `username=permission` entries. |
| `AIOSTREAMS_AUTH_REQUIRED` | `false` | Require a login to open the configure page. |
| `REQUEST_HEADER_OVERRIDES` | empty | Request header overrides as comma-separated `key:value` pairs. |

The encryption key (`SECRET_KEY`) is generated automatically from the device seed and is stable across restarts and updates. It must not be changed after the first start, otherwise saved source credentials can no longer be decrypted. Everything else is configured from the AIOStreams dashboard.

### Caddy

| Variable | Default | Purpose |
| --- | --- | --- |
| `DUCKDNS_SUBDOMAIN` | `homednx` | DuckDNS parent subdomain. The wildcard certificate covers `*.<parent>.duckdns.org`. |
| `AIOSTREAMS_SUBDOMAIN` | `aio` | Child subdomain that serves AIOStreams. |
| `DUCKDNS_TOKEN` | empty | DuckDNS API token from <https://www.duckdns.org>. |
| `CADDY_PORT` | `40444` | Host port that publishes the HTTPS site. |
| `CADDY_UPSTREAM` | `http://sparkles-aiostreams_aiostreams_1:3000` | Address Caddy proxies requests to. The default points at the AIOStreams app on umbrelOS's shared Docker network. |

The resulting AIOStreams URL is `https://<AIOSTREAMS_SUBDOMAIN>.<DUCKDNS_SUBDOMAIN>.duckdns.org`, for example `https://aio.homednx.duckdns.org`.

Caddy serves two entry points:

- **HTTPS on port 443 inside the container**, published to the host on `CADDY_PORT` (40444 by default). This is the wildcard site for `*.<parent>.duckdns.org`.
- **HTTP on port 80 inside the container**, used by umbrelOS's app gateway. The app proxy is not published to the host, so this path is only reachable through umbrelOS.

AIOStreams keeps its own app proxy, so it stays reachable through umbrelOS regardless of the Caddy settings.

#### Prerequisites

1. **Create the DuckDNS parent subdomain.** Sign in at <https://www.duckdns.org> and create a subdomain, for example `homednx`. Copy the API token from the top of the page. The token is a 36-character UUID.
2. **Point DuckDNS at this device's LAN address.** In the DuckDNS domain settings, set the IP to this device's **LAN IP address**. This is a LAN-only setup: no router port forwarding and no public DNS record are needed. If your public IP is what you want to use instead, set the public IP there and forward the port on your router.
3. **Set the app settings.** In the Caddy app's **Settings → Environment variables**, set at least `DUCKDNS_TOKEN`. Adjust `DUCKDNS_SUBDOMAIN`, `AIOSTREAMS_SUBDOMAIN` and `CADDY_PORT` to match your setup, then restart the app.
4. **Open the published port on your LAN.** Caddy listens on `CADDY_PORT` (40444 by default). Reach AIOStreams at `https://aio.homednx.duckdns.org:40444` unless you map that port to 443 on your LAN.

#### Why the HTTPS port is not 443

umbrelOS 2.0 binds the host ports `80` and `443` itself for its dashboard, and it reserves them when allocating ports to apps. An app cannot publish either one, so Caddy uses a high host port instead. If you want the URL without a port, map `40444` to `443` in your LAN reverse proxy, or forward the router's external `443` to `40444` when you want internet access.

The certificate is issued by Let's Encrypt with the **DNS-01 challenge**, because the HTTP-01 and TLS-ALPN-01 challenges need to reach the container on port 80 or 443. DNS-01 only needs the DuckDNS API token, so it works no matter how the ports are mapped. DuckDNS stores the challenge record on the parent domain, which is what lets one certificate cover the whole wildcard.

#### Setting the AIOStreams base URL

AIOStreams builds its install links from `BASE_URL`. To make them point at the HTTPS URL, set `BASE_URL` in the AIOStreams app's **Settings → Environment variables** to:

```
https://aio.homednx.duckdns.org
```

Leave it at the default `http://<device>.local:4000` if you do not use Caddy.

#### Certificates

The certificate is issued by Let's Encrypt and is publicly trusted, so browsers accept it without any manual trust step. There is no internal CA to install.

Caddy stores the certificate, the ACME account and the certificate authority agreement under `${APP_DATA_DIR}/data`, so they survive restarts and app updates. Caddy renews the certificate automatically about 30 days before it expires.

#### The Caddyfile

The Caddyfile is generated by the app's `pre-start` hook into `${APP_DATA_DIR}/Caddyfile` on every start and every app update, using the values from the app settings. Do not edit it by hand; your changes are overwritten. The `hooks` directory is part of umbrelOS's app update set, so the configuration stays in sync with the app settings after an update.

The token is not written into the Caddyfile. The Caddyfile refers to the `DUCKDNS_TOKEN` environment variable, and Caddy reads it from the container's environment at runtime. Until the token is set, Caddy serves only the plain-HTTP site and the app stays reachable through umbrelOS.

## Development

Each package lives in a directory whose name matches its `id`. Validate the manifests and the Compose configuration without starting containers:

```sh
docker compose -f sparkles-aiostreams/docker-compose.yml config
docker compose -f sparkles-caddy/docker-compose.yml config
```

umbrelOS removes the `app_proxy` service from the Compose file at runtime, so a bare `docker compose config` needs an overlay that provides it:

```sh
printf 'services:\n  app_proxy:\n    image: app-proxy-config-only\n' > /tmp/app_proxy_overlay.yml
docker compose -f sparkles-caddy/docker-compose.yml -f /tmp/app_proxy_overlay.yml config
```
