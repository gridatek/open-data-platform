# console/web — Angular + Tailwind

The Phase 2 dashboard: Angular 18 (standalone components, signals) + Tailwind,
rendering the three read-only panels from `console/api`.

## Run / build

```bash
npm install
npm start        # dev server on :4200, proxies /api → :8090 (proxy.conf.json)
npm run build    # production bundle → dist/console
```

The API must be running on :8090 (see `../api`). The dev proxy forwards `/api`
calls to it, so there are no CORS issues in development.

## Layout

```
src/
├── index.html
├── main.ts                  # bootstrapApplication(AppComponent, appConfig)
├── styles.css               # @tailwind base/components/utilities
└── app/
    ├── app.config.ts        # provideHttpClient()
    ├── console.service.ts    # typed GETs to /api/*
    ├── models.ts            # ServiceStatus, PolicySummary
    └── app.component.ts     # the dashboard (services / catalog / policies)
```

Panels degrade gracefully: if a backing service is down, its panel shows an
"unavailable" placeholder instead of erroring.
