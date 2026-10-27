# Lab DoS/DDoS — roteiro do aluno (60 min)

> Laboratório isolado, sem acesso à internet. Tudo acontece dentro do seu próprio notebook.
> Antes de começar, preencha e assine o `termo-autorizacao.md`.

## 0. Subir o ambiente (5 min)

```bash
docker compose up -d
```

Abra:
- Site alvo: http://localhost:8080
- Grafana: http://localhost:3000 (sem login)

## 1. Baseline — como é o site saudável (10 min)

Em um terminal, gere tráfego legítimo:

```bash
docker exec k6 k6 run /scripts/baseline.js
```

Enquanto roda, olhe o Grafana. Anote na tabela abaixo: RPS normal, conexões ativas normais.

**Antes de continuar, escreva uma previsão:** o que você acha que vai acontecer com o RPS quando o ataque começar?

_____________________________________________

## 2. SYN flood (15 min)

Abra outro terminal e entre no container atacante:

```bash
docker exec -it attacker bash
attack-syn.sh 30 200
```

Deixe o `baseline.js` rodando ao mesmo tempo (rode de novo se já tiver terminado).

Em outro terminal, observe o estado das conexões no alvo (a imagem não tem `ss`,
então lemos direto de `/proc/net/tcp` — o estado `03` em hexadecimal é `SYN_RECV`):

```bash
docker exec target sh -c "awk 'NR>1 {print \$4}' /proc/net/tcp | sort | uniq -c"
```

Anote: quantas conexões no estado `03`? O que aconteceu com o RPS no Grafana?

## 3. Slowloris (15 min)

Ainda no container atacante:

```bash
attack-slowloris.sh 30 180
```

Observe no Grafana o painel "Conexões ativas" — repare que a CPU e a banda praticamente não sobem,
mas o site trava. Essa é a diferença entre ataque volumétrico (SYN flood) e ataque de aplicação (Slowloris).

## 4. Mitigação medida (15 min)

Aplique uma mitigação por vez e **repita o ataque correspondente** para medir o efeito:

```bash
# mitigação para SYN flood
docker exec target /mitigate-syn.sh
# repita: attack-syn.sh 30 200

# mitigação para Slowloris
docker exec target /mitigate-slowloris.sh
# repita: attack-slowloris.sh 30 180
```

Preencha a tabela:

| Cenário | RPS | Conexões ativas | Site respondeu? |
|---|---|---|---|
| Baseline | | | |
| SYN flood (sem mitigação) | | | |
| SYN flood (com syncookies) | | | |
| Slowloris (sem mitigação) | | | |
| Slowloris (com limit_conn/timeout) | | | |

## 5. Fechamento (5 min)

Responda em 3-4 linhas:

1. Qual mitigação te surpreendeu mais, e por quê?
2. A mitigação aplicada teve algum custo para um usuário legítimo? Qual?
3. Se o ataque fosse 1000x maior (saturando o link, não só o servidor), essas mitigações ainda resolveriam? O que seria necessário?

## Para encerrar

```bash
docker exec target /reset.sh
docker compose down
```
