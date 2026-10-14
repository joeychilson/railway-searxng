# SearXNG on Railway

[![Release](https://img.shields.io/github/v/release/joeychilson/railway-searxng)](https://github.com/joeychilson/railway-searxng/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

A Railway template for a private [SearXNG](https://github.com/searxng/searxng)
metasearch instance with a JSON search API for LLM agents and backend services.

## Deploy

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/searxng-api?referralCode=NhCCIt&utm_medium=integration&utm_source=template&utm_campaign=generic)

The template creates one `searxng` service with:

- The `ghcr.io/joeychilson/railway-searxng` image for amd64 and arm64.
- Curated general, developer, package, and academic search engines.
- An 8-second engine timeout with one retry.
- A `/healthz` healthcheck.
- A generated `SEARXNG_SECRET`.
- No public domain and no Redis or Valkey.

SearXNG has no authentication, and this configuration turns off its rate
limiter. Other services in the same Railway project reach it over private
networking:

```text
http://searxng.railway.internal:8080
```

To reach it from outside Railway, attach a public domain to port `8080` and set
`SEARXNG_BASE_URL`. Anyone with that URL can query the instance.

## Usage

Run a general web search:

```text
curl "http://searxng.railway.internal:8080/search?q=python+async&format=json"
```

Developer engines use the `it` category, and academic engines use `science`:

```text
curl "http://searxng.railway.internal:8080/search?q=tokio+channels&format=json&categories=it"
curl "http://searxng.railway.internal:8080/search?q=mixture+of+experts&format=json&categories=science"
```

Target specific engines or use a bang shortcut:

```text
curl "http://searxng.railway.internal:8080/search?q=transformers&format=json&engines=arxiv,github"
curl "http://searxng.railway.internal:8080/search?q=%21gh+railway+cli&format=json"
```

Paginate or limit results by time range:

```text
curl "http://searxng.railway.internal:8080/search?q=rust&format=json&pageno=2&time_range=week"
```

The JSON response has `results`, `answers`, `infoboxes`, and `suggestions`.
Each result has its URL, title, content, engine, and score. For an agent tool,
expose a required `query` parameter and optional `categories` and `time_range`
parameters.

| Category | Engines |
|---|---|
| General | DuckDuckGo, Brave, Qwant, Wikipedia, Wikidata, Currency |
| Developer | GitHub, GitLab, Stack Overflow, MDN, Hacker News, Arch Linux Wiki |
| Packages | npm, PyPI, crates.io, pkg.go.dev, Docker Hub |
| Science | arXiv, Semantic Scholar, Crossref, PubMed |

Google, Bing, Yahoo, Yandex, and Baidu are off because they often block
datacenter traffic. The general web engines can still reject cloud IPs at
times; `/stats` shows each engine's error rate.

## Configuration

| Variable | Required | Purpose |
|---|---|---|
| `SEARXNG_SECRET` | Yes | Server secret. The template generates it, and SearXNG refuses to start without it. |
| `SEARXNG_BASE_URL` | No | Public URL with a trailing slash, when the service has a public domain |

SearXNG reads both variables directly. Everything else is in
[`settings.yml`](settings.yml).

## Updates

Each release is published as `ghcr.io/joeychilson/railway-searxng:X.Y.Z` and
moves the `X.Y` tag to it. The Railway template deploys `X.Y` with patch
auto-updates on, so a deployment that keeps that setting picks up patch releases
in Railway's nightly update window. A minor or major release starts a new `X.Y`
tag, and its release notes say what to change before you move to it.

[Renovate](https://docs.renovatebot.com) bumps SearXNG to the newest dated
image once a week. The bump merges after the smoke test passes on amd64 and
arm64, and the merge publishes a patch release. The release policy for all of
these templates is in
[railway-templates](https://github.com/joeychilson/railway-templates#releases).

## Development

```text
docker build -t railway-searxng:test .
./test/smoke-test.sh railway-searxng:test
```

The smoke test checks the healthcheck, the enabled engines, and a JSON search
over GET. To run the image yourself:

```text
docker run --rm -e SEARXNG_SECRET="$(openssl rand -hex 32)" -p 8080:8080 railway-searxng:test
```

## License

[MIT](LICENSE)
