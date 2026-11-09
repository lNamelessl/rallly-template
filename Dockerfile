# Rallly on Railway — thin wrapper over the official image.
#
# Pinned: lukevella/rallly v4.16.4 (released 2026-11-01), multi-arch index
# digest. The official image already: runs migrations on boot
# (docker-start.sh -> prisma migrate deploy), listens on $PORT, ships a
# container HEALTHCHECK at /api/status, and is built with
# NEXT_PUBLIC_SELF_HOSTED=true (self-hosted mode, billing UI removed).
FROM lukevella/rallly:4.16.4@sha256:1dacb9297f29d89d543f6fe4de2f8703b2c59e854bac1953fc66a6dbc1d1d8b0

# SUPPORT_EMAIL is required by Rallly's runtime env validation (must be a
# valid email) and is the default From address for one-time-code emails
# unless NOREPLY_EMAIL is set. Baked here so the template deploys with zero
# prompts. Override with a service variable for production use.
ENV SUPPORT_EMAIL=support@example.com

# Install the boot wrapper (derives NEXT_PUBLIC_BASE_URL from Railway's
# injected domain). The base image declares USER nextjs, so toggle to root
# only for the file placement and back.
USER root
COPY docker-entrypoint-wrapper.sh /usr/local/bin/docker-entrypoint-wrapper.sh
RUN chmod 0755 /usr/local/bin/docker-entrypoint-wrapper.sh
USER nextjs

# The base image CMD ["./docker-start.sh"] is inherited and arrives as args
# to this entrypoint; the wrapper ignores them and execs the same script.
ENTRYPOINT ["/usr/local/bin/docker-entrypoint-wrapper.sh"]
