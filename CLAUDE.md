# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This is **deployment configuration only** — there is no application source code here. It deploys [Grimmory](https://github.com/grimmory-tools/grimmory) (the successor of BookLore) to a single user-owned server using [Kamal 2](https://kamal-deploy.org/). The Grimmory application itself lives in a separate upstream repo and is consumed as a prebuilt container image.

## Commands

All Kamal commands must run through `mise exec --` so they use the bundled Ruby 3.3 and the `kamal` gem (`bin/kamal` is a Bundler binstub). `mise` also loads env vars from `mise.local.toml`.

```bash
./bin/setup                                   # First-time: checks mise, bundle install, creates mise.local.toml
mise exec -- bin/kamal setup                  # Provision a fresh host + first deploy
./bin/deploy                                  # Deploy the latest Grimmory GitHub release
./bin/deploy v1.18.3                          # Deploy a specific version
./bin/status                                  # Compare deployed version vs latest release
mise exec -- bin/kamal app logs               # Tail app logs
mise exec -- bin/kamal app exec -i bash       # Shell into the running container
mise exec -- bin/kamal details                # Deployment status
```

`bin/deploy` and `bin/status` require the `gh` CLI (they query GitHub releases of `grimmory-tools/grimmory`).

## Configuration flow

Instance-specific values are **never** edited into `config/deploy.yml` directly. The flow is:

1. User edits `mise.local.toml` (gitignored; copied from `mise.local.toml.example` by `bin/setup`).
2. `mise` exports those as environment variables (`BOOKLORE_HOST`, `BOOKLORE_DOMAIN`, `KAMAL_REGISTRY_*`, `BOOKLORE_DB_*`, etc.).
3. `config/deploy.yml` reads them via **ERB** (`<%= ENV[...] %>`) — this is why `deploy.yml` stays generic and users can `git pull` without merge conflicts.
4. `.kamal/secrets` maps the same env vars into Kamal's secret store (DB credentials, registry password). Secrets in `deploy.yml` reference these names, not literal values.

When changing what a deployment needs, prefer adding an env var + ERB reference over hardcoding into `deploy.yml`.

## Wrapper image architecture (important)

`Dockerfile` does **not** build the app. It is a thin wrapper: `FROM ghcr.io/grimmory-tools/grimmory:${VERSION}`, adding only `ENV BOOKLORE_VERSION` and a label. Kamal then pushes this wrapped image to the user's *own* GHCR namespace (`<KAMAL_REGISTRY_USERNAME>/grimmory`).

This indirection exists solely because Kamal requires a `service` label on the image and the upstream image lacks one. The cost is that users need a PAT with `write:packages` (not just `read:packages`). If upstream ever adds `service="booklore"` to its image labels, this wrapper and the re-push can be removed (deploy with `--skip-push`). See `NOTES.md` (gitignored) for the upstream-fix proposal.

Version selection chain: `VERSION` env var → `deploy.yml` builder arg → `Dockerfile` `ARG VERSION` → upstream image tag. `bin/deploy` sets `VERSION` from the latest GitHub release (or its argument).

## Naming inconsistency — do not casually "fix"

The project was renamed BookLore → Grimmory, but identifiers were intentionally left mixed for deployment continuity:

- `service: booklore` and host volumes under `/data/booklore/...` — renaming these is **destructive** to existing deployments (Kamal treats it as a different service; data volume paths would change).
- Env vars are still `BOOKLORE_*`; DB name / `DATABASE_URL` use `booklore`.
- The image and upstream source are `grimmory`.

Treat the `booklore` names as stable infrastructure identifiers, not stale typos.

## Host-side state

- `.kamal/hooks/docker-setup` runs on `kamal setup`, SSHing as `root` to create `/data/booklore/{data,libraries,bookdrop,mariadb}` and `chown 1000:1000`. The container runs as UID/GID 1000 (`APP_USER_ID`/`APP_GROUP_ID`).
- Library content lives under `/data/booklore/libraries/<library-name>/` (one subfolder per Grimmory library), bind-mounted into the container at `/libraries`. Each Grimmory library's root path is `/libraries/<library-name>`; do **not** nest one library inside another — the scanner would index files twice.
- MariaDB runs as a Kamal accessory (`mariadb:11.4.5`) on the same host, data at `/data/booklore/mariadb`, reachable from the app at host `booklore-db`.
- Health check: app must respond on `/api/v1/healthcheck` at port `6060`; kamal-proxy terminates TLS (Let's Encrypt) for `BOOKLORE_DOMAIN`.
