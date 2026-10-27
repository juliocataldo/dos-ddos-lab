FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        hping3 \
        slowhttptest \
        tcpdump \
        curl \
        iproute2 \
        procps \
    && rm -rf /var/lib/apt/lists/*

COPY attack-syn.sh attack-slowloris.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/attack-syn.sh /usr/local/bin/attack-slowloris.sh

WORKDIR /root
