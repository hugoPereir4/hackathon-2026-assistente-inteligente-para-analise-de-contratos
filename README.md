# hackathon-2026-assistente-inteligente-para-analise-de-contratos

## API de documentos

Os endpoints abaixo exigem autenticação JWT e operam somente sobre documentos
da empresa autenticada:

- `POST /api/v1/documents/`: envia um PDF usando `multipart/form-data`, com o
  arquivo no campo `file` e, opcionalmente, `doc_type` (`contract`, `tender` ou
  `proposal`).
- `GET /api/v1/documents/`: lista os documentos da empresa.
- `GET /api/v1/documents/{id}/`: consulta os metadados do documento.
- `POST /api/v1/documents/{id}/analyze/`: analisa o texto com o contexto da empresa
  e retorna o documento com o resultado completo, de forma síncrona.
- `DELETE /api/v1/documents/{id}/`: exclui o documento.

O limite inicial de upload é 10 MB, configurado por
`MAX_DOCUMENT_UPLOAD_SIZE`. Os arquivos são armazenados localmente sob
`MEDIA_ROOT`; o caminho de armazenamento não é exposto na resposta da API.
O upload extrai o texto do PDF; PDFs digitalizados precisam de OCR, que não faz
parte desta etapa. O arquivo não tem endpoint de download.

## Análise com IA

Instale `requirements.txt` e configure `GOOGLE_AI_API_KEY` no `.env`.
`GOOGLE_AI_MODEL` permite selecionar o modelo, mantendo como padrão
`gemini-3.5-flash-lite`. O acesso ao modelo e suas respostas reais não são
validados pelos testes com mocks.

A análise utiliza os dados de `Company` e os fatos de `CompanyFact` pertencentes
à empresa do documento. Apenas dados confirmados podem sustentar comparações;
fatos de origem IA não comprovam capacidades. Não são enviados e-mail, senha
nem dados de autenticação.

A listagem retorna `score`, `cobertura` e `outcome`; o detalhe e o POST de análise
retornam também `analysis_json`. Sempre mostre score junto à cobertura: uma nota
100 com cobertura 20% ainda é parcial. Todos esses campos são somente leitura.

Veja o [contrato de análise e os erros da API](core/modules/documents/docs/analysis.md).

## Testes

```powershell
.\.venv\Scripts\python.exe manage.py test core
.\.venv\Scripts\python.exe manage.py makemigrations --check --dry-run
```

Os testes de análise simulam o Gemini, sem consumir a API real.
