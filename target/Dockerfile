FROM nginx:1.27-alpine

# Exporter de métricas vira um container separado (ver docker-compose.yml) —
# evita build com apk/curl, que quebra atrás de proxy com inspeção TLS.
#
# worker_connections baixo de propósito: simula um servidor pequeno para que
# o ataque com poucas centenas de conexões/pacotes já tenha efeito visível.
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-default.conf /etc/nginx/conf.d/default.conf
COPY nginx-mitigated.conf /etc/nginx/conf.d/mitigated.conf.disabled
COPY nginx-flood-mitigated.conf /etc/nginx/conf.d/flood-mitigated.conf.disabled
COPY index.html /usr/share/nginx/html/index.html
COPY mitigate-syn.sh mitigate-slowloris.sh mitigate-flood.sh reset.sh /
RUN chmod +x /mitigate-syn.sh /mitigate-slowloris.sh /mitigate-flood.sh /reset.sh

# Arquivo quase-aleatório (comprime mal) para custar CPU de verdade a cada
# vez que o nginx tenta comprimir na resposta — é o alvo do HTTP flood.
RUN dd if=/dev/urandom bs=1024 count=1536 2>/dev/null | base64 > /usr/share/nginx/html/heavy.txt

EXPOSE 80
