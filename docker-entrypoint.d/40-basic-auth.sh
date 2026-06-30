#!/bin/sh
# Runs before nginx starts (official image runs /docker-entrypoint.d/*.sh).
# Builds two things from env (override in Coolify, keeps secrets out of git):
#   BASIC_AUTH_USER / BASIC_AUTH_PASSWORD → login credentials (default admin/1234)
#   SMC_AUTH_TOKEN                        → session-cookie secret (else random per start)
set -e

AUTH_USER="${BASIC_AUTH_USER:-admin}"
AUTH_PASS="${BASIC_AUTH_PASSWORD:-1234}"
htpasswd -bc /etc/nginx/.htpasswd "$AUTH_USER" "$AUTH_PASS" >/dev/null 2>&1

TOKEN="${SMC_AUTH_TOKEN:-$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')}"
cat > /etc/nginx/conf.d/00-auth.conf <<EOF
map \$cookie_smc_auth \$smc_ok   { default 0; "$TOKEN" 1; }
map \$host           \$smc_token { default "$TOKEN"; }
EOF

echo "[basic-auth] login user: $AUTH_USER · session cookie ready"
