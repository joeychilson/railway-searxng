# SearXNG Railway

A pre-configured [SearXNG](https://github.com/searxng/searxng) template for Railway, optimized for LLM / agent tool use: a private metasearch instance your agents query over a plain GET JSON API.

## Features

- **JSON API over GET** — `?q=...&format=json` with no POST bodies or CSRF dance
- **Pinned upstream version** — the Dockerfile pins a dated SearXNG image; images publish under immutable tags, never `latest`
- **Curated, weighted engines** — a diverse general-web set plus API-backed engines (GitHub, arXiv, PyPI, ...) that never CAPTCHA
- **Engines that block datacenter IPs disabled** — Google and Bing CAPTCHA cloud IPs quickly; failing engines only add latency
- **Latency-bounded** — 8s engine timeout, single retry; SearXNG waits for the slowest engine, so this caps response time
- **No rate limiter** — private instance; no Redis/Valkey needed
- **Health-checked** — `/healthz` wired into `railway.json` (Railway ignores Docker `HEALTHCHECK`s)

## Deploy

### Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/searxng-api?referralCode=NhCCIt&utm_medium=integration&utm_source=template&utm_campaign=generic)

The only required variable is `SEARXNG_SECRET` (any long random string — the template generates one). The instance refuses to start without it.

The template deploys **without public networking**: SearXNG has no auth and this config disables the rate limiter, so it's meant to be reached only by services in the same Railway project at `http://searxng.railway.internal:8080`. If you need access from outside Railway, enable public networking on your deployment (target port 8080) — and know that anyone with the URL can query your instance.

### Any container platform

```bash
docker build -t searxng .
docker run -p 8080:8080 -e SEARXNG_SECRET="$(openssl rand -hex 32)" searxng
```

Or locally: `docker compose up --build`

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SEARXNG_SECRET` | Secret key for the instance (server-side crypto) | Yes |
| `SEARXNG_BASE_URL` | Public URL of the instance (e.g. `https://your-app.up.railway.app/`) | No |

These are read natively by SearXNG — `settings.yml` intentionally omits `secret_key`.

## API Usage

From another service in the same Railway project, the base URL is `http://searxng.railway.internal:8080`.

```bash
# Basic JSON search (hits the "general" category)
curl "http://searxng.railway.internal:8080/search?q=python+async&format=json"

# Category matters: dev engines live in "it", academic in "science".
# A plain query does NOT hit them — select the category:
curl "http://searxng.railway.internal:8080/search?q=tokio+channels&format=json&categories=it"
curl "http://searxng.railway.internal:8080/search?q=mixture+of+experts&format=json&categories=science"

# Or target specific engines
curl "http://searxng.railway.internal:8080/search?q=transformers&format=json&engines=arxiv,github"

# Or use bang shortcuts inside the query
curl "http://searxng.railway.internal:8080/search?q=%21gh+railway+cli&format=json"

# Paginate and time-filter
curl "http://searxng.railway.internal:8080/search?q=rust&format=json&pageno=2&time_range=week"
```

The JSON response has `results` (each with `url`, `title`, `content`, `engine`, `score`), plus `answers`, `infoboxes`, and `suggestions`.

**Agent tip:** give your agent one tool with `query`, optional `categories` (`general` | `it` | `science`), and optional `time_range`. That covers web, dev, and academic search with a single instance.

## Enabled Search Engines

| Category | Engines |
|----------|---------|
| general | DuckDuckGo, Brave, Startpage, Qwant, Mojeek, Wikipedia, Wikidata, Currency |
| it / q&a | GitHub, GitLab, StackOverflow, MDN, Hacker News, Arch Wiki |
| packages | npm, PyPI, crates.io, pkg.go.dev, Docker Hub |
| science | arXiv, Semantic Scholar, Crossref, PubMed |

**Disabled:** Google, Bing, Yahoo, Yandex, Baidu (block datacenter IPs or add noise).

General-web engines are scraped and can intermittently CAPTCHA cloud IPs; the enabled set is deliberately diverse so one engine blocking doesn't empty results. Check `/stats` on your instance to see per-engine error rates.

## Versioning

Upstream SearXNG ships rolling date-tagged images with no stable releases, so this template pins an exact tag (`ARG SEARXNG_VERSION` in the Dockerfile). A weekly workflow opens a PR bumping the pin; CI smoke tests every build. Images publish to GHCR only when a GitHub release is cut — never `latest`. `X.Y.Z` and `sha-<commit>` tags are immutable; the `X.Y` tag tracks the latest patch in that minor and is the channel the Railway template deploys.

Routine upstream SearXNG bumps ship as **patch** releases, so new template deploys pick them up automatically through the `X.Y` channel. Anything that changes the template's own behavior — variables, engine set, settings semantics — bumps the minor or major, and never reaches the template without a deliberate republish. Template versions are deliberately independent of upstream's date tags, but every release records which SearXNG it wraps: release titles follow `vX.Y.Z — SearXNG <upstream tag>`, and published images carry the exact upstream image in the `org.opencontainers.image.base.name` label.

## Development

```bash
docker build -t searxng-test .
./test/smoke-test.sh searxng-test
```

## License

MIT
