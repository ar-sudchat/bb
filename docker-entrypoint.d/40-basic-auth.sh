#!/bin/sh
# Generate nginx Basic Auth file at container start from env vars.
# Override in Coolify: BASIC_AUTH_USER / BASIC_AUTH_PASSWORD (keeps secret out of git).
set -e

AUTH_USER="${BASIC_AUTH_USER:-admin}"
AUTH_PASS="${BASIC_AUTH_PASSWORD:-1234}"

htpasswd -bc /etc/nginx/.htpasswd "$AUTH_USER" "$AUTH_PASS" >/dev/null 2>&1
echo "[basic-auth] enabled — user: $AUTH_USER"
