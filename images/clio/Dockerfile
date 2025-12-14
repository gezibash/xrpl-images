# Dockerfile for Clio (XRP Ledger API server) with multi-variant support
# Variants: full, slim, distroless
# NOTE: Only linux/amd64 - no arm64 packages available upstream

ARG UBUNTU_VERSION=24.04
ARG UBUNTU_CODENAME=noble

# =============================================================================
# Stage 1: Builder - Install clio and gather dependencies
# =============================================================================
FROM --platform=linux/amd64 ubuntu:${UBUNTU_VERSION} AS builder

ARG UBUNTU_CODENAME
ENV DEBIAN_FRONTEND=noninteractive

# Install clio from official Ripple apt repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    ca-certificates \
    && curl -fsSL https://repos.ripple.com/repos/api/gpg/key/public \
       | gpg --dearmor -o /etc/apt/trusted.gpg.d/ripple.gpg \
    && echo "deb https://repos.ripple.com/repos/rippled-deb ${UBUNTU_CODENAME} stable" \
       > /etc/apt/sources.list.d/ripple.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends clio \
    && rm -rf /var/lib/apt/lists/*

# Collect all shared library dependencies into /runtime (for distroless)
RUN mkdir -p /runtime/lib/x86_64-linux-gnu /runtime/lib64 /runtime/opt/clio/bin /runtime/etc \
    && cp /opt/clio/bin/clio_server /runtime/opt/clio/bin/ \
    && ldd /opt/clio/bin/clio_server | awk '/=>/ {print $3}' | while read lib; do \
         [ -f "$lib" ] && cp -L "$lib" /runtime/lib/x86_64-linux-gnu/; \
       done \
    && cp -L /lib64/ld-linux-x86-64.so.2 /runtime/lib64/ \
    && cp -r /etc/ssl /runtime/etc/

# =============================================================================
# Stage 2a: Full - Ubuntu with debug tools
# =============================================================================
FROM --platform=linux/amd64 ubuntu:${UBUNTU_VERSION} AS full

ARG UBUNTU_CODENAME
ENV DEBIAN_FRONTEND=noninteractive

LABEL org.opencontainers.image.title="clio-full"
LABEL org.opencontainers.image.description="XRP Ledger Clio API server (full variant with debug tools)"
LABEL org.opencontainers.image.source="https://github.com/gezibash/xrpl-images"

# Install clio and debug tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    ca-certificates \
    && curl -fsSL https://repos.ripple.com/repos/api/gpg/key/public \
       | gpg --dearmor -o /etc/apt/trusted.gpg.d/ripple.gpg \
    && echo "deb https://repos.ripple.com/repos/rippled-deb ${UBUNTU_CODENAME} stable" \
       > /etc/apt/sources.list.d/ripple.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
       clio \
       curl \
       jq \
       vim-tiny \
       procps \
       net-tools \
       iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration and entrypoint
COPY configs/ /etc/clio/
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Create data directory (clio user already exists from apt package)
RUN mkdir -p /var/lib/clio && chown -R clio:clio /var/lib/clio

USER clio
WORKDIR /var/lib/clio

VOLUME ["/etc/clio", "/var/lib/clio"]

EXPOSE 51233

ENTRYPOINT ["/entrypoint.sh"]
CMD ["clio_server", "--conf", "/etc/clio/config.json"]

# =============================================================================
# Stage 2b: Slim - Distroless with busybox shell (for debugging)
# =============================================================================
FROM --platform=linux/amd64 gcr.io/distroless/cc-debian12:debug AS slim

LABEL org.opencontainers.image.title="clio-slim"
LABEL org.opencontainers.image.description="XRP Ledger Clio API server (slim variant with shell)"
LABEL org.opencontainers.image.source="https://github.com/gezibash/xrpl-images"

# Copy clio binary and all its dependencies from builder
COPY --from=builder /runtime/opt/clio/bin/clio_server /opt/clio/bin/
COPY --from=builder /runtime/lib/ /lib/
COPY --from=builder /runtime/lib64/ /lib64/
COPY --from=builder /runtime/etc/ssl /etc/ssl

# Copy configuration
COPY configs/ /etc/clio/

WORKDIR /var/lib/clio

VOLUME ["/etc/clio", "/var/lib/clio"]

EXPOSE 51233

ENTRYPOINT ["/opt/clio/bin/clio_server"]
CMD ["--conf", "/etc/clio/config.json"]

# =============================================================================
# Stage 2c: Distroless - No shell, minimal attack surface
# =============================================================================
FROM --platform=linux/amd64 gcr.io/distroless/cc-debian12:nonroot AS distroless

LABEL org.opencontainers.image.title="clio-distroless"
LABEL org.opencontainers.image.description="XRP Ledger Clio API server (distroless variant)"
LABEL org.opencontainers.image.source="https://github.com/gezibash/xrpl-images"

# Copy clio binary and all its dependencies from builder
COPY --from=builder /runtime/opt/clio/bin/clio_server /opt/clio/bin/
COPY --from=builder /runtime/lib/ /lib/
COPY --from=builder /runtime/lib64/ /lib64/
COPY --from=builder /runtime/etc/ssl /etc/ssl

# Copy configuration
COPY configs/ /etc/clio/

WORKDIR /var/lib/clio

VOLUME ["/etc/clio", "/var/lib/clio"]

EXPOSE 51233

ENTRYPOINT ["/opt/clio/bin/clio_server"]
CMD ["--conf", "/etc/clio/config.json"]
