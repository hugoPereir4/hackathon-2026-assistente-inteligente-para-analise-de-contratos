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
O texto é extraído durante o upload e salvo em `Document.text_content`.
PDFs corrompidos ou protegidos por senha retornam `400`, com erro no campo
`file`. Falhas de extração ou persistência removem o arquivo salvo.
PDFs sem texto são aceitos com `text_content` vazio; não há OCR nesta etapa.
O texto e o download do arquivo ainda não são disponibilizados pelo endpoint
de detalhe.

Para executar os testes pelas rotas normais da aplicação:

```powershell
.\venv\Scripts\python.exe -B manage.py test core --verbosity 2
```
