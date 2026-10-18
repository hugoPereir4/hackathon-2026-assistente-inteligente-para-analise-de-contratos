# Respostas, confirmação e reavaliação

Todas as operações exigem JWT e usam somente documentos da empresa autenticada.
A entrega é síncrona. A prévia faz uma chamada à IA; a confirmação faz outra para
reanalisar. Nenhuma delas inclui chamadas reais nos testes automatizados.

Execute `python manage.py migrate` antes de usar os novos endpoints. A migração
`0002_document_answer_batches` cria a tabela dos lotes, sem converter análises ou
fatos existentes. Reinicie servidores e shells para carregar os novos modelos.

## 1. Obter perguntas atuais

Consulte `GET /api/v1/documents/{id}/`. Perguntas estão em
`analysis_json.perguntas_pendentes`. Este fluxo requer `schema_version: 2` e
documento `ready`. Para uma análise anterior, execute primeiro
`POST /api/v1/documents/{id}/reanalyze/`, sem body.

Exemplo de pergunta v2:

```json
{
  "id": "q1",
  "pergunta": "Sua empresa já possui certificação ISO 9001?",
  "requisito_ids": ["r1"],
  "fato_chave": "iso_9001",
  "destino": "company_fact",
  "fato_rotulo": "Possui certificação ISO 9001",
  "tipo_valor": "booleano"
}
```

O destino e a chave vêm da pergunta salva, nunca do body de confirmação. Chaves
existentes são reutilizadas; fatos ausentes já recebem uma chave para sua criação.
Perguntas `cadastro` não podem ser respondidas por esses endpoints.

## 2. Gerar prévia sem alterar o perfil

`POST /api/v1/documents/{id}/answers/preview/`

```json
{
  "respostas": [
    {"pergunta_id": "q1", "texto": "Sim, temos ISO 9001."}
  ]
}
```

São aceitas de 1 a 100 respostas, com IDs distintos e texto de até 10.000 caracteres
por resposta. É permitido responder apenas parte das perguntas atuais.

O retorno `201` contém o UUID `id` do lote, `document`, `analysis_fingerprint`,
`original_answers`, `proposals`, `status: "pending"`, datas de criação e confirmação,
IDs aprovados e autorizados e o estado/erro da reavaliação (inicialmente sem estado).
Exemplo de item de `proposals`:

```json
{
  "id": "q1",
  "pergunta_id": "q1",
  "pergunta": "Sua empresa já possui certificação ISO 9001?",
  "texto_original": "Sim, temos ISO 9001.",
  "fato_chave": "iso_9001",
  "fato_rotulo": "Possui certificação ISO 9001",
  "valor_proposto": true,
  "tipo_valor": "booleano",
  "tipos_campos": null,
  "suficiente": true,
  "justificativa": "O usuário confirmou que já possui a certificação.",
  "esclarecimento": null,
  "valor_anterior": null,
  "exige_autorizacao_substituicao": false
}
```

Quando o fato já existe, `valor_anterior` contém `valor`, `confirmado`, `origem`
e `rotulo`. O backend registra esse retrato e o hash da análise para detectar
alterações entre a prévia e a confirmação. A prévia não grava `CompanyFact`.

Uma negativa explícita é um booleano `false`. Respostas incertas como “não sei”
ou “estamos buscando a certificação” devem produzir `suficiente: false`,
valor/tipo nulos e uma pergunta em `esclarecimento`. Não podem ser aprovadas;
envie uma nova resposta para criar outra prévia. A interpretação é feita pela IA
e deve ser revisada pelo usuário antes de confirmar.

Decimais usam strings, por exemplo `"1234567890123456789.90"`; datas usam
`YYYY-MM-DD`. Objetos novos são planos e cada campo escalar tem seu tipo em
`tipos_campos`, por exemplo `{"ano": "inteiro", "moeda": "texto", "valor": "decimal"}`.
Listas, floats e objetos aninhados não são aceitos pela interpretação nesta versão.
Atualizações preservam os tipos JSON e as chaves de objetos existentes.

## 3. Confirmar propostas revisadas

`POST /api/v1/documents/{id}/answers/{batch_id}/confirm/`

```json
{
  "propostas_aprovadas": ["q1"],
  "autorizar_substituicao": []
}
```

Para um item com `exige_autorizacao_substituicao: true`, inclua também seu ID em
`autorizar_substituicao`. Essa autorização é exigida quando o valor proposto difere
de um fato já confirmado. Sem autorização, a confirmação inteira recebe `409`,
sem gravações parciais. Fatos não confirmados podem ser substituídos com a aprovação
geral da proposta.

Somente IDs existentes na proposta salva são aceitos. Novos valores, destinos e
IDs de empresa enviados no body não alteram o que foi revisado. Para corrigir
uma interpretação, gere outra prévia.

Pode-se aprovar um subconjunto das propostas. A primeira confirmação encerra o
lote; propostas não aprovadas não são aplicadas. Perguntas que continuarem
pendentes na nova análise podem receber outro lote.

O backend grava os fatos com `source: "user"` e `confirmed: true` e registra os
IDs aprovados, as autorizações e a data. Tudo ocorre em uma transação curta,
com aquisição atômica do documento e serialização por empresa. A análise da IA
começa após o commit. Confirmações repetidas do mesmo lote retornam o estado
salvo, sem nova gravação nem nova geração, inclusive durante o processamento.

O retorno `200` contém:

```json
{
  "respostas_salvas": true,
  "reavaliacao": {"status": "ready", "erro": null},
  "lote": {},
  "documento": {}
}
```

`lote` contém o lote completo e `documento` contém o documento detalhado, incluindo
análise, score, cobertura, outcome e `analysis_desatualizada`.

## Falhas, reavaliação e compatibilidade

Se a reavaliação falhar, a confirmação ainda retorna `200` porque os fatos já
foram salvos. `reavaliacao.status` será `failed`, com mensagem segura em `erro`.
O documento fica `failed`, preservando a análise, o score e o outcome anteriores.
`analysis_desatualizada` compara o perfil atual ao contexto da análise salva.

Use `POST /api/v1/documents/{id}/reanalyze/` para tentar novamente, sem reenviar
as respostas. Sucesso retorna `200` com o documento detalhado. O lote mantém o
resultado histórico da reavaliação disparada por sua confirmação; uma tentativa
manual posterior aparece no documento atual e não reescreve esse histórico.

Uma reavaliação bem-sucedida gera o contrato v2, atualiza o snapshot do contexto,
recalcula os indicadores e pode resolver perguntas ou identificar outras lacunas.
Alterar fatos não dispara análises dos demais documentos: seus detalhes indicarão
desatualização quando o contexto atual diferir do snapshot salvo.

| HTTP | Situação |
| --- | --- |
| `400` | Body inválido, pergunta inexistente/repetida, destino não suportado, proposta insuficiente ou autorização inválida. |
| `401` | Autenticação ausente ou inválida. |
| `404` | Documento ou lote inexistente/inacessível, lote de outro documento ou UUID inválido. |
| `409` | Análise antiga, documento indisponível, análise/fatos alterados desde a prévia ou substituição sem autorização. |
| `502` | Falha do provedor ou interpretação inválida na prévia; falha na reavaliação manual. |

Falhas de prévia não alteram o perfil nem o resultado do documento. Falhas de
validação da confirmação fazem rollback de todas as alterações, inclusive do
status temporário. Documentos em `processing` bloqueiam novas análises e
confirmações de outros lotes. Um lote já confirmado pode ser consultado novamente
pelo mesmo POST de confirmação, sem repetir o processamento.
