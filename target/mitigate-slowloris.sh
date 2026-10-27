#!/bin/sh
# Mitigação para Slowloris: troca a config do nginx pela versão com timeouts
# curtos de header/body e limit_conn por IP.
set -e

cp /etc/nginx/conf.d/mitigated.conf.disabled /etc/nginx/conf.d/active.conf
mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.off

nginx -s reload

echo "[mitigate-slowloris] config mitigada ativa. Rode o ataque de novo e compare o dashboard."
