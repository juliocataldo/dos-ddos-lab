#!/bin/sh
# Mitigação para HTTP flood: ativa limit_req (taxa de requisições por IP)
# na rota /heavy, em vez do limit_conn usado para Slowloris.
set -e

cp /etc/nginx/conf.d/flood-mitigated.conf.disabled /etc/nginx/conf.d/active.conf
mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.off

nginx -s reload

echo "[mitigate-flood] limit_req ativo (5 req/s por IP, burst 10). Rode o ataque de novo e compare o dashboard."
