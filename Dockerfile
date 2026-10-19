# SearXNG publishes a dated image for every commit and has no stable releases.
# renovate: datasource=docker packageName=docker.io/searxng/searxng depName=SearXNG versioning=regex:^(?<major>\d{4})\.(?<minor>\d+)\.(?<patch>\d+)-[0-9a-f]+$
ARG SEARXNG_VERSION=2026.10.17-decdfa6f7

FROM docker.io/searxng/searxng:${SEARXNG_VERSION}

# 977:977 is the searxng user in the upstream image.
COPY --chown=977:977 settings.yml /etc/searxng/settings.yml

EXPOSE 8080

# Railway uses the template's healthcheck path. This one is for other runtimes.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost:8080/healthz || exit 1
