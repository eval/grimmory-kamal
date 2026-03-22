# Grimmory Kamal Deployment

Deploy [Grimmory](https://github.com/grimmory-tools/grimmory) (formerly Booklore) to your own server using [Kamal 2](https://kamal-deploy.org/).

## Prerequisites

- A server with SSH access
- A GitHub account (for pulling the BookLore image from GHCR)

## Setup

### 1. Clone and run setup

```bash
git clone https://github.com/eval/grimmory-kamal.git
cd grimmory-kamal
./bin/setup
```

### 2. Configure

Edit `mise.local.toml` with your values:

```toml
[env]
# Server configuration
BOOKLORE_HOST = "203.0.113.42"             # Your server IP
BOOKLORE_DOMAIN = "booklore.example.com"   # Your domain
BOOKLORE_TZ = "Europe/Copenhagen"          # Your timezone (optional)

# GitHub Container Registry credentials
# Create a PAT at https://github.com/settings/tokens with read:packages and write:packages scopes
KAMAL_REGISTRY_USERNAME = "your-github-username"
KAMAL_REGISTRY_PASSWORD = "ghp_xxxxxxxxxxxx"

# Database credentials
BOOKLORE_DB_USER = "booklore"
BOOKLORE_DB_PASSWORD = "your-secure-password"
BOOKLORE_DB_ROOT_PASSWORD = "your-secure-root-password"
```

**Note:** `deploy.yml` uses ERB to read these environment variables, so you never need to edit it directly. This means you can `git pull` updates without merge conflicts.

### 3. Deploy

```bash
mise exec -- bin/kamal setup
```

This sets up everything needed on a fresh host and deploys BookLore. Further details at [Kamal docs](https://kamal-deploy.org/docs/commands/setup/).

### 4. Access BookLore

Open `https://your-domain.com` in your browser. SSL certificates are automatically provisioned by kamal-proxy via Let's Encrypt.

## Checking for Updates

See what version is deployed and whether updates are available:

```bash
./bin/status
```

This shows your deployed version, recent releases, and a link to the changelog if an update is available.

## Updating

If an update is available:

```bash
./bin/deploy
```

This automatically fetches the latest BookLore release and deploys it. To deploy a specific version:

```bash
./bin/deploy v1.18.3
```

## Kobo Sync Setup

To sync books with a Kobo e-reader:

1. Enable Kobo sync in BookLore settings and copy your token
2. Connect your Kobo via USB
3. Edit `.kobo/Kobo/Kobo eReader.conf` on the device
4. Change `api_endpoint` under `[OneStoreServices]` to:
   ```
   api_endpoint=https://your-domain.com/api/kobo/YOUR_TOKEN
   ```
5. Eject and sync your Kobo

**Important:** The URL must include `/api/kobo/` - not just `/kobo/`.

## Useful Commands

```bash
# Check for updates
./bin/status

# View logs
mise exec -- bin/kamal app logs

# Access container shell
mise exec -- bin/kamal app exec -i bash

# Restart the app
mise exec -- bin/kamal app boot

# Check deployment details
mise exec -- bin/kamal details

# Deploy latest version
./bin/deploy

# Deploy specific version
./bin/deploy v1.18.3
```

## License

MIT. Grimmory itself is licensed under [GPL-3.0](https://github.com/grimmory-tools/grimmory/blob/main/LICENSE).
