## Sparkles Umbrel Community App Store

This store contains custom umbrelOS packages:

- **AIOStreams** (`sparkles-aiostreams`) — combines Stremio addons, debrid services, and Usenet sources into one configurable stream.
- **AIOMetadata** (`sparkles-aiometadata`) — catalogs and metadata for AIOStreams, with a German catalog template.
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

### AIOMetadata

Every server setting from AIOMetadata's `.env.example` (148 of them) is listed under **Settings → Environment variables**, with its upstream description as the note. Empty values are removed before the server starts, so AIOMetadata's own defaults apply. The full reference is AIOMetadata's [ENVIRONMENT_VARIABLES.md](https://github.com/cedya77/aiometadata/blob/dev/docs/ENVIRONMENT_VARIABLES.md).

The settings to look at first:

| Variable | Default | Purpose |
| --- | --- | --- |
| `HOST_NAME` | `http://<device>.local:3232` | URL that clients use for manifests and artwork. With Caddy, set `https://meta.<parent>.duckdns.org:40444`. |
| `BUILT_IN_TMDB_API_KEY` | empty | TMDB key used for every config that has no key of its own. It stays on the server. The German template needs TMDB. |
| `TMDB_API_KEY` | empty | TMDB key prefilled on the configure page. It is sent to every visitor's browser. |
| `ADMIN_KEY` | derived from the device seed | Admin API key. It also signs the artwork proxy URLs. |
| `TZ` | `Europe/Berlin` | Server time zone. Date windows like "next 90 days" are calculated in this zone. |
| `CACHE_WARM_LANGUAGE` | `de-DE` | Language used to pre-warm the popular catalogs. |

Fixed by the app, not settable: `PORT`, `NODE_ENV`, the SQLite database and cache paths under `${APP_DATA_DIR}/data/addon`, and `REDIS_URL`, which points at the bundled Redis 8 (capped at 512 MB). `MOVIELENS_CRED_KEY` is derived from the device seed. Do not change it, otherwise stored MovieLens logins can no longer be decrypted.

#### German catalogs

[`sparkles-aiometadata/templates/germany.json`](sparkles-aiometadata/templates/germany.json) is an AIOMetadata setup template. It replaces the catalog lineup with these catalogs, for movies and for series each:

| Catalog | What it lists |
| --- | --- |
| Im Trend | Movies: released in Germany in the last 60 days. Series: episodes aired in the last 14 days on German streaming. Sorted by TMDB popularity. |
| Beliebt | Most popular titles available on German subscription, free or ad-supported streaming. |
| Demnächst | Movies: German theatrical releases in the next 90 days. Series: premieres in the next 90 days, worldwide, because TMDB has no German air dates for series. |
| Netflix, Prime Video, Disney+, Apple TV, WOW, HBO Max, Paramount+, RTL+, Joyn, Crunchyroll | Most popular titles on that service in Germany. Rentals and purchases are excluded. |

TMDB popularity is global, so "Im Trend" and "Beliebt" mean popular titles that are available or released in Germany. There is no TMDB ranking per country.

To apply it, open AIOMetadata → **Setup** → **Share a setup**, load

```
https://raw.githubusercontent.com/pstens/umbrel-custom-store/master/sparkles-aiometadata/templates/germany.json
```

then preview and apply. The template also sets the metadata language to `de-DE`. It disables the built-in catalogs, which removes the long genre lists in UHF. Add the manifest URL to AIOStreams afterwards, or refresh it there.

The streaming catalogs use TMDB's German watch-provider IDs. If a row stays empty, pick that service in the Setup page's streaming picker with region **Germany** instead. The picker looks the IDs up live.

### Caddy

| Variable | Default | Purpose |
| --- | --- | --- |
| `DUCKDNS_SUBDOMAIN` | `homednx` | DuckDNS parent subdomain. The wildcard certificate covers `*.<parent>.duckdns.org`. |
| `AIOSTREAMS_SUBDOMAIN` | `aio` | Child subdomain that serves AIOStreams. |
| `DUCKDNS_TOKEN` | empty | DuckDNS API token from <https://www.duckdns.org>. |
| `CADDY_PORT` | `40444` | Host port that publishes the HTTPS site. |
| `CADDY_UPSTREAM` | `http://sparkles-aiostreams_aiostreams_1:3000` | Address Caddy proxies requests to. The default points at the AIOStreams app on umbrelOS's shared Docker network. |
| `AIOMETADATA_SUBDOMAIN` | `meta` | Child subdomain that serves AIOMetadata. Answers 502 until the AIOMetadata app is installed. |
| `AIOMETADATA_UPSTREAM` | `http://sparkles-aiometadata_aiometadata_1:3232` | Address Caddy proxies AIOMetadata requests to. |

Caddy serves three entry points:

| Entry point | Certificate | Reachable at |
| --- | --- | --- |
| Wildcard site | Let's Encrypt, publicly trusted | `https://<child>.<parent>.duckdns.org` on host port `CADDY_PORT` |
| Local site | Caddy local CA, **not** publicly trusted | `https://umbrel.local` (the device's own name) on host port `CADDY_PORT` |
| Plain HTTP | none | inside the container on port 80, used by umbrelOS's app gateway |

AIOStreams keeps its own app proxy, so it stays reachable through umbrelOS regardless of the Caddy settings.

#### Prerequisites

1. **Create the DuckDNS parent subdomain.** Sign in at <https://www.duckdns.org> and create a subdomain, for example `homednx`. Copy the API token from the top of the page. The token is a 36-character UUID.
2. **Point DuckDNS at this device's LAN address.** In the DuckDNS domain settings, set the IP to this device's **LAN IP address**. This is a LAN-only setup: no router port forwarding and no public DNS record are needed. If your public IP is what you want to use instead, set the public IP there and forward the port on your router.
3. **Set the app settings.** In the Caddy app's **Settings → Environment variables**, set at least `DUCKDNS_TOKEN`. Adjust `DUCKDNS_SUBDOMAIN`, `AIOSTREAMS_SUBDOMAIN` and `CADDY_PORT` to match your setup, then restart the app.
4. **Open the published port on your LAN.** Caddy listens on `CADDY_PORT` (40444 by default). Reach AIOStreams at `https://aio.homednx.duckdns.org:40444` unless you map that port to 443 on your LAN.
5. **Allow private DuckDNS answers.** Your router may block DNS answers that point at private IPs (DNS-rebind protection). Whitelist `duckdns.org` or add a local DNS override for `*.homednx.duckdns.org` to this device's LAN IP.

#### Why the HTTPS port is not 443

umbrelOS 2.0 binds the host ports `80` and `443` itself for its dashboard, and it reserves them when allocating ports to apps. An app cannot publish either one, so Caddy uses a high host port instead. If you want the URL without a port, map `40444` to `443` in your LAN reverse proxy, or forward the router's external `443` to `40444` when you want internet access.

The wildcard certificate is issued by Let's Encrypt with the **DNS-01 challenge**, because the HTTP-01 and TLS-ALPN-01 challenges need to reach the container on port 80 or 443. DNS-01 only needs the DuckDNS API token, so it works no matter how the ports are mapped. DuckDNS stores the challenge record on the parent domain, which is what lets one certificate cover the whole wildcard.

#### Setting the AIOStreams base URL

AIOStreams builds its install links from `BASE_URL`. To make them point at the HTTPS URL, set `BASE_URL` in the AIOStreams app's **Settings → Environment variables** to:

```
https://aio.homednx.duckdns.org:40444
```

Drop `:40444` if you map that port to 443 on your LAN. Leave it at the default `http://<device>.local:4000` if you do not use Caddy.

#### Certificates

The **DuckDNS wildcard** `*.<parent>.duckdns.org` is signed by Let's Encrypt and is publicly trusted, so clients accept it without any manual step.

The **local site** (the device's own `umbrel.local` and bare hostname) is signed by **Caddy's own local authority**. Clients show a security warning until they trust the Caddy root CA, see below. The root key is persisted under `${APP_DATA_DIR}/data/data/caddy/pki/authorities/local`, so the CA stays the same across restarts and updates. Caddy stores the certificate and the ACME account under `${APP_DATA_DIR}/data`, so they survive restarts and app updates, and renews the certificate about 30 days before it expires.

Caddy runs with `auto_https disable_redirects`, so the plain-HTTP site on port 80 keeps serving the umbrelOS app gateway instead of redirecting to HTTPS.

#### Trusting the local certificate

Download the Caddy root CA from the local site:

```sh
curl -k https://umbrel.local:40444/caddy-ca.crt -o caddy-ca.crt
```

The file is also served over plain HTTP on the app gateway port, and the path is the same on every site.

Then install it as a trusted root on each device that should use the local hostname:

**macOS**

```sh
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain caddy-ca.crt
```

**Linux**

```sh
sudo cp caddy-ca.crt /usr/local/share/ca-certificates/caddy-ca.crt
sudo update-ca-certificates
```

**Windows**

Open `caddy-ca.crt` and choose **Install Certificate → Local Machine → Place all certificates in the following store → Trusted Root Certification Authorities**, then finish the wizard.

**Android**

Settings → Security → Encryption & credentials → Install a certificate → CA certificate, and pick the downloaded file.

**iOS / iPadOS**

Mail the certificate to yourself, open the attachment, then Settings → General → About → Certificate Trust Settings and enable full trust for the Caddy root.

The certificate appears in the trust store as **Caddy Local Authority**. To remove it again, delete the entry from the trust store.

#### The Caddyfile

The app's `pre-start` hook writes `${APP_DATA_DIR}/Caddyfile` on every start. umbrelOS copies `hooks` on app updates but not a plain Caddyfile, so the config lives in the hook. The heredoc is not expanded by the shell: site addresses use `{$VAR}`, which Caddy fills in from the container environment when it loads the config. The token is read with `{env.DUCKDNS_TOKEN}` at runtime and is never written to disk. Edits to the generated file are overwritten on the next start.

## Development

Each package lives in a directory whose name matches its `id`. Validate the manifests and the Compose configuration without starting containers:

```sh
docker compose -f sparkles-aiostreams/docker-compose.yml config
docker compose -f sparkles-caddy/docker-compose.yml config
docker compose -f sparkles-aiometadata/docker-compose.yml config
```

umbrelOS removes the `app_proxy` service from the Compose file at runtime, so a bare `docker compose config` needs an overlay that provides it:

```sh
printf 'services:\n  app_proxy:\n    image: app-proxy-config-only\n' > /tmp/app_proxy_overlay.yml
docker compose -f sparkles-caddy/docker-compose.yml -f /tmp/app_proxy_overlay.yml config
```
