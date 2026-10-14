# Deploy and Host SearXNG with Railway

SearXNG is an open-source metasearch engine. It sends each query to many search
engines and returns the combined results. This template runs a private SearXNG
instance with a JSON search API, tuned for LLM agents and backend services that
need web, developer, package, and academic search.

## About Hosting SearXNG

The template runs one SearXNG service from a tested image for amd64 and arm64.
It has no public domain: SearXNG has no authentication, and this configuration
turns off its rate limiter, so other services in the project call it over
Railway's private network at `http://searxng.railway.internal:8080`. Engine
requests time out after 8 seconds with one retry, so a slow engine can't stall
a search. Railway checks `/healthz` before switching traffic to a new
deployment, and patch releases of the image install automatically during the
nightly update window.

## Common Use Cases

- A web search tool for AI agents and LLM applications
- Search for a backend service without a paid search API
- Developer and package search across GitHub, Stack Overflow, npm, PyPI, and crates.io
- Academic search across arXiv, Semantic Scholar, Crossref, and PubMed

## Dependencies for SearXNG Hosting

- None. SearXNG runs without Redis or Valkey because the rate limiter is off.

### Deployment Dependencies

- [SearXNG documentation](https://docs.searxng.org)
- [Template source and full README](https://github.com/joeychilson/railway-searxng)

### Implementation Details

From another service in the same project:

```bash
# General web search
curl "http://searxng.railway.internal:8080/search?q=python+async&format=json"

# Developer engines
curl "http://searxng.railway.internal:8080/search?q=tokio+channels&format=json&categories=it"

# Academic engines
curl "http://searxng.railway.internal:8080/search?q=mixture+of+experts&format=json&categories=science"
```

The JSON response has `results`, `answers`, `infoboxes`, and `suggestions`.

| Category | Engines |
|---|---|
| General | DuckDuckGo, Brave, Qwant, Wikipedia, Wikidata, Currency |
| Developer | GitHub, GitLab, Stack Overflow, MDN, Hacker News, Arch Linux Wiki |
| Packages | npm, PyPI, crates.io, pkg.go.dev, Docker Hub |
| Science | arXiv, Semantic Scholar, Crossref, PubMed |

`SEARXNG_SECRET` is generated for you. To reach the instance from outside
Railway, attach a public domain to port `8080` and set `SEARXNG_BASE_URL` to its
URL. Anyone with that URL can query the instance.

### Why Deploy SearXNG on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will
host your infrastructure so you don't have to deal with configuration, while
allowing you to vertically and horizontally scale it.

By deploying SearXNG on Railway, you are one step closer to supporting a
complete full-stack application with minimal burden. Host your servers,
databases, AI agents, and more on Railway.
