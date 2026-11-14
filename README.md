## Sparkles Umbrel Community App Store

This store contains custom umbrelOS packages:

- **AIOStreams** (`sparkles-aiostreams`) — combines Stremio addons, debrid services, and Usenet sources into one configurable stream.
- **Caddy** (`sparkles-caddy`) — reverse proxy that sits in front of AIOStreams.

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
| `CADDY_UPSTREAM` | `http://sparkles-aiostreams_aiostreams_1:3000` | Address Caddy proxies requests to. The default points at the AIOStreams app on umbrelOS's shared Docker network. |
| `CADDY_ADDRESS` | `http://` | Site address Caddy serves. Keep the port at `80`: that is the port umbrelOS connects to, so a different port makes the app unreachable. |

`Caddyfile` in this package holds the Caddy configuration. Caddy expands `{$CADDY_ADDRESS}` and `{$CADDY_UPSTREAM}` from its own environment when it loads the file, so the values set in umbrelOS apply without regenerating the file.

Caddy's configuration and certificate storage persist under `${APP_DATA_DIR}/data`. The `Caddyfile` itself lives at `${APP_DATA_DIR}/Caddyfile` and is installed with the app; it is not replaced by app updates, so changes to it only take effect after a reinstall.

## Development

Each package lives in a directory whose name matches its `id`. Validate the manifests and the Compose configuration without starting containers:

```sh
docker compose -f sparkles-aiostreams/docker-compose.yml config
docker compose -f sparkles-caddy/docker-compose.yml config
```
