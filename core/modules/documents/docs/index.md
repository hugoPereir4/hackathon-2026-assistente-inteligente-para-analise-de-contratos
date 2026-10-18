# Documents

Documentos (PDFs) da empresa logada e a análise feita pela IA. Cada empresa só enxerga os próprios documentos: o id de um documento de outra empresa responde `404`.

Base URL: `/api/v1/documents/`

Todas as rotas exigem o header:

```
Authorization: Bearer <access>
```

Veja como obter o token em [auth/docs/index.md](../../auth/docs/index.md).

| Método | Rota                                                  | Descrição |
| ------ | ----------------------------------------------------- | --------- |
| GET    | `/api/v1/documents/`                                  | Lista os documentos (paginado) |
| POST   | `/api/v1/documents/`                                  | Envia um PDF |
| GET    | `/api/v1/documents/{id}/`                             | Detalhe do documento, com a análise |
| DELETE | `/api/v1/documents/{id}/`                             | Exclui o documento e o arquivo |
| POST   | `/api/v1/documents/{id}/analyze/`                     | Primeira análise pela IA |
| POST   | `/api/v1/documents/{id}/reanalyze/`                   | Refaz a análise |
| POST   | `/api/v1/documents/{id}/answers/preview/`             | Envia respostas às perguntas da IA e recebe a interpretação |
| POST   | `/api/v1/documents/{id}/answers/{batch_id}/confirm/`  | Confirma as respostas e reanalisa |

> `PUT` e `PATCH` não são aceitos (respondem `405`). Para trocar o arquivo, exclua e envie de novo.

### Fluxo típico na tela

1. `POST /documents/` com o PDF. O documento nasce com `status: "uploaded"`.
2. `POST /documents/{id}/analyze/`. A chamada é síncrona e pode levar alguns segundos: mostre um loading e não deixe o usuário clicar de novo.
3. Exiba `analysis_json`. Se `analysis_json.perguntas_pendentes` tiver itens, mostre as perguntas ao usuário.
4. `POST /answers/preview/` com as respostas, e mostre as propostas para o usuário revisar.
5. `POST /answers/{batch_id}/confirm/` com as propostas aprovadas. A resposta já traz o documento reanalisado.

---

## Objeto `Document`

| Campo                    | Tipo              | Na listagem | Observação |
| ------------------------ | ----------------- | ----------- | ---------- |
| `id`                     | number            | Sim | |
| `doc_type`               | string \| null    | Sim | `"contract"`, `"tender"` (edital) ou `"proposal"`. Opcional no upload. |
| `filename`               | string            | Sim | Nome original do arquivo enviado. |
| `status`                 | string            | Sim | `"uploaded"`, `"processing"`, `"ready"` ou `"failed"`. |
| `score`                  | number \| null    | Sim | 0 a 100, atribuído pela IA a partir do contexto do documento. `null` até ser analisado. |
| `cobertura`              | number \| null    | Sim | 0 a 100: percentual dos requisitos que a IA conseguiu avaliar. |
| `outcome`                | string \| null    | Sim | Ver [valores de `outcome`](#valores-de-outcome). |
| `created_at`             | string (ISO 8601) | Sim | |
| `analysis_json`          | object \| null    | Não | Resultado completo da análise. `null` antes da primeira análise. |
| `analysis_desatualizada` | boolean           | Não | `true` quando os dados da empresa mudaram depois da análise. Sugira reanalisar. |

O campo `file` só existe no upload e nunca volta nas respostas.

```json
{
  "id": 7,
  "doc_type": "tender",
  "filename": "edital-pregao-12-2026.pdf",
  "status": "ready",
  "created_at": "2026-10-17T14:32:10.123456-03:00",
  "score": 50,
  "outcome": "insufficient_data",
  "cobertura": 67,
  "analysis_json": { "schema_version": 2, "resumo": "...", "...": "..." },
  "analysis_desatualizada": false
}
```

### Valores de `status`

| Valor        | Significado | O que o front pode fazer |
| ------------ | ----------- | ------------------------ |
| `uploaded`   | Enviado, ainda sem análise. | `analyze` |
| `processing` | Análise em andamento. | Esperar. Qualquer outra análise responde `409`. |
| `ready`      | Análise concluída. | Exibir; `reanalyze`; responder perguntas. |
| `failed`     | A última análise falhou. Se já existia uma análise antes, ela continua em `analysis_json`. | `reanalyze` (se houver análise anterior) ou excluir e enviar de novo. |

### Valores de `outcome`

| Valor               | Significado |
| ------------------- | ----------- |
| `good_fit`          | A empresa atende ao documento. |
| `high_risk`         | Existe risco alto/crítico ou requisito obrigatório parcialmente atendido. |
| `incompatible`      | Algum requisito obrigatório não é atendido. |
| `insufficient_data` | Faltam dados da empresa para concluir. Há perguntas em `perguntas_pendentes`. |

---

## Objeto `analysis_json`

Resumo do que interessa para a tela. O contrato completo e as regras de validação estão em [analysis.md](analysis.md).

| Campo                 | Conteúdo |
| --------------------- | -------- |
| `schema_version`      | `2`. Análises antigas podem não ter este campo: use `reanalyze` para atualizá-las. |
| `resumo`              | Texto do resumo executivo. |
| `papel_empresa`       | `{ papel, justificativa, evidencia }`. `papel`: `"contratante"`, `"fornecedora"` ou `"desconhecido"`. |
| `prazos`              | Lista de `{ id, descricao, data, prazo_relativo, evento_referencia, evidencia }`. `data` é `YYYY-MM-DD` ou `null`. |
| `valores`             | Lista de `{ descricao, categoria, moeda, montante, percentual, aproximado, evidencia }`. `montante` e `percentual` são **strings** decimais (`"123456.90"`). |
| `obrigacoes`          | Lista de `{ descricao, parte_responsavel, prazo_id, evidencia }`. |
| `riscos`              | Lista de `{ descricao, severidade, impacto, recomendacao, evidencia }`. `severidade`: `"baixa"`, `"media"`, `"alta"` ou `"critica"`. |
| `requisitos`          | Lista de `{ id, descricao, obrigatorio, resultado, depende_papel, justificativa, evidencia, referencias_perfil }`. `resultado`: `"atende"`, `"parcialmente_atende"`, `"nao_atende"` ou `"desconhecido"`. |
| `perguntas_pendentes` | Perguntas para o usuário. Ver [Respondendo perguntas](#respondendo-perguntas). |
| `aderencia`           | `{ score, cobertura, total, avaliados, atendidos, parcialmente_atendidos, nao_atendidos, desconhecidos }`. |
| `outcome`             | O mesmo valor de `Document.outcome`. |
| `metadados`           | `{ analisado_em, modelo, contexto_empresa }`. |

`evidencia` é `{ trecho, clausula }`: `trecho` é o texto literal do PDF e `clausula` é o nome da cláusula ou `null`. Use o `trecho` para destacar de onde veio a informação. Listas sem itens vêm como `[]`, nunca `null`.

---

## GET `/api/v1/documents/`

Lista os documentos da empresa, do mais recente para o mais antigo. A listagem não traz `analysis_json` nem `analysis_desatualizada`: para isso, use o detalhe.

Paginação de 10 itens por página. Use `?page=2` para as próximas.

### Resposta `200 OK`

```json
{
  "count": 23,
  "next": "http://localhost:8000/api/v1/documents/?page=2",
  "previous": null,
  "results": [
    {
      "id": 7,
      "doc_type": "tender",
      "filename": "edital-pregao-12-2026.pdf",
      "status": "ready",
      "created_at": "2026-10-17T14:32:10.123456-03:00",
      "score": 50,
      "outcome": "insufficient_data",
      "cobertura": 67
    }
  ]
}
```

Uma página além da última responde `404`.

---

## POST `/api/v1/documents/`

Envia um PDF. O body é `multipart/form-data`, não JSON.

| Campo      | Obrigatório | Observação |
| ---------- | ----------- | ---------- |
| `file`     | Sim | Somente PDF, até 10 MB, sem senha. |
| `doc_type` | Não | `"contract"`, `"tender"` ou `"proposal"`. |

```js
const form = new FormData();
form.append("file", arquivo);          // File vindo do <input type="file">
form.append("doc_type", "tender");

await fetch("/api/v1/documents/", {
  method: "POST",
  headers: { Authorization: `Bearer ${access}` }, // não defina Content-Type: o navegador põe o boundary
  body: form,
});
```

O upload só salva e extrai o texto. A análise **não** começa sozinha: chame `analyze` em seguida.

### Resposta `201 Created`

O objeto `Document` no formato da listagem, com `status: "uploaded"` e `score`, `outcome` e `cobertura` em `null`.

### Erros `400 Bad Request`

```json
{ "file": ["Envie um arquivo PDF."] }
```

Outras mensagens possíveis em `file`:

- `"O arquivo excede o limite de 10 MB."`
- `"O conteúdo enviado não é um PDF válido."` (extensão `.pdf`, mas o conteúdo não é PDF)
- `"Envie um PDF sem proteção por senha."`
- `"Não foi possível ler o PDF. O arquivo pode estar corrompido."`
- `"Nenhum arquivo foi submetido."`

E em `doc_type`: `"\"xyz\" não é um escolha válido."`

> PDFs escaneados (só imagem) são aceitos no upload, mas não têm texto. A análise deles responde `400`. Por enquanto não há OCR.

---

## GET `/api/v1/documents/{id}/`

### Resposta `200 OK`

O objeto `Document` completo, com `analysis_json` e `analysis_desatualizada`.

Se o usuário saiu da tela durante uma análise, use esta rota para ver o `status` atual.

---

## DELETE `/api/v1/documents/{id}/`

Exclui o documento, o PDF e os lotes de respostas dele. Não há como desfazer. Os dados da empresa (fatos) já confirmados a partir deste documento **não** são apagados.

### Resposta `200 OK`

```json
{ "message": "Registro deletado com sucesso!" }
```

---

## POST `/api/v1/documents/{id}/analyze/`

Primeira análise do documento. Sem body. Só funciona com `status: "uploaded"`.

A IA usa os dados da empresa logada (cadastro e fatos confirmados) para dizer se ela atende aos requisitos. Quanto mais completo o cadastro, menos perguntas pendentes.

### Resposta `200 OK`

O objeto `Document` completo, já com `status: "ready"`.

### Erros

| Status | Quando |
| ------ | ------ |
| `400`  | O PDF não tem texto (ex.: escaneado), ou a IA não está configurada no servidor. |
| `409`  | O documento não está `uploaded`: já está em análise, já foi analisado ou falhou. Use `reanalyze`. |
| `502`  | A IA falhou, demorou demais ou devolveu algo inválido. |

Em qualquer erro depois que a análise começa (`400` por falta de texto ou `502`), o documento fica `failed`. Como ainda não tem `analysis_json`, ele não pode ser reanalisado: a saída é excluir e enviar o PDF de novo.

Corpo dos erros: `{ "error": "mensagem" }`. A mensagem pode ser exibida ao usuário.

---

## POST `/api/v1/documents/{id}/reanalyze/`

Refaz a análise de um documento que já tem `analysis_json`. Sem body. Aceita `status` `"ready"` ou `"failed"`.

Use quando:

- `analysis_desatualizada` for `true` (a empresa mudou dados depois da análise);
- a reavaliação depois de confirmar respostas falhou;
- a análise é antiga (sem `schema_version: 2`) e o usuário quer responder às perguntas.

Se a reanálise falhar, a análise anterior continua em `analysis_json` e o documento fica `failed`.

### Resposta `200 OK`

O objeto `Document` completo.

### Erros

| Status | Quando |
| ------ | ------ |
| `400`  | O documento nunca foi analisado (use `analyze`). |
| `409`  | O documento está em `processing`. |
| `502`  | Falha da IA. |

---

## Respondendo perguntas

Quando a IA não tem dados para avaliar um requisito, ela gera perguntas em `analysis_json.perguntas_pendentes`. O fluxo tem duas etapas: a **prévia** mostra como a IA interpretou cada resposta, e a **confirmação** grava os dados na empresa e reanalisa. Os detalhes estão em [answers.md](answers.md).

Requer `schema_version: 2` e `status: "ready"`.

### Objeto de pergunta

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

| Campo          | Uso no front |
| -------------- | ------------ |
| `id`           | Enviado de volta em `pergunta_id`. |
| `pergunta`     | Texto para exibir. |
| `destino`      | Só `"company_fact"` pode ser respondido aqui. `"cadastro"` deve levar o usuário a editar a empresa ([company/docs/index.md](../../company/docs/index.md)). O papel da empresa nunca é perguntado. |
| `tipo_valor`   | Dica para o campo de entrada: `booleano`, `inteiro`, `decimal`, `texto`, `data` ou `objeto`. A resposta é sempre enviada como texto livre. |

---

## POST `/api/v1/documents/{id}/answers/preview/`

Envia as respostas em texto livre. A IA interpreta cada uma, mas **nada é gravado** na empresa ainda.

### Body

```json
{
  "respostas": [
    { "pergunta_id": "q1", "texto": "Sim, temos ISO 9001." }
  ]
}
```

- De 1 a 100 respostas, sem `pergunta_id` repetido.
- `texto` com até 10.000 caracteres.
- Pode responder só parte das perguntas.

### Resposta `201 Created`

O lote criado. Guarde o `id` para a confirmação e mostre `proposals` para o usuário revisar.

```json
{
  "id": "3f2b8c1e-6d4a-4f7e-9b21-0c5e8a7d9f10",
  "document": 7,
  "status": "pending",
  "original_answers": [{ "pergunta_id": "q1", "texto": "Sim, temos ISO 9001." }],
  "proposals": [
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
  ],
  "analysis_fingerprint": "…",
  "approved_proposals": [],
  "overwrite_authorizations": [],
  "created_at": "2026-10-17T14:40:02.000000-03:00",
  "confirmed_at": null,
  "reanalysis_status": null,
  "reanalysis_error": ""
}
```

Como exibir cada proposta:

- `suficiente: false`: a resposta foi vaga ("não sei", "estamos vendo"). Mostre `esclarecimento` e peça uma nova resposta, que gera **outra** prévia. Essa proposta não pode ser aprovada.
- `valor_anterior` preenchido: a empresa já tinha esse dado (`{ valor, confirmado, origem, rotulo }`). Mostre o antes e o depois.
- `exige_autorizacao_substituicao: true`: o valor novo substitui um dado já confirmado. Peça uma confirmação explícita ao usuário.

---

## POST `/api/v1/documents/{id}/answers/{batch_id}/confirm/`

Grava as propostas aprovadas como dados confirmados da empresa e reanalisa o documento. A chamada é síncrona e chama a IA: mostre loading.

### Body

```json
{
  "propostas_aprovadas": ["q1"],
  "autorizar_substituicao": []
}
```

- `propostas_aprovadas`: ids de `proposals` que o usuário aprovou (pelo menos um).
- `autorizar_substituicao`: ids das propostas com `exige_autorizacao_substituicao: true`. Se faltar algum, nada é gravado e a resposta é `409`.
- Os valores gravados são os da prévia. Não dá para editar o valor aqui: para corrigir, gere outra prévia.

Um lote só pode ser confirmado uma vez. Repetir a chamada devolve o mesmo resultado, sem gravar de novo.

### Resposta `200 OK`

```json
{
  "respostas_salvas": true,
  "reavaliacao": { "status": "ready", "erro": null },
  "lote": { "...": "o lote, agora com status \"confirmed\"" },
  "documento": { "...": "o objeto Document completo, já reanalisado" }
}
```

Se `reavaliacao.status` vier `"failed"`, as respostas **foram salvas**, mas a reanálise falhou: mostre `reavaliacao.erro` e ofereça `reanalyze`. Não reenvie as respostas.

### Erros (prévia e confirmação)

| Status | Quando |
| ------ | ------ |
| `400`  | Body inválido, pergunta inexistente ou repetida, pergunta com `destino` diferente de `company_fact`, proposta insuficiente aprovada. |
| `404`  | Documento ou lote inexistente, ou lote de outro documento. |
| `409`  | Análise antiga (use `reanalyze`), documento em `processing`, análise ou dados da empresa mudaram desde a prévia (gere outra prévia), ou substituição sem autorização. |
| `502`  | Falha da IA ao interpretar as respostas (só na prévia). |

Os erros de fluxo vêm como `{ "error": "mensagem" }`. Os de validação do body vêm por campo, ex.: `{ "respostas": ["Este campo é obrigatório."] }`.

---

## Erros comuns a todas as rotas

| Status | Quando |
| ------ | ------ |
| `401`  | Header `Authorization` ausente, ou `access` inválido/expirado. Tente `/auth/refresh/`. |
| `404`  | Documento inexistente ou de outra empresa. |
| `405`  | Método não suportado (ex.: `PUT`, `PATCH`). |
| `429`  | Limite de 50 req/min por usuário excedido. |
