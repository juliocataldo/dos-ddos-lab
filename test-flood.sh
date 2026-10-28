#!/usr/bin/env bash
# Valida se o HTTP flood (/heavy.txt) satura a CPU do alvo nesta máquina.
#
# Uso: ./test-flood.sh [vus] [duracao]
# Ex.:  ./test-flood.sh 100 20s

set -u
export MSYS_NO_PATHCONV=1

VUS="${1:-100}"
DURATION="${2:-20s}"

cd "$(dirname "$0")" || exit 1

cpu_pct() {
  docker stats target --no-stream --format "{{.CPUPerc}}" | tr -d '%'
}

echo "==> Subindo a stack (se já estiver no ar, não faz nada)"
docker compose up -d >/dev/null 2>&1
sleep 3

echo "==> Resetando o alvo para o baseline"
docker exec target sh -c "/reset.sh" >/dev/null 2>&1
sleep 1

echo "==> CPU em repouso"
IDLE=$(cpu_pct)
echo "    $IDLE%"

echo "==> Disparando flood ($VUS VUs, $DURATION) em background"
docker exec -d k6 k6 run --vus "$VUS" --duration "$DURATION" /scripts/flood.js --quiet
sleep 4

echo "==> CPU durante o ataque (2 amostras)"
C1=$(cpu_pct); sleep 2
C2=$(cpu_pct)
echo "    $C1% / $C2%"

echo "==> Esperando o flood terminar..."
sleep 20

echo "==> CPU depois do ataque"
AFTER=$(cpu_pct)
echo "    $AFTER%"

echo ""
echo "===================== VEREDITO ====================="
MAX_C=$C1
awk "BEGIN{exit !($C2>$MAX_C)}" && MAX_C=$C2

if awk "BEGIN{exit !($MAX_C>60)}"; then
  echo "PASSOU — CPU chegou a ${MAX_C}% durante o flood (idle: ${IDLE}%)."
  echo "  Pode seguir com o HTTP flood no roteiro do aluno como está."
else
  echo "NÃO PASSOU — CPU ficou em ${MAX_C}%, não satura visivelmente."
  echo "  Tente mais VUs: ./test-flood.sh 200 20s"
  echo "  Ou confirme o limite de CPU do container 'target' no docker-compose.yml (cpus: \"1.0\")."
fi
echo "======================================================"
