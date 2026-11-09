# Rallly on Railway

**Rallly** is an open-source scheduling and collaboration tool — create a meeting poll with date and time options, share the link, and participants vote on when to meet. It is the modern successor to Framadate/Doodle-style scheduling polls, built on Next.js, Prisma, tRPC and TailwindCSS.

This repository packages Rallly for one-click deployment on [Railway](https://railway.com).

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/rallly-template)

## What this template deploys

| Service | Image | Notes |
|---|---|---|
| **Rallly** | `lukevella/rallly:4.16.4` (pinned by digest) | Official image, self-hosted mode; Prisma migrations run automatically on every boot; health-checked at `/api/status` |
| **Postgres** | `postgres:18-alpine` (pinned by digest) | Persistent volume mounted at `/var/lib/postgresql`; password generated per deployment |

The deploy has **zero form prompts** — secrets are generated per deployment, the database connection is wired automatically, and the public URL is derived from the Railway domain at boot.

## After deploying (about 2 minutes)

Rallly's organizer login uses **passwordless one-time codes sent by email**, so SMTP must be configured before the first sign-in. Participants voting on polls never need accounts.

1. On the **Rallly** service add these variables, then redeploy:

   | Variable | Example | Purpose |
   |---|---|---|
   | `SMTP_HOST` | `smtp.gmail.com` (or any provider) | Outgoing mail server |
   | `SMTP_PORT` | `587` | SMTP port |
   | `SMTP_SECURE` | `false` | `true` for implicit TLS (port 465) |
   | `SMTP_USER` + `SMTP_PWD` | set both, or neither | SMTP credentials |
   | `INITIAL_ADMIN_EMAIL` | `you@example.com` | This address can claim the admin role |

2. Open your Railway domain, enter your email on the login page, receive the 6-digit code, and sign in. The first sign-in creates your account.
3. Visit `/control-panel` and click **Make me an admin** (available to the `INITIAL_ADMIN_EMAIL` address).
4. Create a poll and share the link — guests vote without any account.

## Environment variables

Required (pre-configured by this template):

- `DATABASE_URL` — wired to the Postgres service automatically.
- `NEXT_PUBLIC_BASE_URL` — derived from your Railway domain at boot; redeploy after adding a custom domain, or set it explicitly.
- `SECRET_PASSWORD` — session-encryption key (min 32 chars); generated per deployment. **Set it explicitly for sessions that survive redeploys.**
- `SUPPORT_EMAIL` — defaults to `support@example.com`; set your own address (it is the default From for OTP emails unless `NOREPLY_EMAIL` is set).

Recommended after deploy: `SMTP_*` (above), `INITIAL_ADMIN_EMAIL`, `ALLOWED_EMAILS` (restrict who can register, wildcards supported, e.g. `*@example.com`).

Optional:

- `NOREPLY_EMAIL`, `NOREPLY_EMAIL_NAME` — sender identity for transactional email.
- `REGISTRATION_ENABLED` (`true` by default), `EMAIL_LOGIN_ENABLED` (`true` by default — do **not** set `false` without configuring SSO, or no one can log in).
- SSO: Google (`GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`), Microsoft (`MICROSOFT_CLIENT_ID`, `MICROSOFT_CLIENT_SECRET`), or any OIDC provider (`OIDC_DISCOVERY_URL`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, display name `OIDC_NAME`). All three OIDC values are required together; callback URL is `https://your-domain/api/auth/callback/oidc`.
- File uploads offload: `S3_BUCKET_NAME`, `S3_ENDPOINT`, `S3_REGION`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`.
- Rate limiting / session offload: `KV_REST_API_URL`, `KV_REST_API_TOKEN` (Upstash-compatible; in-memory + database otherwise).
- Bot protection: `TURNSTILE_SECRET_KEY` + `NEXT_PUBLIC_TURNSTILE_SITE_KEY` (Cloudflare Turnstile, set both together).
- Maintenance: `MAINTENANCE_MODE=true` (skips migrations, serves a maintenance page; bypass with `MAINTENANCE_BYPASS_TOKEN`).

Full reference: the upstream configuration docs at https://support.rallly.co/self-hosting/configuration.

## Auth model

- **Organizer login**: email one-time code (passwordless). Passwords can be set later from a signed-in session. No environment variable can disable authentication entirely (upstream removed that in v3).
- **Guests**: never need accounts; they vote from the shared link.
- **Admin**: the `INITIAL_ADMIN_EMAIL` address claims the admin role at `/control-panel`; admins can manage users, registration, and settings there.
- **SSO (optional)**: Google, Microsoft Entra ID, or any OpenID Connect provider.

## Healthcheck, migrations, persistence

- Railway healthcheck: `GET /api/status` — returns JSON with `database: connected|disconnected`.
- Migrations: `prisma migrate deploy` runs before the server starts on every boot (skipped in maintenance mode).
- All state lives in Postgres; the app container is stateless. The volume mounts at `/var/lib/postgresql` (the parent of `PGDATA`), which survives redeploys.

## Licensing

Rallly is open source under **AGPL-3.0** — this repository only packages it. Self-hosting is free for personal use; running a multi-user instance is covered by an honor-system license available from the upstream project (see https://support.rallly.co/self-hosting/licensing). Guest poll participants do not count as users.

## Phone-home note

The self-hosted image contacts `api.rallly.co` for update checks only. Set the `API_BASE_URL` variable to a dummy value to prevent outbound calls if your policy requires it.

## Build notes

- The `Dockerfile` is a thin wrapper over the official image (digest-pinned): it bakes a `SUPPORT_EMAIL` default and derives `NEXT_PUBLIC_BASE_URL` from Railway's injected domain at boot. Everything else — migrations, healthcheck, non-root user, port handling — is the upstream image's own behavior.
- `railway.json` declares the Dockerfile builder, the `/api/status` healthcheck, and an `ON_FAILURE` restart policy (max 10 retries).
