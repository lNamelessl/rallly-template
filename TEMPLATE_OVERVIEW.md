**Rallly** is an open-source scheduling and collaboration tool — the modern successor to Framadate and Doodle-style meeting polls. Create a poll with date and time options, share the link, and participants vote on when to meet. Nobody needs an account to vote.

This template deploys Rallly v4.16.4 (official image, pinned by digest) together with PostgreSQL 18 on Railway, fully wired and health-checked, with zero deploy-form prompts.

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/rallly-template)

**What you get**

- **Rallly** — the official self-hosted image; database migrations run automatically on every boot; health-checked at /api/status; runs as a non-root user.
- **Postgres 18** — persistent volume, per-deployment generated password, connection wired into Rallly automatically.
- Zero-prompt deploy: the database URL, session secret, public URL, and support email are all handled by the template.

**Two-minute setup after deploy**

1. Rallly signs organizers in with a one-time code sent by email, so add SMTP variables on the Rallly service (SMTP_HOST, SMTP_PORT, SMTP_SECURE, and SMTP_USER with SMTP_PWD — any provider works, Gmail app passwords included), plus INITIAL_ADMIN_EMAIL with your own address, and redeploy.
2. Enter your email on the login page, read the 6-digit code from your inbox, sign in, then claim the admin role at /control-panel.
3. Create a poll and share the link — participants vote without accounts.

Single sign-on is optional (Google, Microsoft, or any OpenID Connect provider). The repo README documents every variable.

# Deploy and Host

## About Hosting

This template provisions two services. **Rallly** runs the official lukevella/rallly image (v4.16.4, digest-pinned) as a Next.js server that listens on the Railway-injected port, applies Prisma migrations before each start, and answers the /api/status healthcheck. **Postgres** runs postgres:18-alpine with a persistent volume mounted at /var/lib/postgresql; its per-deployment password and private-network host are referenced by Rallly automatically, so no database wiring is manual. The Rallly public URL is derived from your Railway domain at boot — after attaching a custom domain, redeploy once (or set NEXT_PUBLIC_BASE_URL explicitly). Organizer sign-in uses one-time email codes, so SMTP variables (SMTP_HOST, SMTP_PORT, SMTP_SECURE, optional SMTP_USER/SMTP_PWD) must be added before the first login; poll participants never need accounts or SMTP. Sessions are encrypted with a per-deployment SECRET_PASSWORD; set it explicitly for sessions that survive redeploys.

## Why Deploy

Deploying Rallly by hand means building the Docker image with the right build flags, provisioning Postgres, writing the connection string and public URL into environment variables, and running migrations before the server. This template does all of it in one click on Railway's managed infrastructure: migrations run on every boot, the /api/status healthcheck gates traffic until the app and database are actually ready, the restart policy recovers failed boots, and the volume keeps polls and votes across deploys and restarts. You get a public HTTPS domain instantly, usage-based pricing, and a one-command redeploy path when Rallly releases a new version — bump the digest in the repo and redeploy.

## Common Use Cases

- Team meeting scheduling: propose time slots for a meeting, sprint planning or retros, and let everyone vote on what works.
- Community and event planning: pick dates for club nights, game sessions, classes or workshops; guests vote from a plain link with no sign-up.
- Client-facing scheduling: send a booking-style poll to customers or volunteers and collect availability without exposing anyone's calendar.
- Replacing an aging Framadate/OpenSondage instance: Rallly is the actively developed successor, with spaces for team collaboration and optional SSO.

## Dependencies for

Rallly runs as a single Next.js server with PostgreSQL 18 as its only required backing service (provisioned by this template). One-time-code login requires SMTP access from the Rallly service — bring any SMTP provider's host, port, and credentials as variables after deploy. Everything else (Google/Microsoft/OIDC single sign-on, S3 file storage, Redis-backed rate limiting, Turnstile bot protection) is optional and enabled by adding the documented variables.

### Deployment Dependencies

- **Postgres** (included): postgres:18-alpine image, persistent volume at /var/lib/postgresql, generated POSTGRES_PASSWORD, DATABASE_URL referenced by Rallly over Railway's private network.
- **SMTP provider** (you supply after deploy): host, port, TLS flag, and optionally credentials — used to deliver the 6-digit sign-in codes to organizers.
- **A browser** — no other infrastructure is needed; voting needs no account.

**Licensing note:** Rallly is AGPL-3.0 open source and free for personal use. Multi-user instances (more than one registered organizer) are covered by an honor-system license from the upstream project; poll guests do not count as users.
