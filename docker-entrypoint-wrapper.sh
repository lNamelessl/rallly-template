#!/bin/sh
# Rallly on Railway boot wrapper.
# Runs as the image's `nextjs` user before the upstream docker-start.sh.
set -e

# NEXT_PUBLIC_BASE_URL is required by Rallly (public URL incl. scheme; used
# for auth callbacks, poll links and email links). Derive it from the
# Railway-injected public domain unless the operator set it explicitly.
# After adding a custom domain, redeploy to pick up the new value.
export NEXT_PUBLIC_BASE_URL="${NEXT_PUBLIC_BASE_URL:-https://${RAILWAY_PUBLIC_DOMAIN}}"

# SECRET_PASSWORD (required, min 32 chars) encrypts sessions. Boot-generate
# one if unset so the container always boots. NOTE: a boot-generated value
# rotates on every redeploy (users simply re-login via email code; poll data
# is unaffected — it lives in Postgres). Set SECRET_PASSWORD explicitly for
# sessions that survive redeploys.
export SECRET_PASSWORD="${SECRET_PASSWORD:-$(node -e 'console.log(require("crypto").randomBytes(32).toString("hex"))')}"

# Upstream entrypoint (in /app): prisma migrate deploy, then the Next.js
# server. MAINTENANCE_MODE=true skips migrations.
exec /app/docker-start.sh
