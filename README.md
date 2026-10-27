# Lab DoS — SYN flood + Slowloris (60 min, treino livre)

## O que eu já testei e funciona (ponta a ponta)

Testei num ambiente Docker isolado (sandbox, não a sua máquina) e corrigi 4 bugs
que o build pegou:

1. **Build do `attacker` e do `target`** — ok.
2. **`docker compose up`** sobe os 7 containers.
3. **Slowloris + mitigação, com números reais medidos:**

   | Cenário | Site responde? | Latência | Conexões ativas |
   |---|---|---|---|
   | Baseline | sim | ~0,001s | ~1-2 |
   | Ataque (sem mitigação) | **não — conexão recusada** | — | — |
   | Ataque (com `mitigate-slowloris.sh`) | sim | ~0,076s | ~45 |

4. **`reset.sh`** volta a config ao estado inicial, confirmado.
5. **Grafana** provisiona o dashboard automaticamente (log confirma:
   `dashboardTitle="DoS Lab — Alvo"`), **Prometheus** confirma scrape
   `"health":"up"` no nginx-exporter.

Dois bugs que corrigi e já estão no código:
- O dashboard do Grafana não subia por causa de um mount aninhado dentro de
  um volume `:ro` — reestruturei os arquivos.
- O `nginx:alpine` padrão sobe com 8 workers × 1024 conexões, capacidade
  grande demais para um ataque de ~150-200 conexões ter efeito visível —
  adicionei um `nginx.conf` que limita a 1 worker / 128 conexões, simulando
  um servidor pequeno de verdade.

## O que eu NÃO consegui validar — teste você antes da aula

**SYN flood: não consegui confirmar que ele chega no alvo neste ambiente.**
Mandei ~50 mil pacotes SYN com `hping3` e o contador de `accepts` do nginx
quase não se moveu — o estado `SYN_RECV` nunca apareceu em `/proc/net/tcp`.
Isso pode ser uma limitação específica do ambiente sandboxed onde testei
(sockets raw/spoofing costumam ser restringidos em runtimes de container
mais isolados) e não necessariamente do seu Docker Desktop. **Mas é o único
pedaço do lab que não tenho prova de que funciona — rode isto antes de
levar para a turma:**

```bash
./test-syn.sh          # usa 15s / 500 pps por padrão
./test-syn.sh 20 2000  # ou ajuste duração/taxa
```

O script sobe a stack, mede requisições legítimas e estado `SYN_RECV` antes,
durante e depois do ataque, e imprime **PASSOU** ou **NÃO PASSOU** com os
números. Se der "NÃO PASSOU", **o lab de 60 min funciona igual só com
Slowloris** (já validado) e o SYN flood vira demonstração/discussão em vez
de hands-on medido.

## Antes da aula — faça isso você, não o aluno

O build do `attacker` usa `apt-get`, que funcionou no meu teste. Mas o build
original do `target` (que eu já removi) usava `apk add curl` para baixar o
exporter do GitHub, e isso **quebrou** por causa de inspeção TLS de rede
corporativa (certificado self-signed). Troquei o exporter por um container
separado (imagem oficial `nginx/nginx-prometheus-exporter`), então isso já
não é mais problema — mas serve de aviso: **evite adicionar qualquer `apk`/
`curl` que baixe algo da internet durante o build**, nesta rede isso falha.

Mesmo assim, se quiser blindar 100% contra a rede da faculdade:

```bash
docker compose build attacker target
docker tag dos-lab-attacker SEU_USUARIO/dos-lab-attacker:1
docker tag dos-lab-target SEU_USUARIO/dos-lab-target:1
docker push SEU_USUARIO/dos-lab-attacker:1
docker push SEU_USUARIO/dos-lab-target:1
```

E troque `build:` por `image: SEU_USUARIO/...` no `docker-compose.yml`.

## Nota para quem for rodar comandos manualmente no Windows (Git Bash)

Se você usar Git Bash para rodar `docker exec target /mitigate-syn.sh`, o
Git Bash pode **converter o caminho `/mitigate-syn.sh` para um caminho do
Windows** e quebrar o comando. Dois jeitos de evitar:

```bash
MSYS_NO_PATHCONV=1 docker exec target /mitigate-syn.sh
# ou
docker exec target sh -c "/mitigate-syn.sh"
```

Isso só afeta quem roda comandos soltos fora do roteiro — os scripts do
`student/roteiro-aluno.md` já foram escritos pensando nisso.

## Ainda vale a pena calibrar

Os números (`attack-syn.sh 15 500`, `attack-slowloris.sh 30 180`) foram os
que funcionaram no meu teste. Rode uma vez no seu hardware real da aula —
pode precisar de ajuste para cima ou para baixo.

## Estrutura de arquivos

```
dos-lab/
  docker-compose.yml
  target/          # nginx (1 worker/128 conexões) + scripts de mitigação/reset
  attacker/         # hping3 + slowhttptest + scripts de ataque (rate-limited)
  prometheus/
  grafana/          # datasource + dashboard provisionados
  k6/               # tráfego legítimo (baseline)
  student/          # roteiro do aluno + termo de autorização
```

## O que ficou fora deste escopo de 1h

- DNS amplification, HTTP/2 Rapid Reset, ML (CICDDoS2019) — ficaram como
  demonstração do professor ou take-home, conforme combinado.
- Wireshark não entra neste roteiro rápido; dá para acrescentar depois pedindo
  ao aluno para capturar com `docker exec attacker tcpdump -i eth0 -w /tmp/cap.pcap`
  durante o ataque (o `target` não tem `tcpdump` instalado, só o `attacker`).
