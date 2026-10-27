#!/bin/sh
# Mitigação para SYN flood: liga TCP SYN cookies.
# Com syncookies, o kernel não reserva estado para cada SYN recebido —
# ele só cria a conexão de verdade quando o ACK final chega com o cookie certo.
echo "[mitigate-syn] estado atual:"
sysctl net.ipv4.tcp_syncookies

sysctl -w net.ipv4.tcp_syncookies=1

echo "[mitigate-syn] novo estado:"
sysctl net.ipv4.tcp_syncookies
echo "[mitigate-syn] pronto. Rode o ataque de novo e compare o dashboard."
