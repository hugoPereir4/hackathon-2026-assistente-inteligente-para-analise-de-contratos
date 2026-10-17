# Análise contextual de documentos — versão 2

`POST /api/v1/documents/{id}/analyze/` exige autenticação JWT e não precisa de body.
Usa exclusivamente a empresa proprietária do documento, selecionado pelo token.
Um identificador de empresa no body não altera o contexto utilizado.

A resposta `200` é o documento detalhado: `id`, `doc_type`, `filename`, `status`,
`created_at`, `score`, `cobertura`, `outcome`, `analysis_json` e `analysis_desatualizada`.
O campo `file` continua exclusivo do upload e não aparece nas respostas.
O GET de detalhe retorna a mesma estrutura. A listagem omite `analysis_json`.

## Contrato de `analysis_json`

O contrato da saída do modelo está definido em
[`analysis_schema.py`](../service/analysis_schema.py). Todos os campos do schema
são obrigatórios, inclusive os que aceitam `null`; campos extras são rejeitados.
Textos são em português. Listas sem itens são `[]`.

O schema Pydantic é enviado ao Gemini por `response_json_schema`, usando
`DocumentAnalysis.model_json_schema()`. Essa opção preserva o JSON Schema,
incluindo `additionalProperties: false`, sem convertê-lo para o `response_schema`
OpenAPI do provedor. A resposta continua sendo validada localmente pelo Pydantic,
mesmo quando o provedor não aplica alguma restrição do schema.

| Campo | Conteúdo |
| --- | --- |
| `schema_version` | Inteiro `2`, atribuído pelo backend. |
| `resumo` | Texto do resumo executivo. |
| `papel_empresa` | `papel`: `contratante`, `fornecedora` ou `desconhecido`; `justificativa` e `evidencia` (nula apenas quando o papel é desconhecido). |
| `prazos` | Itens com `id`, `descricao`, `data`, `prazo_relativo`, `evento_referencia`, `evidencia`. |
| `valores` | Itens com `descricao`, `categoria`, `moeda`, `montante`, `percentual`, `aproximado`, `evidencia`. Categorias: `valor_total`, `pagamento`, `multa`, `garantia`, `outro`. |
| `obrigacoes` | Itens com `descricao`, `parte_responsavel`, `prazo_id`, `evidencia`. `prazo_id` é nulo ou referencia um item de `prazos`. |
| `riscos` | Itens com `descricao`, `severidade` (`baixa`, `media`, `alta`, `critica`), `impacto`, `recomendacao`, `evidencia`. |
| `requisitos` | Itens com `id`, `descricao`, `obrigatorio`, `resultado` (`atende`, `nao_atende`, `desconhecido`), `depende_papel`, `justificativa`, `evidencia`, `referencias_perfil`. |
| `perguntas_pendentes` | Itens com `id`, `pergunta`, `requisito_ids`, `fato_chave`, `sobre_papel`, `destino`, `fato_rotulo`, `tipo_valor`. |
| `aderencia` | `score`, `cobertura`, `total`, `avaliados`, `atendidos`, `nao_atendidos`, `desconhecidos`, calculados pelo backend. |
| `outcome` | Classificação calculada pelo backend. |
| `metadados` | `analisado_em` (ISO com timezone), `modelo`, `contexto_empresa` (cópia exata do contexto enviado). |

`evidencia` contém `trecho` literal não vazio e `clausula` textual ou nula.
O trecho precisa existir no texto extraído, com normalização apenas de espaços.
Não há números de página, pois a extração atual não preserva essa informação.
Datas explícitas usam `YYYY-MM-DD`. Prazos relativos mantêm `data: null` quando
o documento não informa uma data explícita; não há cálculo presumido da data.

`montante` e `percentual` são strings decimais (por exemplo, `"123456789.90"`
e `"10.00"`), ou `null`. Não passam por float. Aproximações são indicadas por
`aproximado`; condições e fórmulas permanecem na descrição e no trecho original.

## Contexto e confirmação

O contexto é um mapa com referências `cadastro.legal_name`, `cadastro.cnpj`,
`cadastro.cnae_primary`, `cadastro.company_size`, `cadastro.founded_on`,
`cadastro.address_city`, `cadastro.address_state` e `fatos.<fact_key>`.
Cada entrada tem `chave`, `valor`, `origem`, `confirmado`; fatos têm também `rotulo`.
Os campos cadastrais usam origem `cadastro` e a confirmação global da empresa.
Fatos preservam a origem (`user`, `cnpj_api`, `ai`) e sua confirmação individual.

Conclusões `atende` ou `nao_atende` exigem referências existentes, não vazias e
confirmadas, sem origem `ai`. O valor booleano `false` é preservado como dado
explícito. Não confundir um fato ausente com uma negativa.
Quando o requisito depende do papel da empresa, esse papel precisa estar resolvido.
Respostas que violam essas regras são rejeitadas antes da persistência.

Todo requisito desconhecido precisa estar coberto por uma pergunta. Perguntas
só podem referenciar requisitos desconhecidos. `destino` distingue `company_fact`,
`cadastro` e `papel`. Para fatos, `fato_chave` existe mesmo antes de cadastrar o
fato: usa snake_case ASCII com até 100 caracteres, sem colidir com campos de Company,
autenticação ou papel. `fato_rotulo` é um texto não vazio com até 255 caracteres.
`tipo_valor` é `booleano`, `inteiro`, `decimal`, `texto`, `data` ou `objeto`.
Perguntas sobre a mesma chave devem ser agrupadas. Papel desconhecido exige uma pergunta
`sobre_papel: true`, que pode também cobrir requisitos dependentes desse papel.
Para destino `papel`, chave, rótulo e tipo são nulos. Para `cadastro`, a chave é
um campo do contexto cadastral, com rótulo e tipo nulos. Somente `company_fact`
pode ser respondido pelo [fluxo de prévia e confirmação](answers.md).
Os fatos só são gravados depois da confirmação explícita do usuário.

O backend valida estrutura, trechos, referências e confirmação. A interpretação
semântica do requisito, do perfil e da gravidade do risco continua sendo da IA;
o resultado não é uma certificação automática de habilitação.

## Nota e classificação

Todos os requisitos têm peso igual, incluindo os opcionais.
`score = 100 × atendidos / avaliados`; `cobertura = 100 × avaliados / total`.
Percentuais são arredondados ao inteiro mais próximo, com meio ponto para cima.
Requisitos desconhecidos não entram na nota. Sem avaliados, score é `null`;
sem requisitos, cobertura também é `null`.

Exemplo: um requisito atendido, um não atendido e um desconhecido resultam em
score `50`, cobertura `67`, total `3` e avaliados `2`.

Prioridade de classificação:

1. `incompatible`: requisito obrigatório comprovadamente não atendido.
2. `high_risk`: risco alto ou crítico.
3. `insufficient_data`: requisito desconhecido, papel desconhecido ou nenhum requisito avaliável.
4. `good_fit`: demais casos; um requisito opcional não atendido reduz a nota sem impor incompatibilidade.

`Document.score` e `Document.outcome` são salvos junto com o JSON e espelham seus
indicadores. Resultados anteriores à versão 1 permanecem legíveis, sem adaptação
automática; podem não ter `schema_version` nem `cobertura`. Resultados v1 também
permanecem legíveis. Para responder perguntas antigas, reavalie pelo endpoint
`reanalyze` e use as novas perguntas v2.

## Estados e erros

A análise é síncrona: `uploaded → processing → ready`.
O primeiro pedido adquire o documento com UPDATE condicional atômico.
Outro pedido para o mesmo documento não chama o provedor e recebe `409`.
Não há fila nem retry automático. O endpoint `reanalyze` permite repetir uma
análise existente em estado `ready` ou `failed`; `processing` continua bloqueado.

No serviço Python, uma falha pode ser repetida explicitamente:

```python
analyze_document_with_ai(document, retry_failed=True)
```

Essa opção permite `failed → processing`, mantendo o UPDATE condicional atômico.
Não libera documentos `ready` nem `processing`. O endpoint `analyze` continua sem
retry: para um documento com falha, retorna `409`. Use `reanalyze` quando houver
um resultado anterior. Reinicie o shell Django antes
de importar a nova versão da função. A análise real envia o contexto e o texto ao
Gemini; uma nova tentativa pode consumir a quota do projeto.

| HTTP | Situação |
| --- | --- |
| `400` | Texto vazio ou chave da API não configurada. |
| `401` | Autenticação ausente ou inválida. |
| `404` | Documento inexistente ou pertencente a outra empresa. |
| `409` | Documento em processamento, pronto ou com falha. |
| `502` | Timeout, erro do SDK, resposta vazia, JSON inválido ou evidência/referência inválida. |

Falhas após adquirir o documento levam a `failed`, sem salvar resultado parcial.
Reavaliações preservam o resultado anterior em caso de falha. O campo
`analysis_desatualizada` compara o contexto salvo com o perfil atual; é `false`
quando ainda não existe análise e `true` para análises antigas sem contexto.
Erros retornam `{"error": "mensagem"}` e não expõem detalhes do provedor.
As mensagens distinguem HTTP 400 (solicitação/schema), 401/403 (autenticação ou
permissão), 404 (modelo), 429 (quota), timeout e falha de conexão. A causa original
continua encadeada para diagnóstico no shell. O banco não armazena o histórico
dos erros anteriores; `failed` sozinho não permite recuperar sua causa.
Credenciais nunca aparecem no contexto ou nos metadados.

PDF continua sendo o único formato aceito. OCR, DOCX, chat e respostas sobre o papel
da empresa no documento ficam para etapas futuras. Alterações cadastrais continuam
no endpoint atual de empresa.
