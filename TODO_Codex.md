# TODO DO PROJETO

## Atualizacao 2026-07-02 - Upload AppMaq

- [ ] Validar no painel administrativo os modelos enviados por API antes de considerar o lote concluido.
- [ ] Configurar compressao de PDF se algum PDF individual retornar `413 Request Entity Too Large`.
- [x] `A800C` foi enviado e confirmado no painel administrativo com 4 PDFs.
- [x] `A800P` foi enviado e confirmado no painel administrativo com 4 PDFs.
- [x] `A800R` foi enviado por API com 6 PDFs e status `200 OK`.
- [x] Lote `VALTRA 3` de `A850` ate `BT210` foi enviado por API.
- [x] `A990` foi reenviado em partes por limite do pacote; cada PDF foi enviado inteiro, sem dividir documento.
- [x] Criado uploader por API/Chrome controlado em `scripts\appmaq-upload-valtra3.mjs`.
- [x] Teste local do uploader em `A800R` confirmou 6 PDFs; depois o upload real foi concluido quando a janela Chrome controlada estava logada.

## Prioridade Alta

- [ ] Confirmar com o usuario o caminho para upload no AppMaq: manual assistido no navegador ou API administrativa. Arquivos provaveis: `CHECKPOINT_Codex.md`, futuro manifest de upload. Risco: alto, pode anexar documentos no modelo errado. Creditos/contexto: baixo se usar inventario local.
- [ ] Preparar manifest de teste para `A800C` com os 4 PDFs da pasta `E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA 3\A800C`. Arquivos provaveis: novo CSV em `Inventario_APPMAQ`. Risco: baixo, desde que nao faça upload automatico. Creditos/contexto: baixo.
- [ ] Validar novamente no AppMaq se `A800C` continua sem manuais antes de qualquer upload. Arquivos provaveis: nenhum, consulta API/navegador. Risco: medio por depender de sessao/rede. Creditos/contexto: baixo.
- [ ] Definir regra juridica/operacional com o usuario para documentos de Scribd e terceiros antes de subir no AppMaq. Arquivos provaveis: `CONFIGURACAO_COLETA_USUARIO.md`. Risco: alto por direitos autorais. Creditos/contexto: baixo.

## Prioridade Media

- [ ] Criar rotina segura de upload em lote somente depois de validar endpoint, autenticacao e campos obrigatorios. Arquivos provaveis: novo script em `scripts\`. Risco: alto. Creditos/contexto: medio.
- [ ] Atualizar inventario com status de upload por modelo quando o fluxo for aprovado. Arquivos provaveis: `Inventario_APPMAQ\Lotes_Usuario\*.csv`. Risco: medio. Creditos/contexto: baixo.
- [ ] Revisar os modelos Valtra 3 e Valtra 4 que possuem apenas genericos para decidir se precisam de nova busca especifica. Arquivos provaveis: status dos lotes em `Inventario_APPMAQ\Lotes_Usuario`. Risco: baixo. Creditos/contexto: medio se pesquisar internet.
- [ ] Melhorar classificacao por tipo de documento no inventario sem criar subpastas nos modelos. Arquivos provaveis: CSVs em `Inventario_APPMAQ\Pesquisa_Cache`. Risco: medio. Creditos/contexto: baixo.

## Prioridade Baixa

- [ ] Limpar ou arquivar temporarios em `tmp\`, `_appmaq_tmp\` e `_downloads_tmp\` somente com autorizacao do usuario. Arquivos provaveis: pastas temporarias. Risco: medio por poder perder rastreabilidade. Creditos/contexto: baixo.
- [ ] Criar um README operacional curto para uso do usuario fora do Codex. Arquivos provaveis: `README.md`. Risco: baixo. Creditos/contexto: baixo.
- [ ] Verificar instalacao do Git no PATH para permitir `git status` e historico. Arquivos provaveis: nenhum. Risco: baixo. Creditos/contexto: baixo.

## Tarefas concluidas

- [x] Testado upload em lote no AppMaq para `A800C` com 4 PDFs. Arquivo de registro: `Inventario_APPMAQ\Lotes_Usuario\upload_appmaq_teste_a800c_2026-07-02.md`. Risco: medio, confirmado na listagem administrativa filtrada.
- [x] Criado protocolo de pesquisa economica. Arquivo: `PROTOCOLO_PESQUISA_ECONOMICA_MANUAIS.md`. Risco: baixo. Creditos/contexto: economiza buscas futuras.
- [x] Criada configuracao consolidada das regras do usuario. Arquivo: `CONFIGURACAO_COLETA_USUARIO.md`. Risco: baixo. Creditos/contexto: economiza releitura de chat.
- [x] Organizado lote `VALTRA 3` com 20 modelos e 103 PDFs finais. Local: `E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA 3`. Risco: baixo, conferido sem arquivos nao-PDF.
- [x] Organizado lote `VALTRA 4` com 17 modelos e 111 PDFs finais. Local: `E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA 4`. Risco: baixo, conferido sem arquivos nao-PDF.
- [x] Biblioteca de 4 genericos Valtra confirmada. Local: `E:\MANUAIS_APPMAQ\_GENERICOS\VALTRA`. Risco: baixo.
- [x] Identificado bloqueio tecnico do upload visual no AppMaq sem alterar dados no site. Arquivo provavel de continuidade: `CHECKPOINT_Codex.md`. Risco: baixo, pois nada foi enviado.
- [x] Criado pacote de continuidade da sessao. Arquivos: `AGENTS.md`, `CHECKPOINT_Codex.md`, `TODO_Codex.md`, `CONTINUIDADE_NOVA_SESSAO.md`. Risco: baixo.
