# Template Reference

Detailed documentation for every reusable workflow in this repository.

> **How reusable workflows work:** GitHub requires reusable workflows to be located in `.github/workflows/` of the repository they are called from. To use these templates, consumers reference them as:
> ```yaml
> uses: MeteorFactory/Pipelines/.github/workflows/<template>.yml@main
> ```
> The `templates/` directory is the canonical source; files are copied to `.github/workflows/` for GitHub to serve them.

---

## ci-node.yml

General-purpose Node.js CI pipeline with independently toggleable jobs: lint, typecheck, test, and build. Supports multi-OS matrix builds.

### Inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `node-version` | string | no | `"22"` | Node.js version to use |
| `package-manager` | string | no | `"npm"` | Package manager to use (`npm` or `pnpm`) |
| `pnpm-version` | string | no | `"10"` | pnpm version (only used when `package-manager` is `pnpm`) |
| `os-matrix` | string | no | `'["ubuntu-latest"]'` | JSON array of runner OS labels |
| `run-lint` | boolean | no | `true` | Enable/disable the lint job |
| `run-typecheck` | boolean | no | `true` | Enable/disable the typecheck job |
| `run-test` | boolean | no | `true` | Enable/disable the test job |
| `run-build` | boolean | no | `true` | Enable/disable the build job |

### Secrets

None.

### Jobs

Each job runs independently (no dependencies between them) and uses the OS matrix:

1. **lint** -- Runs `{package-manager} run lint`
2. **typecheck** -- Runs `{package-manager} run typecheck`
3. **test** -- Runs `{package-manager} run test`
4. **build** -- Runs `{package-manager} run build`

Install step adapts automatically: `npm ci` for npm, `pnpm install --frozen-lockfile` for pnpm.

### Example

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  ci:
    uses: MeteorFactory/Pipelines/.github/workflows/ci-node.yml@main
    with:
      node-version: "20"
      run-typecheck: false  # Skip typecheck for this project
```

#### With pnpm

```yaml
jobs:
  ci:
    uses: MeteorFactory/Pipelines/.github/workflows/ci-node.yml@main
    with:
      package-manager: "pnpm"
      pnpm-version: "10"
```

#### Multi-OS build

```yaml
jobs:
  ci:
    uses: MeteorFactory/Pipelines/.github/workflows/ci-node.yml@main
    with:
      os-matrix: '["ubuntu-latest", "macos-latest"]'
```

---

## ci-electron.yml

Electron-specific CI pipeline targeting macOS and Windows by default. Same toggleable jobs as `ci-node.yml` but with `NODE_OPTIONS: --max-old-space-size=4096` on the build job to handle Electron's memory requirements.

### Inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `node-version` | string | no | `"22"` | Node.js version to use |
| `package-manager` | string | no | `"npm"` | Package manager to use (`npm` or `pnpm`) |
| `pnpm-version` | string | no | `"10"` | pnpm version (only used when `package-manager` is `pnpm`) |
| `os-matrix` | string | no | `'["macos-latest", "windows-latest"]'` | JSON array of runner OS labels |
| `run-lint` | boolean | no | `true` | Enable/disable the lint job |
| `run-typecheck` | boolean | no | `true` | Enable/disable the typecheck job |
| `run-test` | boolean | no | `true` | Enable/disable the test job |
| `run-build` | boolean | no | `true` | Enable/disable the build job |

### Secrets

None.

### Example

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  ci:
    uses: MeteorFactory/Pipelines/.github/workflows/ci-electron.yml@main
    with:
      node-version: "22"
      package-manager: "pnpm"
```

---

## release-electron.yml

Full Electron release pipeline: auto-versioning from `package.json`, macOS code signing + notarization (arm64 + x64), Windows build (x64), asset cleanup (removes `.blockmap` files), and draft-to-public release publishing.

### Inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `node-version` | string | no | `"22"` | Node.js version to use |
| `package-manager` | string | no | `"npm"` | Package manager to use (`npm` or `pnpm`) |
| `pnpm-version` | string | no | `"10"` | pnpm version (only used when `package-manager` is `pnpm`) |

### Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `GH_TOKEN` | yes | GitHub token for release creation and publishing |
| `MAC_CERTIFICATE` | yes | Base64-encoded macOS signing certificate (.p12) |
| `MAC_CERTIFICATE_PASSWORD` | yes | Password for the macOS signing certificate |
| `APPLE_ID` | yes | Apple ID email for notarization |
| `APPLE_APP_SPECIFIC_PASSWORD` | yes | App-specific password for Apple notarization |
| `APPLE_TEAM_ID` | yes | Apple Developer Team ID |

### Jobs

1. **prepare-release** -- Reads version from `package.json`, determines the next patch version from existing git tags, creates and pushes the tag.
2. **release-mac** -- Builds and publishes macOS artifacts (arm64 + x64) with code signing and notarization via `electron-builder`.
3. **release-win** -- Builds and publishes Windows artifacts (x64) via `electron-builder`.
4. **finalize-release** -- Generates release notes from commits (grouped by conventional commit type), removes `.blockmap` assets, and marks the GitHub release as non-draft.

### Permissions

Requires `contents: write` to create tags and releases.

### Example

```yaml
name: Release

on:
  workflow_dispatch:

jobs:
  release:
    uses: MeteorFactory/Pipelines/.github/workflows/release-electron.yml@main
    with:
      node-version: "22"
    secrets:
      GH_TOKEN: ${{ secrets.GH_TOKEN }}
      MAC_CERTIFICATE: ${{ secrets.MAC_CERTIFICATE }}
      MAC_CERTIFICATE_PASSWORD: ${{ secrets.MAC_CERTIFICATE_PASSWORD }}
      APPLE_ID: ${{ secrets.APPLE_ID }}
      APPLE_APP_SPECIFIC_PASSWORD: ${{ secrets.APPLE_APP_SPECIFIC_PASSWORD }}
      APPLE_TEAM_ID: ${{ secrets.APPLE_TEAM_ID }}
```

### Versioning Logic

The `prepare-release` job reads the `major.minor` from `package.json`, scans existing tags matching `v{major}.{minor}.*`, and increments the patch number. For example, if `package.json` has `1.2.0` and tags `v1.2.0`, `v1.2.1` exist, the next release will be `v1.2.2`.

---

## deploy-pages.yml

Deploys a directory of static files to GitHub Pages using the official `actions/deploy-pages` action.

### Inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `path` | string | no | `"website"` | Path to the static files to deploy |

### Secrets

None (uses the built-in `GITHUB_TOKEN` via `id-token: write`).

### Permissions

Requires `contents: read`, `pages: write`, and `id-token: write`.

### Concurrency

Uses concurrency group `pages` with `cancel-in-progress: false` to prevent overlapping deployments.

### Prerequisites

GitHub Pages must be configured to deploy from **GitHub Actions** (not from a branch) in your repository settings under **Settings > Pages > Source**.

### Example

```yaml
name: Deploy Docs

on:
  push:
    branches: [main]

jobs:
  deploy:
    uses: MeteorFactory/Pipelines/.github/workflows/deploy-pages.yml@main
    with:
      path: "dist"
```

---

## docker-build.yml

Builds a Docker image using Buildx, tags it with branch/PR/semver/SHA metadata, and pushes to a container registry. Uses GitHub Actions cache for layer caching.

### Inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `dockerfile` | string | no | `"Dockerfile"` | Path to the Dockerfile |
| `context` | string | no | `"."` | Docker build context |
| `registry` | string | no | `"ghcr.io"` | Container registry URL |
| `image-name` | string | **yes** | -- | Image name without registry prefix (e.g., `myorg/myapp`) |

### Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `REGISTRY_USERNAME` | yes | Registry username |
| `REGISTRY_PASSWORD` | yes | Registry password or access token |

### Permissions

Requires `contents: read` and `packages: write`.

### Tags

The workflow automatically generates the following tags via `docker/metadata-action`:

| Tag pattern | Trigger |
|-------------|---------|
| Branch name | Push to branch |
| PR number | Pull request |
| `x.y.z` (semver full) | Tag push matching semver |
| `x.y` (semver major.minor) | Tag push matching semver |
| Git SHA (short) | Every build |

### Push Behavior

Images are pushed only on non-PR events (`github.event_name != 'pull_request'`). PR builds validate the image builds correctly but do not push.

### Example

```yaml
name: Docker

on:
  push:
    branches: [main]
    tags: ["v*"]
  pull_request:

jobs:
  docker:
    uses: MeteorFactory/Pipelines/.github/workflows/docker-build.yml@main
    with:
      image-name: "myorg/my-api"
      registry: "ghcr.io"
    secrets:
      REGISTRY_USERNAME: ${{ github.actor }}
      REGISTRY_PASSWORD: ${{ secrets.GITHUB_TOKEN }}
```

#### Custom Dockerfile location

```yaml
jobs:
  docker:
    uses: MeteorFactory/Pipelines/.github/workflows/docker-build.yml@main
    with:
      image-name: "myorg/my-api"
      dockerfile: "docker/Dockerfile.prod"
      context: "."
    secrets:
      REGISTRY_USERNAME: ${{ secrets.DOCKERHUB_USERNAME }}
      REGISTRY_PASSWORD: ${{ secrets.DOCKERHUB_TOKEN }}
```

---

## deploy-railway.yml

Deploy an application to Railway using the Railway CLI. Supports both Nixpacks and Dockerfile-based builds (Railway auto-detects). Designed for use after a CI job passes.

### Inputs

| Input | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `railway-service` | string | no | `""` | Railway service name (for multi-service projects) |
| `node-version` | string | no | `"22"` | Node.js version |
| `wait-for-deploy` | boolean | no | `true` | Wait for deployment to complete |

### Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `RAILWAY_TOKEN` | yes | Railway deploy token (Project → Settings → Tokens) |

### Jobs

1. **deploy** -- Installs Railway CLI, runs `railway up --detach`, optionally waits for health check

### Example

```yaml
deploy:
  needs: ci
  uses: MeteorFactory/Pipelines/.github/workflows/deploy-railway.yml@main
  secrets:
    RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```

#### With service name (multi-service project)

```yaml
deploy:
  needs: ci
  uses: MeteorFactory/Pipelines/.github/workflows/deploy-railway.yml@main
  with:
    railway-service: "web"
  secrets:
    RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
```
