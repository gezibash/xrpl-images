# XRPL Docker Images

Docker images for XRP Ledger infrastructure components.

## Available Images

| Image              | Description            | Variants               |
| ------------------ | ---------------------- | ---------------------- |
| `gezibash/rippled` | XRP Ledger core server | full, slim, distroless |
| `gezibash/clio`    | XRP Ledger API server  | full, slim, distroless |

## Quick Start

### rippled

```bash
# Pull the latest distroless image (recommended for production)
docker pull gezibash/rippled:latest

# Or pull a specific version with explicit base
docker pull gezibash/rippled:3.0.0-debian12-distroless

# Run rippled
docker run -d \
  --name rippled \
  -p 5005:5005 \
  -p 6006:6006 \
  -p 51235:51235 \
  -v rippled-data:/var/lib/rippled \
  -v rippled-config:/etc/rippled \
  gezibash/rippled:latest
```

### clio

```bash
# Pull the latest distroless image
docker pull gezibash/clio:latest

# Run clio (requires rippled and Cassandra)
docker run -d \
  --name clio \
  -p 51233:51233 \
  -v clio-config:/etc/clio \
  gezibash/clio:latest
```

## Image Variants

Each image is available in three variants:

| Variant      | Base                                    | Use Case              | Size   |
| ------------ | --------------------------------------- | --------------------- | ------ |
| `distroless` | `gcr.io/distroless/cc-debian12:nonroot` | Production (default)  | ~110MB |
| `slim`       | `gcr.io/distroless/cc-debian12:debug`   | Production with shell | ~112MB |
| `full`       | `ubuntu:24.04`                          | Development/debugging | ~193MB |

### Choosing a Variant

- **distroless** (default): Minimal attack surface, no shell. Best for
  production.
- **slim**: Distroless with busybox shell for debugging. Nearly as small as
  distroless.
- **full**: Ubuntu with curl, jq, vim, procps, net-tools. Best for development
  and troubleshooting.

## Tags

Tags include the base image codename for clarity:

- **full**: Ubuntu codename (e.g., `noble`)
- **slim/distroless**: Debian codename (e.g., `bookworm`)

| Tag Pattern                  | Example                      | Description                     |
| ---------------------------- | ---------------------------- | ------------------------------- |
| `{version}-{base}-{variant}` | `3.0.0-bookworm-distroless`  | Primary: fully explicit         |
| `{version}-{variant}`        | `3.0.0-distroless`           | Alias: default base for variant |
| `{version}`                  | `3.0.0`                      | Default variant + default base  |
| `latest-{base}-{variant}`    | `latest-bookworm-distroless` | Latest version, explicit base   |
| `latest-{variant}`           | `latest-distroless`          | Latest version, default base    |
| `latest`                     | `latest`                     | Latest everything               |

**Example tags for rippled 3.0.0:**

```
# Distroless variant (default)
gezibash/rippled:3.0.0-bookworm-distroless  # Primary (explicit base)
gezibash/rippled:3.0.0-distroless           # Alias (default base)
gezibash/rippled:3.0.0                      # Alias (default variant)

# Slim variant
gezibash/rippled:3.0.0-bookworm-slim        # Primary (explicit base)
gezibash/rippled:3.0.0-slim                 # Alias (default base)

# Full variant
gezibash/rippled:3.0.0-noble-full           # Primary (explicit base)
gezibash/rippled:3.0.0-full                 # Alias (default base)

# Latest
gezibash/rippled:latest                     # Latest everything
```

## Configuration

### rippled

Mount your configuration to `/etc/rippled/`:

```bash
docker run -d \
  -v /path/to/rippled.cfg:/etc/rippled/rippled.cfg:ro \
  -v /path/to/validators.txt:/etc/rippled/validators.txt:ro \
  gezibash/rippled:latest
```

**Ports:**

- `5005`: HTTP/WebSocket (public API)
- `6006`: HTTP/WebSocket (admin API)
- `51235`: Peer protocol

**Volumes:**

- `/etc/rippled`: Configuration files
- `/var/lib/rippled`: Database and logs

### clio

Mount your configuration to `/etc/clio/`:

```bash
docker run -d \
  -v /path/to/config.json:/etc/clio/config.json:ro \
  gezibash/clio:latest
```

**Ports:**

- `51233`: HTTP/WebSocket API

**Volumes:**

- `/etc/clio`: Configuration files
- `/var/lib/clio`: Logs

## Building Locally

### Prerequisites

- Docker with buildx support
- [Task](https://taskfile.dev) (task runner)
- jq (for matrix parsing)
- hadolint (optional, for linting)

### Build Commands

```bash
# Build default (rippled distroless on bookworm)
task build

# Build specific image/variant (base is derived automatically)
task build IMAGE=rippled VARIANT=slim    # builds 3.0.0-bookworm-slim
task build IMAGE=clio VARIANT=full       # builds 2.6.0-noble-full

# Build all variants for an image
task build-all IMAGE=rippled

# Test the image
task test IMAGE=rippled

# Lint Dockerfiles
task lint

# Show build matrix
task matrix

# Show current build configuration
task info

# Open shell in full variant (for debugging)
task shell IMAGE=rippled

# List all available tasks
task --list
```

## Architecture

Only `linux/amd64` is supported. ARM64 packages are not available from the
upstream Ripple apt repository.

## Registries

Images are published to:

- **Docker Hub**: `gezibash/rippled`, `gezibash/clio`
- **GitHub Container Registry**: `ghcr.io/{owner}/rippled`,
  `ghcr.io/{owner}/clio`

## Automation

New upstream releases are automatically detected every 6 hours. When found:

1. A PR is created with the updated version
2. Human reviews and merges
3. Images are built and pushed automatically

## License

MIT License - see [LICENSE](LICENSE)

## Links

- [XRP Ledger Documentation](https://xrpl.org/docs/)
- [rippled GitHub](https://github.com/XRPLF/rippled)
- [Clio GitHub](https://github.com/XRPLF/clio)
