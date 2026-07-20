# syntax=docker/dockerfile:1

# SearXNG for Railway, preconfigured for LLM / agent tool use (JSON API).
#
# Upstream publishes rolling date-tagged images (no semver, no stable
# releases). Pin one and bump deliberately — never track `latest`:
ARG SEARXNG_VERSION=2026.7.19-6da6eee26

FROM docker.io/searxng/searxng:${SEARXNG_VERSION}

# 977:977 is the searxng user in the upstream image.
COPY --chown=977:977 settings.yml /etc/searxng/settings.yml

EXPOSE 8080

# Railway ignores Docker HEALTHCHECKs (railway.json's healthcheckPath covers
# that); this one is for docker/podman/compose users.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/healthz || exit 1
