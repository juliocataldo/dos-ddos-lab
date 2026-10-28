# Lab DoS/DDoS — SYN Flood & Slowloris em ambiente isolado

Laboratório hands-on para ensino de ataques de negação de serviço (DoS), construído
para uma disciplina introdutória de Cyber Security. Todo o ambiente roda em
containers Docker numa rede sem acesso à internet — o aluno ataca, observa o
impacto em métricas reais e aplica uma mitigação medida, sem nunca sair da própria
máquina.

## Objetivo de aprendizagem

Ao final do laboratório, o aluno é capaz de:

- Diferenciar um ataque **volumétrico/protocolo** (SYN flood) de um ataque de
  **camada de aplicação** (Slowloris) observando o comportamento de cada um em
  métricas de rede e de servidor.
- Interpretar indicadores de comprometimento de disponibilidade: estado de
  conexões TCP, conexões ativas por fase (lendo/escrevendo/esperando) e taxa de
  requisições.
- Aplicar e **medir o efeito** de uma contramedida específica para cada vetor
  (TCP SYN cookies; timeouts e `limit_conn` no servidor web).
- Discutir os limites de mitigação em nível de host frente a um ataque que
  satura o link de rede.

## Arquitetura

```
┌──────────┐      rede Docker interna (sem saída p/ internet)
│ attacker │──────────────┐
│ hping3   │              │
│ slowhttp │              ▼
└──────────┘        ┌──────────┐      ┌────────────────┐      ┌───────────┐
                     │  target  │─────▶│ nginx-exporter │─────▶│ Prometheus│
┌──────────┐         │  nginx   │      └────────────────┘      └─────┬─────┘
│    k6    │────────▶│          │                                    │
│(baseline)│         └──────────┘                                    ▼
└──────────┘                                                   ┌───────────┐
                                                                 │  Grafana  │
                                                                 └───────────┘
```

| Componente | Papel |
|---|---|
| `target` | nginx configurado com capacidade reduzida (1 worker, 128 conexões), simulando um servidor pequeno |
| `attacker` | `hping3` (SYN flood) e `slowhttptest` (Slowloris), com scripts de taxa e duração limitadas |
| `k6` | gera tráfego legítimo contínuo, para medir o impacto real em usuário |
| `nginx-exporter` + `Prometheus` + `Grafana` | coleta e exibe RPS, conexões ativas e uso de CPU/memória do alvo em tempo real |

## Pré-requisitos

- Docker e Docker Compose
- Nenhum conhecimento prévio de Prometheus/Grafana é necessário — o dashboard já
  vem provisionado

## Como rodar

```bash
git clone https://github.com/juliocataldo/dos-ddos-lab.git
cd dos-ddos-lab
docker compose up -d
```

- Site alvo: http://localhost:8080
- Dashboard: http://localhost:3000

Valide o ambiente antes de usar em aula:

```bash
./test-syn.sh          # mede o efeito do SYN flood nesta máquina (PASSOU/NÃO PASSOU)
```

Roteiro completo do aluno, com tabela de medição e perguntas de fechamento, em
[`student/roteiro-aluno.md`](student/roteiro-aluno.md).

## Estrutura do repositório

```
dos-ddos-lab/
  docker-compose.yml
  target/           # nginx + scripts de mitigação (mitigate-syn.sh, mitigate-slowloris.sh) e reset.sh
  attacker/          # hping3 + slowhttptest + scripts de ataque (attack-syn.sh, attack-slowloris.sh)
  prometheus/        # configuração de scrape
  grafana/           # dashboard e datasource provisionados
  k6/                # script de tráfego legítimo (baseline.js)
  student/           # roteiro do aluno + termo de autorização
  test-syn.sh         # valida o efeito do SYN flood no host atual
```

## Limitações conhecidas

O efeito do SYN flood depende de como o runtime/driver de rede do Docker trata
pacotes `hping3 --rand-source` — em alguns ambientes (runtimes de container
mais restritos, certas configurações de rede) os pacotes forjados não chegam
ao alvo com volume suficiente para gerar `SYN_RECV` mensurável. O Slowloris,
por operar em HTTP/TCP padrão, não tem essa dependência e é o cenário
recomendado quando o `test-syn.sh` não confirmar efeito.

## Ética e legislação

Este ambiente é isolado (rede `internal: true`, sem rota para a internet) e
deve ser usado **exclusivamente** contra o container `target` incluído no
`docker-compose.yml`. O uso dessas ferramentas contra qualquer sistema de
terceiros, sem autorização por escrito, é crime previsto na Lei 12.737/2012
(Lei Carolina Dieckmann). Ver [`student/termo-autorizacao.md`](student/termo-autorizacao.md).

## Autoria

Material didático desenvolvido por Julio Cataldo para disciplina de Cyber
Security, com apoio de Claude (Anthropic) no desenho e implementação do
ambiente de laboratório.
