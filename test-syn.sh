#!/usr/bin/env bash
# Valida se o SYN flood deste lab realmente degrada o alvo na SUA máquina.
# Ver README.md, seção "O que eu NÃO consegui validar", para o contexto.
#
# Uso: ./test-syn.sh [duracao_segundos] [pacotes_por_segundo]
# Ex.:  ./test-syn.sh 15 800

set -u
export MSYS_NO_PATHCONV=1   # evita o Git Bash converter "/proc/..." em caminho do Windows

DURATION="${1:-15}"
RATE="${2:-800}"
REQS_DURING="${REQS_DURING:-15}"   # quantas requisições legítimas tentamos durante o ataque

cd "$(dirname "$0")" || exit 1

syn_recv_count() {
  # "grep -c" sai com status 1 quando a contagem é zero, o que disparava um
  # "|| echo 0" extra e duplicava a saída — por isso a contagem é toda em awk.
  local n
  n=$(docker exec target sh -c "awk 'NR>1 && \$4==\"03\" {c++} END{print c+0}' /proc/net/tcp" 2>/dev/null)
  echo "${n:-0}"
}

accepted_count() {
  docker exec attacker curl -s --max-time 3 http://nginx-exporter:9113/metrics 2>/dev/null \
    | awk '/^nginx_connections_accepted/ {print $2}'
}

legit_requests_ok() {
  local n="$1" ok=0
  for _ in $(seq 1 "$n"); do
    code=$(docker exec attacker curl -s -o /dev/null -w "%{http_code}" --max-time 2 http://target/ 2>/dev/null)
    [ "$code" = "200" ] && ok=$((ok + 1))
  done
  echo "$ok"
}

echo "==> Subindo a stack (se já estiver no ar, não faz nada)"
docker compose up -d >/dev/null 2>&1
sleep 3

echo "==> Resetando o alvo para o baseline"
docker exec target sh -c "/reset.sh" >/dev/null 2>&1

echo "==> Baseline: testando $REQS_DURING requisições legítimas (esperado: $REQS_DURING/$REQS_DURING)"
BASELINE_OK=$(legit_requests_ok "$REQS_DURING")
BASELINE_SYN=$(syn_recv_count)
echo "    OK: $BASELINE_OK/$REQS_DURING | conexões em SYN_RECV: $BASELINE_SYN"

echo "==> Disparando attack-syn.sh $DURATION $RATE em background"
docker exec -d attacker attack-syn.sh "$DURATION" "$RATE"
sleep 2

echo "==> Durante o ataque: testando $REQS_DURING requisições legítimas e lendo SYN_RECV (3 amostras)"
DURING_OK=$(legit_requests_ok "$REQS_DURING")
S1=$(syn_recv_count); sleep 1
S2=$(syn_recv_count); sleep 1
S3=$(syn_recv_count)
echo "    OK: $DURING_OK/$REQS_DURING | SYN_RECV amostras: $S1 / $S2 / $S3"

echo "==> Esperando o ataque terminar..."
sleep "$((DURATION + 2))"

echo "==> Depois do ataque: o site se recupera?"
AFTER_OK=$(legit_requests_ok "$REQS_DURING")
AFTER_SYN=$(syn_recv_count)
echo "    OK: $AFTER_OK/$REQS_DURING | conexões em SYN_RECV: $AFTER_SYN"

echo ""
echo "===================== VEREDITO ====================="
MAX_SYN=$S1
[ "$S2" -gt "$MAX_SYN" ] 2>/dev/null && MAX_SYN=$S2
[ "$S3" -gt "$MAX_SYN" ] 2>/dev/null && MAX_SYN=$S3

if [ "$MAX_SYN" -ge 10 ] 2>/dev/null || [ "$DURING_OK" -lt "$BASELINE_OK" ] 2>/dev/null; then
  echo "PASSOU — o ataque teve efeito mensurável nesta máquina."
  echo "  (SYN_RECV subiu para $MAX_SYN e/ou requisições legítimas caíram de $BASELINE_OK para $DURING_OK)"
  echo "  Pode seguir com o SYN flood no roteiro do aluno como está."
else
  echo "NÃO PASSOU — não vi efeito claro do SYN flood nesta máquina."
  echo "  (SYN_RECV ficou em $MAX_SYN, requisições legítimas: baseline=$BASELINE_OK durante=$DURING_OK)"
  echo "  Possíveis causas: driver de rede do Docker filtrando --rand-source,"
  echo "  runtime sandboxed, ou a taxa/duração precisam subir (tente ./test-syn.sh 20 2000)."
  echo "  Plano B: use só o Slowloris no roteiro de 60 min (já validado)."
fi
echo "======================================================"
echo ""
echo "Alvo recuperado após o ataque: $AFTER_OK/$REQS_DURING requisições OK."
