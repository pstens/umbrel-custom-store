## Sparkles Umbrel Community App Store

This store contains custom umbrelOS packages:

- **AIOStreams** (`sparkles-aiostreams`) — combines Stremio addons, debrid services, and Usenet sources into one configurable stream.
- **AIOMetadata** (`sparkles-aiometadata`) — catalogs and metadata for AIOStreams, with a German catalog template.
- **Paperless Sweeper** (`sparkles-paperless-sweeper`) — every night, shares the correspondents, tags, document types and storage paths that Paperless-ngx users create with the household group.
- **Deal Alerts** (`sparkles-deal-alerts`) — Telegram alerts for retoura tool deals and for construction finds in your product-tester groups.
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

#### One genre list for UHF

UHF's Filme and Serien tabs show one tile per genre per library, and every AIOMetadata catalog carries a genre list. A small filter in front of AIOMetadata (the `aiometadata` service; the server itself runs as `server`) keeps the full genre list only on the catalogs in `GENRE_CATALOG_IDS`, which are the two "Beliebt" catalogs by default. Every other catalog gets a single "Alle" genre that opens the whole catalog. UHF then shows one tile per catalog, such as "Alle · Neu im Kino", plus one per genre of "Beliebt", such as "Drama · Beliebt". Catalogs whose genre is required keep their list, because they can't be browsed without one. After changing `GENRE_CATALOG_IDS`, refresh the AIOMetadata catalogs in AIOStreams.

Fixed by the app, not settable: `PORT`, `NODE_ENV`, the SQLite database and cache paths under `${APP_DATA_DIR}/data/addon`, and `REDIS_URL`, which points at the bundled Redis 8 (capped at 512 MB). `MOVIELENS_CRED_KEY` is derived from the device seed. Do not change it, otherwise stored MovieLens logins can no longer be decrypted.

#### German catalogs

[`sparkles-aiometadata/templates/germany.json`](sparkles-aiometadata/templates/germany.json) is an AIOMetadata setup template. It replaces the catalog lineup with these catalogs, for movies and for series each:

| Catalog | What it lists |
| --- | --- |
| Im Trend | AIOMetadata's built-in TMDB trending catalog (worldwide, today), movies and series. AIOMetadata names it "TMDB Trending"; rename it on the configure page if you like. |
| Neu im Kino | Movies released in German cinemas within the last month. |
| Neu auf Streaming | Movies: released within the last year and now on German subscription, free or ad-supported streaming. Series: scripted shows and miniseries that premiered within the last month on German streaming. |
| Beliebt | Most popular titles on German subscription, free or ad-supported streaming. Series: scripted shows and miniseries that premiered within the last 10 years. |
| Demnächst | Movies: German theatrical releases from today on. Series: premieres from today on, worldwide, because TMDB has no German air dates for series. |
| Netflix, Prime Video, Disney+, Apple TV, WOW, HBO Max, Paramount+, RTL+, Joyn, Crunchyroll | Most popular titles on that service in Germany. Rentals and purchases are excluded. Series: premiered within the last 10 years. |

Date windows use AIOMetadata 3.8.3's named windows (today, last month, last year, last 10 years). That version has no rolling "last N days" windows.

TMDB popularity is global, so "Im Trend" and "Beliebt" mean popular titles that are available or released in Germany. There is no TMDB ranking per country.

To apply it, open AIOMetadata → **Setup** → **Share a setup**, load

```
https://raw.githubusercontent.com/pstens/umbrel-custom-store/master/sparkles-aiometadata/templates/germany.json
```

then preview and apply. The template disables the built-in catalogs, which removes the long genre lists in UHF. Add the manifest URL to AIOStreams afterwards, or refresh it there. The Setup page does not carry the metadata language, so set **German** as the language on the configure page yourself.

The streaming catalogs use TMDB's German watch-provider IDs. If a row stays empty, pick that service in the Setup page's streaming picker with region **Germany** instead. The picker looks the IDs up live.

### Paperless Sweeper

Paperless-ngx makes every correspondent, tag, document type and storage path the AI or a user creates private to that user, so other users can't see it and the AI creates duplicates for them. The sweeper removes the owner from those objects and gives the household group view and change permissions. It runs once at start and then every night. The app page lists the latest sweeps and has a **Run now** link.

| Variable | Default | Purpose |
| --- | --- | --- |
| `PAPERLESS_TOKEN` | empty | API token of a Paperless superuser, such as `admin`. |
| `HOUSEHOLD_GROUP` | `Haushalt` | Paperless group that gets view and change permissions. |
| `SWEEP_HOUR_UTC` | `2` | Hour of the nightly sweep in UTC, at minute 30. |

It reaches Paperless at `http://paperless_webserver_1:8000` on umbrelOS's shared Docker network. If two users each own an object with the same name, that object fails with a name clash and is listed under FAILED. Merge the two by hand.

### Deal Alerts

Checks the retoura category every 30 minutes, sorted by discount, and stops at the first item below the minimum discount. Items whose name contains one of your words get one Telegram message with the product photo and purchase link, and another if the price drops further. It also reads your Telegram groups as your own account. A post with a link is forwarded when it contains one of your words, or when [jev](https://github.com/feder-cr/jev) scores it at or above the threshold. jev is a small yes/no model that runs locally in the app's `jev` service (0.9B parameters, about 1 GB of RAM, x86-64 only). Your account forwards the original post into your chat with the bot, and the bot adds a note below it with the reason: the matched word, or jev's score and the category it picked from `TG_TOPIC`. Channels that block forwarding get a copy of the text and photo instead.

Words, discount and threshold are set by messaging the bot, and the first chat that writes to it owns it:

| Command | Effect |
| --- | --- |
| `/add Bohrhammer, Makita` | Watch these words in retoura names and group posts. |
| `/del Makita` | Stop watching a word. |
| `/discount 60` | Minimum retoura discount in percent (default 60). |
| `/threshold 0.2` | jev score (0–1) a group post without a watched word needs (default 0.2). |
| `/quiet 22 7` | Messages between 22:00 and 7:00 (Berlin time) arrive without sound; `/quiet off` turns this off. |
| `/check` | Check retoura now. |
| `/list` | Show the settings. |

The bot shows these commands in Telegram's `/` menu. With no words, every retoura item at or above the discount counts.

jev is trained on English, and on German posts its scores overlap: in a test, a Bohrhammer scored 0.31 and a Baustrahler 0.17, while a winter jacket scored 0.29 and socks 0.20 (picked as "work clothing"). Watched words are the reliable filter; jev only adds finds no word covers, with noise.

Setup:

1. Telegram → @BotFather → `/newbot`, and put the token in `BOT_TOKEN`. Send `/start` to the new bot.
2. my.telegram.org → **API development tools**, create an app, and put the api_id and api_hash in `TG_API_ID` and `TG_API_HASH`.
3. Open the app page, enter your phone number and the code Telegram sends you, plus your two-step password if you use one. The session is stored under `${APP_DATA_DIR}/data`.

On first start the app installs `telethon` into its data directory and downloads jev's binary and model (about 700 MB, checked against the release's SHA-256 sums). Delete `data/py` or `data/jev` there to get them again.

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
docker compose -f sparkles-paperless-sweeper/docker-compose.yml config
docker compose -f sparkles-deal-alerts/docker-compose.yml config
```

umbrelOS removes the `app_proxy` service from the Compose file at runtime, so a bare `docker compose config` needs an overlay that provides it:

```sh
printf 'services:\n  app_proxy:\n    image: app-proxy-config-only\n' > /tmp/app_proxy_overlay.yml
docker compose -f sparkles-caddy/docker-compose.yml -f /tmp/app_proxy_overlay.yml config
```
