# syntax=docker/dockerfile:1.7

# SearXNG for Railway, preconfigured for LLM / agent tool use (JSON API).
#
# Upstream publishes rolling date-tagged images (no semver, no stable
# releases). Pin one and bump deliberately — never track `latest`:
ARG SEARXNG_VERSION=2026.9.21-49064747a

FROM docker.io/searxng/searxng:${SEARXNG_VERSION}

# 977:977 is the searxng user in the upstream image.
COPY --chown=977:977 settings.yml /etc/searxng/settings.yml

EXPOSE 8080

# Railway templates configure their own healthcheck path. This image-level
# check is for other container runtimes.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/healthz || exit 1
