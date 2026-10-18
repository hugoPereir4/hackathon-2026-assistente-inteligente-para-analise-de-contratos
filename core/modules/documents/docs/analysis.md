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
| `requisitos` | Itens com `id`, `descricao`, `obrigatorio`, `resultado` (`atende`, `parcialmente_atende`, `nao_atende`, `desconhecido`), `depende_papel`, `justificativa`, `evidencia`, `referencias_perfil`. |
| `perguntas_pendentes` | Itens com `id`, `pergunta`, `requisito_ids`, `fato_chave`, `destino`, `fato_rotulo`, `tipo_valor`. |
| `score` / `justificativa_score` | Nota de 0 a 100 atribuída pela IA e a explicação dela. |
| `aderencia` | `score` (cópia da nota da IA), `cobertura`, `total`, `avaliados`, `atendidos`, `parcialmente_atendidos`, `nao_atendidos`, `desconhecidos`; as contagens e a cobertura são calculadas pelo backend. |
| `outcome` | Classificação calculada pelo backend. |
| `metadados` | `analisado_em` (ISO com timezone), `modelo`, `contexto_empresa` (cópia exata do contexto enviado). |

`evidencia` contém `trecho` literal não vazio e `clausula` textual ou nula.
O trecho deve ser contínuo e existir no texto extraído; espaços e quebras de
linha são normalizados na comparação. Resumos, paráfrases e citações que unem
passagens com reticências não são aceitos. Se uma geração falhar nessa validação,
o serviço solicita uma única correção apenas das citações inválidas: a IA escolhe
linhas numeradas, e o backend copia a passagem contínua diretamente do texto
original. O schema restringe os caminhos permitidos e o intervalo de linhas;
o backend também rejeita caminhos extras, duplicados, intervalos invertidos ou
vazios. O resultado completo é validado novamente antes de salvar. Os logs registram os caminhos
dos campos inválidos, sem registrar o conteúdo do contrato.
O trecho precisa existir no texto extraído, com normalização apenas de espaços.
Não há números de página, pois a extração atual não preserva essa informação.
Datas explícitas usam `YYYY-MM-DD`. Prazos relativos mantêm `data: null` quando
o documento não informa uma data explícita; não há cálculo presumido da data.

## Cobertura de requisitos

Quando o texto extraído tem pelo menos 8.000 caracteres e a primeira análise
encontra no máximo quatro requisitos, o backend faz uma segunda chamada focada
em procurar critérios explícitos que ficaram de fora. Ela procura, entre outros,
requisitos jurídicos, fiscais, técnicos, financeiros, certificações, equipe e
condições de execução, preservando evidências literais e evitando repetições.
Os itens adicionais passam pelas mesmas validações de evidência e perfil. Se a
chamada falhar ou a resposta for inválida, a análise original continua. Esse passo
condicional pode aumentar o tempo e o consumo de quota do Gemini em documentos
longos com poucos requisitos iniciais.

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

Conclusões `atende`, `parcialmente_atende` ou `nao_atende` exigem referências existentes, não vazias e
confirmadas, sem origem `ai`. O valor booleano `false` é preservado como dado
explícito. Não confundir um fato ausente com uma negativa.
Quando o requisito depende do papel da empresa, esse papel precisa estar resolvido;
se não estiver, o requisito fica `desconhecido`.
Respostas que violam essas regras são rejeitadas antes da persistência.

Todo requisito desconhecido precisa estar coberto por uma pergunta, exceto os que
só dependem de um papel desconhecido: o papel da empresa não é perguntado ao usuário.
Perguntas só podem referenciar requisitos desconhecidos. `destino` é `company_fact`
ou `cadastro`. Para fatos, `fato_chave` existe mesmo antes de cadastrar o
fato: usa snake_case ASCII com até 100 caracteres, sem colidir com campos de Company,
autenticação ou papel. `fato_rotulo` é um texto não vazio com até 255 caracteres.
`tipo_valor` é `booleano`, `inteiro`, `decimal`, `texto`, `data` ou `objeto`.
Perguntas sobre a mesma chave devem ser agrupadas. Para `cadastro`, a chave é
um campo do contexto cadastral, com rótulo e tipo nulos. Somente `company_fact`
pode ser respondido pelo [fluxo de prévia e confirmação](answers.md).
Os fatos só são gravados depois da confirmação explícita do usuário.

O backend valida estrutura, trechos, referências e confirmação. A interpretação
semântica do requisito, do perfil e da gravidade do risco continua sendo da IA;
o resultado não é uma certificação automática de habilitação.

## Nota e classificação

O score (0 a 100) é atribuído pela IA, que avalia o contexto inteiro do documento:
atendimento dos requisitos (obrigatórios pesam mais que desejáveis), gravidade dos
riscos, multas e garantias, viabilidade dos prazos e compatibilidade do porte, do
ramo e da capacidade da empresa com o objeto e os valores. Faixas de referência
passadas à IA: 80 a 100 compatível; 50 a 79 viável com negociação; 20 a 49 riscos
altos ou lacunas importantes; 0 a 19 incompatível. A explicação fica em
`justificativa_score`. O backend valida apenas que é um inteiro de 0 a 100.

`cobertura = 100 × avaliados / total`, arredondada ao inteiro mais próximo, com meio
ponto para cima; sem requisitos, é `null`. As contagens (`atendidos`,
`parcialmente_atendidos`, `nao_atendidos`, `desconhecidos`) continuam vindo dos
requisitos e não alteram a nota.

Prioridade de classificação:

1. `incompatible`: requisito obrigatório comprovadamente não atendido.
2. `high_risk`: requisito obrigatório parcialmente atendido ou risco alto/crítico.
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
Não há fila nem repetição automática da análise completa. Há no máximo uma
chamada adicional para corrigir evidências inválidas. O endpoint `reanalyze` permite repetir uma
análise existente em estado `ready` ou `failed`; `processing` continua bloqueado.

No serviço Python, uma falha pode ser repetida explicitamente:

```python
analyze_document_with_ai(document, retry_failed=True)
```

Essa opção permite `failed → processing`, mantendo o UPDATE condicional atômico.
Não libera documentos `ready` nem `processing`. No endpoint `analyze`, envie
`{"retry_failed": true}` para repetir explicitamente um documento com falha sem
reenviar o PDF. Sem esse campo, uma falha continua retornando `409`. O frontend
oferece essa opção ao clicar em um documento com estado "Falhou".
Use `reanalyze` quando houver um resultado anterior. Reinicie o shell Django antes
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

### Diagnóstico reproduzível

Conclusões `atende` ou `nao_atende` sem referências confirmadas suficientes, ou
dependentes de um papel ainda desconhecido, são convertidas em `desconhecido`
antes da validação. O backend preserva perguntas existentes ou cria uma pergunta
pendente para o requisito, exceto quando a lacuna é só o papel da empresa. A obrigação escrita no contrato, por si só, não
comprova atendimento. Esses requisitos deixam de contar como avaliados (a nota
continua sendo a da IA). Referências inexistentes ou
duplicadas e citações inválidas continuam sujeitas à validação estrita.
Cada conversão gera um evento `conclusion_reconciled` no diagnóstico, quando
a captura está habilitada, sem nova chamada à IA ou confirmação automática de fatos.

Com `DEBUG=True`, `AI_DIAGNOSTICS_ENABLED` fica habilitado por padrão. Cada análise
grava um JSON em `.diagnostics/analysis/` com ID, horário, versão do serviço (SHA-256),
prompt, modelo, schema, dados enviados, respostas e etapas de validação. Uma falha
de gravação não interrompe a análise. A API devolve o código de suporte na mensagem
de erro para localizar o arquivo. Para desabilitar, use `AI_DIAGNOSTICS_ENABLED=False`.

Os arquivos contêm o contrato e dados do perfil: são locais, ignorados pelo Git e
não são servidos pela API nem por MEDIA_URL. Não incluem chave da API ou headers.
Fora de DEBUG, a captura vem desabilitada por padrão e exige habilitação explícita
com `AI_DIAGNOSTICS_ENABLED=True`.

```powershell
# Executa sem alterar banco ou status (chama o Gemini e consome quota):
.\.venv\Scripts\python.exe manage.py debug_analysis --document 4

# Repete as validações de uma captura, sem rede e sem nova geração:
.\.venv\Scripts\python.exe manage.py debug_analysis --replay .diagnostics/analysis/ID.json

# Testa somente a correção sobre a resposta original capturada (chama o Gemini):
.\.venv\Scripts\python.exe manage.py debug_analysis --repair-from .diagnostics/analysis/ID.json
```

`--replay` verifica os caminhos devolvidos pela correção e reexecuta as validações
capturadas usando o código atual. `--repair-from` usa a primeira resposta capturada
como entrada fixa e gera um novo registro; não substitui a análise no banco.

PDF continua sendo o único formato aceito. OCR, DOCX, chat e respostas sobre o papel
da empresa no documento ficam para etapas futuras. Alterações cadastrais continuam
no endpoint atual de empresa.
