# hackathon-2026-assistente-inteligente-para-analise-de-contratos

## API de documentos

Os endpoints abaixo exigem autenticação JWT e operam somente sobre documentos
da empresa autenticada:

- `POST /api/v1/documents/`: envia um PDF usando `multipart/form-data`, com o
  arquivo no campo `file` e, opcionalmente, `doc_type` (`contract`, `tender` ou
  `proposal`).
- `GET /api/v1/documents/`: lista os documentos da empresa.
- `GET /api/v1/documents/{id}/`: consulta os metadados do documento.
- `DELETE /api/v1/documents/{id}/`: exclui o documento.

O limite inicial de upload é 10 MB, configurado por
`MAX_DOCUMENT_UPLOAD_SIZE`. Os arquivos são armazenados localmente sob
`MEDIA_ROOT`; o caminho de armazenamento não é exposto na resposta da API.
Esta primeira etapa não extrai texto nem disponibiliza download do arquivo.