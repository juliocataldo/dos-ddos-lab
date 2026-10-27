#!/bin/sh
# Volta o alvo ao estado inicial (baseline), desfazendo as duas mitigações.
set -e

sysctl -w net.ipv4.tcp_syncookies=0 2>/dev/null || true

if [ -f /etc/nginx/conf.d/default.conf.off ]; then
  mv /etc/nginx/conf.d/default.conf.off /etc/nginx/conf.d/default.conf
fi
rm -f /etc/nginx/conf.d/active.conf

nginx -s reload
echo "[reset] alvo voltou ao baseline."
