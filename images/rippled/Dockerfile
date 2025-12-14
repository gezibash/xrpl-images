# Dockerfile for rippled with multi-variant support
# Variants: full, slim, distroless
# NOTE: Only linux/amd64 - no arm64 packages available upstream

ARG UBUNTU_VERSION=24.04
ARG UBUNTU_CODENAME=noble

# =============================================================================
# Stage 1: Builder - Install rippled and gather dependencies
# =============================================================================
FROM --platform=linux/amd64 ubuntu:${UBUNTU_VERSION} AS builder

ARG UBUNTU_CODENAME
ENV DEBIAN_FRONTEND=noninteractive

# Install rippled from official Ripple apt repository
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    gnupg \
    ca-certificates \
    && curl -fsSL https://repos.ripple.com/repos/api/gpg/key/public \
       | gpg --dearmor -o /etc/apt/trusted.gpg.d/ripple.gpg \
    && echo "deb https://repos.ripple.com/repos/rippled-deb ${UBUNTU_CODENAME} stable" \
       > /etc/apt/sources.list.d/ripple.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends rippled \
    && rm -rf /var/lib/apt/lists/*

# Collect all shared library dependencies into /runtime (for distroless)
RUN mkdir -p /runtime/lib/x86_64-linux-gnu /runtime/lib64 /runtime/opt/ripple/bin /runtime/etc \
    && cp /opt/ripple/bin/rippled /runtime/opt/ripple/bin/ \
    && ldd /opt/ripple/bin/rippled | awk '/=>/ {print $3}' | while read lib; do \
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

LABEL org.opencontainers.image.title="rippled-full"
LABEL org.opencontainers.image.description="XRP Ledger server (full variant with debug tools)"
LABEL org.opencontainers.image.source="https://github.com/gezibash/xrpl-images"

# Install rippled and debug tools
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
       rippled \
       curl \
       jq \
       vim-tiny \
       procps \
       net-tools \
       iputils-ping \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration and entrypoint
COPY configs/ /etc/rippled/
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Ensure data directory exists with correct permissions (user created by apt package)
RUN mkdir -p /var/lib/rippled/db && chown -R rippled:rippled /var/lib/rippled

USER rippled
WORKDIR /var/lib/rippled

VOLUME ["/etc/rippled", "/var/lib/rippled"]

EXPOSE 5005 6006 51235

ENTRYPOINT ["/entrypoint.sh"]
CMD ["rippled", "--conf", "/etc/rippled/rippled.cfg"]

# =============================================================================
# Stage 2b: Slim - Distroless with busybox shell (for debugging)
# =============================================================================
FROM --platform=linux/amd64 gcr.io/distroless/cc-debian12:debug AS slim

LABEL org.opencontainers.image.title="rippled-slim"
LABEL org.opencontainers.image.description="XRP Ledger server (slim variant with shell)"
LABEL org.opencontainers.image.source="https://github.com/gezibash/xrpl-images"

# Copy rippled binary and all its dependencies from builder
COPY --from=builder /runtime/opt/ripple/bin/rippled /opt/ripple/bin/
COPY --from=builder /runtime/lib/ /lib/
COPY --from=builder /runtime/lib64/ /lib64/
COPY --from=builder /runtime/etc/ssl /etc/ssl

# Copy configuration
COPY configs/ /etc/rippled/

WORKDIR /var/lib/rippled

VOLUME ["/etc/rippled", "/var/lib/rippled"]

EXPOSE 5005 6006 51235

ENTRYPOINT ["/opt/ripple/bin/rippled"]
CMD ["--conf", "/etc/rippled/rippled.cfg"]

# =============================================================================
# Stage 2c: Distroless - No shell, minimal attack surface
# =============================================================================
FROM --platform=linux/amd64 gcr.io/distroless/cc-debian12:nonroot AS distroless

LABEL org.opencontainers.image.title="rippled-distroless"
LABEL org.opencontainers.image.description="XRP Ledger server (distroless variant)"
LABEL org.opencontainers.image.source="https://github.com/gezibash/xrpl-images"

# Copy rippled binary and all its dependencies from builder
COPY --from=builder /runtime/opt/ripple/bin/rippled /opt/ripple/bin/
COPY --from=builder /runtime/lib/ /lib/
COPY --from=builder /runtime/lib64/ /lib64/
COPY --from=builder /runtime/etc/ssl /etc/ssl

# Copy configuration
COPY configs/ /etc/rippled/

WORKDIR /var/lib/rippled

VOLUME ["/etc/rippled", "/var/lib/rippled"]

EXPOSE 5005 6006 51235

ENTRYPOINT ["/opt/ripple/bin/rippled"]
CMD ["--conf", "/etc/rippled/rippled.cfg"]
