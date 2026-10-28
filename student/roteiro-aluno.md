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

## 1. Baseline — como é o site saudável (5 min)

Em um terminal, gere tráfego legítimo:

```bash
docker exec k6 k6 run /scripts/baseline.js
```

Enquanto roda, olhe o Grafana. Anote: RPS normal, conexões ativas normais, CPU normal.

**Antes de continuar, escreva uma previsão:** entre "muita gente pedindo pouca coisa"
e "pouca gente pedindo uma coisa cara", qual você acha que derruba o site mais rápido?

_____________________________________________

## 2. Ataque de aplicação de baixo volume — Slowloris (15 min)

Entre no container atacante:

```bash
docker exec -it attacker bash
attack-slowloris.sh 30 180
```

Deixe o `baseline.js` rodando ao mesmo tempo (rode de novo se já tiver terminado).

Observe no Grafana: **conexões ativas** sobem bastante, mas **CPU e RPS quase não se mexem**.
Esse é o padrão de um ataque que não precisa de volume — só precisa manter conexões
abertas e incompletas até esgotar as vagas do servidor.

## 3. Ataque volumétrico de aplicação — HTTP flood (15 min)

Agora o oposto: muita requisição, numa rota propositalmente cara de responder
(`/heavy.txt`, que o nginx precisa comprimir a cada pedido).

```bash
docker exec k6 k6 run /scripts/flood.js
```

Observe no Grafana: desta vez é a **CPU que vai ao talo** (o alvo está limitado a
1 CPU neste lab), enquanto RPS despenca porque o servidor não consegue processar
a fila.

**Compare com o Slowloris:** qual métrica subiu em cada ataque? CPU, conexões, ou as duas?

## 4. Mitigação medida (15 min)

Aplique uma mitigação por vez e **repita o ataque correspondente**:

```bash
# mitigação para Slowloris: timeouts curtos + limite de conexões por IP
docker exec target /mitigate-slowloris.sh
# repita: attack-slowloris.sh 30 180

# volte ao baseline antes de testar a outra mitigação
docker exec target /reset.sh

# mitigação para HTTP flood: limite de TAXA de requisições por IP
docker exec target /mitigate-flood.sh
# repita: docker exec k6 k6 run /scripts/flood.js
```

Preencha a tabela:

| Cenário | CPU | Conexões ativas | Site respondeu a um usuário normal? |
|---|---|---|---|
| Baseline | | | |
| Slowloris (sem mitigação) | | | |
| Slowloris (com `limit_conn` + timeout) | | | |
| HTTP flood (sem mitigação) | | | |
| HTTP flood (com `limit_req`) | | | |

## 5. Fechamento (5 min)

Responda em 3-4 linhas:

1. `limit_conn` (conexões simultâneas) e `limit_req` (taxa de requisições) resolvem
   problemas diferentes. Qual ataque cada um combate, e por quê o outro limite
   não resolveria o mesmo problema?
2. A mitigação aplicada teve algum custo para um usuário legítimo? Qual?
3. Se o ataque fosse 1000x maior (saturando o link, não só o servidor), essas
   mitigações ainda resolveriam? O que seria necessário?

## Nota sobre SYN flood

O ataque de protocolo mais clássico (SYN flood, com `hping3`) está disponível em
`attacker/attack-syn.sh`, mas seu efeito depende muito do driver de rede do Docker
na sua máquina — em alguns ambientes os pacotes forjados não chegam ao alvo em
volume suficiente. Se quiser tentar: `./test-syn.sh` na raiz do repositório diz
se vale a pena incluir no seu roteiro.

## Para encerrar

```bash
docker exec target /reset.sh
docker compose down
```
