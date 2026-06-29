# expense-splitter

Backend em Ruby para **divisão de despesas em grupo** e **quitação otimizada de dívidas** — dado quem pagou o quê numa viagem/churras/república, ele calcula o saldo de cada pessoa e o **menor conjunto de transferências** necessárias para todo mundo ficar quite.

**Zero dependências externas.** Só a biblioteca padrão do Ruby (`webrick`, `json`, `minitest`, `bigdecimal`). Não precisa de `bundle install`, não precisa de framework. Roda com o Ruby puro.

---

## Por que isso é interessante (a lógica que importa)

O grosso do valor está em duas partes, não no CRUD:

### 1. Dinheiro como centavos inteiros + rateio que sempre fecha
Trabalhar com dinheiro em `Float` é um clássico gerador de bug (`0.1 + 0.2 != 0.3`). Aqui todo valor é um `Money` imutável guardando **centavos inteiros**. O desafio real aparece no rateio: dividir R$ 10,00 entre 3 dá 3,33… e sobra 1 centavo. Onde ele vai?

Os splits por percentual e por cotas usam o **método do maior resto** (`largest-remainder`): cada um recebe o piso da sua fração exata, e os centavos restantes vão para quem tem o maior resto fracionário, com desempate determinístico pelo id. Resultado: **a soma das partes é sempre exatamente o total — nunca some nem cria 1 centavo**. Tem um teste de propriedade (`splits_test.rb`) que joga 40 cenários aleatórios pra provar isso.

Quatro estratégias de divisão (padrão Strategy): `equal`, `exact`, `percentage`, `share`. A invariante "a soma bate com o total" é garantida **uma vez**, na classe base, pra todas.

### 2. Otimizador de quitação (algoritmo guloso)
Dado o saldo líquido de cada um (positivo = tem a receber, negativo = deve), o `SettlementOptimizer` minimiza o número de transferências: repetidamente cruza **quem mais tem a receber** com **quem mais deve** e transfere o menor dos dois. Cada passo zera pelo menos uma pessoa, então o resultado tem no máximo `n-1` transferências.

Honestidade técnica: achar o mínimo **provado** é NP-difícil (variação de subset-sum). Esse guloso é a abordagem padrão, ótima nos casos comuns. Está documentado no código e a complexidade é O(n²). Os testes verificam que o plano **sempre quita todo mundo** (re-aplicando as transferências os saldos zeram) e respeita o limite de `n-1`.

---

## Arquitetura

A regra de negócio é feita de objetos Ruby puros (POROs), sem acoplamento com HTTP. A camada web é fina e plugável.

```
lib/expense_splitter/
├── money.rb                  # value object imutável (centavos)
├── member.rb / expense.rb    # entidades do domínio
├── group.rb                  # aggregate root: membros + despesas
├── balance.rb                # saldo líquido por membro (sempre soma 0)
├── settlement_optimizer.rb   # algoritmo guloso de quitação
├── splits/
│   ├── base_split.rb         # Strategy + invariante "soma == total"
│   ├── apportionment.rb      # método do maior resto (mixin)
│   └── equal/exact/percentage/share_split.rb
├── repository.rb             # store em memória (trocável por banco)
└── api/
    ├── router.rb             # roteador minúsculo (path -> regexp)
    ├── application.rb        # call(verb, path, body) -> [status, hash]  (testável sem servidor)
    └── server.rb             # adaptador WEBrick (trivial de propósito)
```

Destaque de design: `API::Application#call` é uma **função pura da requisição** — recebe `(verbo, path, corpo)` e devolve `[status, hash]`. Isso permite testar **toda** a API em processo, sem subir servidor nem abrir porta. O `Server` é só um adaptador que liga o WEBrick nesse `#call`.

---

## Rodando

Pré-requisito: Ruby 3.x (testado no 3.2). Nada além disso.

### Testes
```bash
rake test
# ou, sem rake:
ruby -Ilib -Itest -e 'Dir["test/**/*_test.rb"].each { |f| require File.expand_path(f) }'
```

### Servidor
```bash
ruby bin/server          # sobe em http://localhost:4567
PORT=8080 ruby bin/server # porta custom
```

---

## API

Todos os valores monetários trafegam como **centavos inteiros** (`amount_cents`, `balance_cents`) — sem ambiguidade pro cliente — junto de uma string já formatada (`R$ ...`) pronta pra exibir.

| Método | Rota | Descrição |
|--------|------|-----------|
| POST | `/groups` | Cria um grupo |
| GET | `/groups/:id` | Detalhe do grupo (membros, despesas, saldos, quitação) |
| POST | `/groups/:id/members` | Adiciona membro |
| POST | `/groups/:id/expenses` | Registra despesa |
| GET | `/groups/:id/balances` | Saldo líquido por membro |
| GET | `/groups/:id/settlements` | Plano otimizado de pagamentos |

### Exemplo

```bash
# 1. cria o grupo
curl -s -X POST localhost:4567/groups -d '{"name":"Churras"}'
# {"id":"grp_1","name":"Churras","members":[]}

# 2. adiciona membros
curl -s -X POST localhost:4567/groups/grp_1/members -d '{"name":"Alice"}'
curl -s -X POST localhost:4567/groups/grp_1/members -d '{"name":"Bob"}'
curl -s -X POST localhost:4567/groups/grp_1/members -d '{"name":"Carol"}'

# 3. Alice paga R$ 300,00 de carne, dividido igualmente
curl -s -X POST localhost:4567/groups/grp_1/expenses -d '{
  "description":"Carne","payer_id":"mbr_2","amount_cents":30000,
  "participant_ids":["mbr_2","mbr_3","mbr_4"],"split":{"type":"equal"}
}'

# 4. quem paga quem
curl -s localhost:4567/groups/grp_1/settlements
# {"settlements":[
#   {"from":"mbr_4","to":"mbr_2","amount_cents":10000,"amount":"R$ 100,00"},
#   {"from":"mbr_3","to":"mbr_2","amount_cents":10000,"amount":"R$ 100,00"}
# ]}
```

### Tipos de split aceitos no campo `split`

```jsonc
{"type":"equal"}                                              // divide igual
{"type":"exact","amounts":{"mbr_2":7000,"mbr_3":3000}}        // valor exato (centavos) por pessoa
{"type":"percentage","percentages":{"mbr_2":70,"mbr_3":30}}  // por % (soma 100)
{"type":"share","shares":{"mbr_2":2,"mbr_3":1}}              // por cotas/peso
```

---

## Tratamento de erros

| Status | Quando |
|--------|--------|
| 400 | corpo não é JSON válido |
| 404 | rota ou grupo inexistente, membro desconhecido |
| 422 | parâmetro faltando ou dado inválido (ex.: percentuais que não somam 100, split que não fecha com o total) |

---

## Notas

- **Concorrência:** o store em memória não é thread-safe; para produção ele seria trocado por um repositório com banco (o domínio não muda).
- **Otimalidade:** ver a seção do otimizador — guloso, não mínimo-provado, por design e documentado.
