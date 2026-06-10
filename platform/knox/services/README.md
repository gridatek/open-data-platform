# Custom Knox service definitions

Knox ships built-in service definitions for many Hadoop services (and a few
others), but not for the engines in this platform. Each directory here is a
minimal **reverse-proxy passthrough** definition for one backend, copied into
the image at `/opt/knox/data/services/`.

Each `<name>/1.0.0/` holds two files:

- **`service.xml`** — declares the `<role>`, a `<route>` matching
  `/<name>/**`, and `<metadata>` (so the service shows up on the Knox homepage).
- **`rewrite.xml`** — one inbound rule that rewrites
  `…/gateway/odp/<name>/<path>` to `{$serviceUrl[<ROLE>]}/<path>`, where
  `serviceUrl` is the `<url>` declared for that role in `topology/odp.xml`.

So the URL a backend lives at is set once, in the topology; these definitions
just teach Knox how to route to it.

## Adding response rewriting for a UI

A passthrough forwards requests fine but does **not** rewrite links in HTML/JS
responses. For API/SQL backends that's all you need. For a UI that emits
absolute URLs, add `dir="OUT"` rules to that service's `rewrite.xml` (and
reference them from the route) to rewrite the backend's links back through the
gateway. Do this per-service as needed — the passthrough is the baseline.
