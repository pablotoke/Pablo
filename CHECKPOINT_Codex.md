# CHECKPOINT DO PROJETO

Data do checkpoint: 2026-07-02.

## 1. Objetivo geral do projeto

O projeto tem como objetivo apoiar a coleta em escala de documentacao tecnica de maquinas agricolas para uso no AppMaq. O fluxo precisa identificar modelos cadastrados ou solicitados, pesquisar manuais e documentos tecnicos na internet, validar se o documento corresponde ao modelo correto, baixar apenas materiais uteis e organizar os PDFs em pastas padronizadas para posterior cadastro no painel administrativo do AppMaq.

O foco atual esta em tratores agricolas Valtra.

## 2. Resultado atual

Atualizacao de upload em 2026-07-02:

- `A800C` foi enviado ao AppMaq e confirmado na listagem administrativa com 4 PDFs.
- `A800P` foi enviado ao AppMaq e confirmado na listagem administrativa com 4 PDFs.
- Foi criado o script `scripts\appmaq-upload-valtra3.mjs` para abrir um Chrome controlado, usar a sessao admin do AppMaq e enviar PDFs por API para `/vehicles/manuals/batch`.
- O teste local em `A800R` confirmou 6 PDFs na pasta do modelo.
- O teste real em `A800R` nao enviou arquivos porque a janela Chrome controlada nao estava logada e o cookie `user_app_maq` nao foi encontrado. Sem sessao valida, o script encerra sem upload.
- Proximo passo pratico: abrir o script, fazer login no Chrome controlado e rodar primeiro `--model=A800R`; depois confirmar no painel e executar o restante do lote.

Ja existe uma estrutura local de trabalho com scripts PowerShell, inventarios CSV/JSON/MD e regras operacionais documentadas.

Os lotes Valtra 3 e Valtra 4 foram montados no HD `E:` com os PDFs diretamente dentro das pastas dos modelos, sem subpastas internas e sem arquivos auxiliares dentro das pastas de modelos.

Resultado confirmado em 2026-07-02:

- `E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA 3`: 20 pastas de modelos, 103 PDFs, 0 arquivos nao-PDF.
- `E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA 4`: 17 pastas de modelos, 111 PDFs, 0 arquivos nao-PDF.
- `E:\MANUAIS_APPMAQ\_GENERICOS\VALTRA`: 4 PDFs genericos aprovados.
- `E:\MANUAIS_APPMAQ\_INVENTARIO`: inventarios copiados para consulta externa.

O usuario aprovou o padrao de organizacao: abrir a pasta do modelo e ver os PDFs diretamente nela.

## 3. Estado atual do sistema

O projeto esta em uma etapa de continuidade e preservacao de contexto. A coleta dos lotes Valtra 3 e Valtra 4 foi feita e registrada.

Foi iniciado um teste para automatizar upload no painel administrativo do AppMaq usando o modelo `A800C`, mas nenhum upload foi concluido. O teste visual pelo navegador admin ficou bloqueado porque o drawer de upload em lote do AppMaq aparecia deslocado/fora da area clicavel no navegador interno, e a ferramenta disponivel nao ofereceu uma forma confiavel de preencher o input de arquivo.

IDs ja localizados para o teste A800C:

- Tipo `Trator Agricola`: `019570fc-0046-7a7e-9537-5270ed100c7e`
- Marca `VALTRA`: `019570fb-3277-7051-b46d-e3f1b3f31d86`
- Modelo `A800C`: `0198b382-f928-739e-8917-739606cfc27c`

Consulta publica do modelo A800C retornou lista vazia, ou seja, sem manuais publicos confirmados no momento do teste:

- `https://api.appmaq.com.br/vehicles/public/manuals/models/0198b382-f928-739e-8917-739606cfc27c`

Endpoint administrativo provavel identificado no codigo do AppMaq, mas ainda nao usado com sucesso:

- `POST https://api.appmaq.com.br/vehicles/manuals/batch`

Campos esperados do `FormData`, conforme inferido do chunk do site:

- `vehicleTypeId`
- `vehicleBrandId`
- `vehicleModelId`
- `files`
- `names`
- `descriptions`

Essa inferencia deve ser tratada com cuidado porque ainda nao foi validada por um upload real.

Atualizacao em 2026-07-02:

O primeiro teste pratico de upload pelo painel administrativo foi executado com sucesso para o modelo `A800C`.

- Tipo: `Trator Agricola`
- Marca: `VALTRA`
- Modelo: `A800C`
- Quantidade: 4 manuais
- Metodo: painel AppMaq, botao `Add em Lote`
- Parte manual: usuario selecionou os 4 PDFs no seletor do Windows.
- Parte automatizada: Codex preencheu tipo, marca, modelo e clicou em `Criar 4 Manuais`.
- Confirmacao: listagem administrativa filtrada por `A800C` retornou 4 linhas.
- Registro: `Inventario_APPMAQ\Lotes_Usuario\upload_appmaq_teste_a800c_2026-07-02.md`
- Observacao: a consulta publica do modelo ainda retornou `[]` logo apos o upload; usar a listagem administrativa como confirmacao principal desse teste.

## 4. Estrutura de pastas e arquivos

Raiz do projeto:

- `CONFIGURACAO_COLETA_USUARIO.md`
- `PROTOCOLO_PESQUISA_ECONOMICA_MANUAIS.md`
- `AGENTS.md`
- `CHECKPOINT_Codex.md`
- `TODO_Codex.md`
- `CONTINUIDADE_NOVA_SESSAO.md`
- `scripts\`
- `Inventario_APPMAQ\`
- `tmp\`
- `_appmaq_tmp\`
- `_downloads_tmp\`
- `.git\`
- `.agents\`

Pastas externas importantes:

- `E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA 3`
- `E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA 4`
- `E:\MANUAIS_APPMAQ\_GENERICOS\VALTRA`
- `E:\MANUAIS_APPMAQ\_INVENTARIO`

## 5. Funcao de cada arquivo relevante

- `CONFIGURACAO_COLETA_USUARIO.md`: regras especificas definidas pelo usuario para organizacao, lotes Valtra, nomes de PDFs, uso de genericos e modelos novos nao solicitados.
- `PROTOCOLO_PESQUISA_ECONOMICA_MANUAIS.md`: protocolo economico de busca, validacao, fontes e criterios para evitar retrabalho e gasto desnecessario.
- `scripts\collect-appmaq-tractor-inventory.ps1`: coleta inventario publico/admin de tratores e manuais do AppMaq.
- `scripts\compare-requested-tractors.ps1`: compara lista solicitada com dados encontrados/cadastrados.
- `scripts\compare-admin-tractor-manual-coverage.ps1`: compara cobertura de manuais por modelo no AppMaq.
- `scripts\build-manual-collection-queue.ps1`: gera fila de coleta de documentos.
- `scripts\initialize-research-cache.ps1`: cria/organiza arquivos de cache de pesquisa.
- `scripts\select-next-research-batch.ps1`: seleciona proximo lote pequeno de pesquisa.
- `scripts\prepare-manual-folders.ps1`: prepara estrutura de pastas para manuais.
- `scripts\cleanup-empty-manual-folders.ps1`: limpa pastas vazias quando autorizado/adequado.
- `scripts\inventory-user-docs-zip.ps1`: inventaria ZIP enviado pelo usuario.
- `scripts\import-user-docs-zip-to-manuals.ps1`: importa documentos do ZIP do usuario para estrutura de manuais.
- `scripts\apply-valtra-generic-docs.ps1`: copia documentos genericos Valtra para modelos.
- `scripts\finaliza-valtra4.ps1`: finaliza organizacao do lote Valtra 4 com documentos oficiais/genericos.
- `scripts\search-valtra4-expanded.ps1`: pesquisa ampliada para Valtra 4 em fontes planejadas.
- `scripts\bing-search-valtra4-expanded.ps1`: pesquisa de candidatos via Bing para Valtra 4.
- `scripts\aplica-valtra4-tcvt-scribd.ps1`: aplica documentos Scribd validados para modelos Valtra T CVT.
- `Inventario_APPMAQ\Pesquisa_Cache\*.csv/json`: cache central de candidatos, validacoes, downloads, rejeicoes, lotes e manifesto.
- `Inventario_APPMAQ\Lotes_Usuario\*.csv/md`: relatorios dos lotes Valtra e documentos adicionados.
- `Inventario_APPMAQ\Arquivos_Usuario\*.csv/json/md`: inventarios de arquivos enviados pelo usuario.
- `Inventario_APPMAQ\appmaq_admin_*.csv/json`: dados do AppMaq admin exportados/coletados anteriormente.
- `Inventario_APPMAQ\comparativo_lista_solicitada_vs_appmaq.*`: comparacao entre lista solicitada e cadastro AppMaq.
- `Inventario_APPMAQ\fila_coleta_documentos_tratores.*`: fila de coleta de documentos.
- `tmp\`: arquivos temporarios de busca, HTML e PDFs intermediarios.
- `_appmaq_tmp\`: HTML/chunks do AppMaq usados para inspecionar endpoints. Pode conter codigo publico do frontend; nao deve conter tokens.
- `_downloads_tmp\`: area temporaria de downloads.

Nao foi encontrado arquivo `.env` na varredura local deste checkpoint.

## 6. Fluxo atual do sistema

Fluxo operacional atual:

1. O usuario informa marca, tipo e modelos desejados.
2. O Codex consulta as configuracoes locais e os caches para evitar repetir pesquisa.
3. O lote e mantido pequeno para economizar creditos e contexto.
4. Primeiro sao coletados candidatos provaveis em fontes como Scribd, Manualslib, sites oficiais, JSAgro e busca web.
5. Nem todos os links sao abertos; somente os candidatos melhores sao validados.
6. A validacao deve conferir conteudo interno sempre que possivel: modelo, familia, tipo do documento, idioma e utilidade.
7. Documentos aprovados sao baixados por link/botao oficial da fonte.
8. PDFs sao renomeados em maiusculas com nome descritivo.
9. Os PDFs sao copiados diretamente para a pasta do modelo, sem subpastas.
10. Candidatos, rejeicoes, validacoes e downloads ficam registrados no inventario/cache, fora das pastas dos modelos.
11. Ao final, o lote e conferido para garantir que as pastas dos modelos tenham somente PDFs.

## 7. Dependencias e bibliotecas

Dependencias confirmadas/usadas:

- Windows PowerShell.
- Scripts `.ps1`.
- Python do runtime do Codex para leitura/validacao de PDFs quando necessario.
- Biblioteca Python `pypdf` foi usada em comandos de validacao.
- Navegador interno do Codex para acesso visual ao AppMaq e Scribd.
- Acesso a internet quando autorizado.

Instalacao exata de dependencias: nao confirmado. O projeto nao possui `requirements.txt` identificado na varredura.

## 8. Variaveis de ambiente necessarias

Nenhum arquivo `.env` foi encontrado neste checkpoint.

Variaveis possiveis, se futuramente forem criadas:

- `APPMAQ_API_TOKEN=necessaria apenas se a automacao admin por API for autorizada; valor ocultado`
- `APPMAQ_SESSION_COOKIE=necessaria apenas se a automacao admin por sessao for autorizada; valor ocultado`
- `SERPAPI_KEY=nao confirmada; valor ocultado se existir`
- `OPENAI_API_KEY=nao confirmada; valor ocultado se existir`

Nao registrar valores reais dessas variaveis em arquivos do projeto.

## 9. Comandos para rodar o projeto

Comandos usados/planejados, a partir da raiz:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\initialize-research-cache.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\select-next-research-batch.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\build-manual-collection-queue.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\finaliza-valtra4.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\aplica-valtra4-tcvt-scribd.ps1
```

Antes de rodar qualquer script, conferir no proprio script se os caminhos e parametros correspondem ao lote atual.

`git status` e `git log --oneline -5` foram tentados, mas o comando `git` nao esta disponivel no PATH desta sessao. Estado Git: nao confirmado.

## 10. O que ja esta funcionando

- Estrutura de inventario local.
- Regras de coleta economica.
- Comparacao entre modelos solicitados e dados AppMaq.
- Organizacao de lotes Valtra.
- Copia de genericos Valtra para cada modelo.
- Renomeacao padronizada de PDFs.
- Validacao basica/local de PDFs.
- Registro de candidatos, downloads, rejeicoes e status.
- Lotes Valtra 3 e Valtra 4 entregues com PDFs diretos nas pastas dos modelos.

## 11. O que ainda nao esta funcionando

- Upload automatico para o AppMaq ainda nao foi concluido.
- Upload visual no navegador interno ficou bloqueado pelo drawer fora da area clicavel.
- Uso direto da API administrativa ainda depende de token/cookie/sessao autorizada e forma segura de envio.
- Manualslib apresentou bloqueio/fechamento de conexao em pesquisas anteriores.
- DuckDuckGo apresentou anti-bot em pesquisas anteriores.
- Nem todos os modelos possuem documentos especificos disponiveis; alguns contam apenas com genericos.

## 12. Problemas que ja apareceram

- Limite de contexto da conversa.
- Necessidade de economizar creditos.
- Sites com bloqueio anti-bot.
- Links ruins, ruido de busca e resultados de venda/marketplace.
- Risco de misturar modelos parecidos.
- PDFs genericos precisam ser tratados com criterio.
- Drawer do AppMaq admin deslocado no navegador interno.
- Ferramenta de navegador sem `setInputFiles` disponivel para input de arquivo.
- Comando `git` indisponivel no PATH.

## 13. Solucoes ja aplicadas

- Criados protocolos locais para pesquisa economica.
- Criados caches CSV/JSON para nao repetir pesquisa.
- Inventarios foram usados para registrar candidatos, rejeicoes e downloads.
- Valtra 3 e Valtra 4 foram separados como lotes distintos para nao misturar com material anterior do usuario.
- PDFs foram colocados diretamente na raiz das pastas dos modelos.
- Arquivos auxiliares foram mantidos fora das pastas dos modelos.
- Documentos Scribd foram baixados apenas por fluxo autorizado pelo usuario.
- Para o problema do upload AppMaq, foi registrada a rota provavel e o bloqueio tecnico; nenhum upload foi forçado.

## 14. Decisoes tecnicas ja tomadas

- Trabalhar por lotes pequenos para economizar creditos/contexto.
- Usar CSV/JSON como cache central.
- Separar arquivos finais no HD `E:`.
- Manter inventarios no projeto e tambem copiar relatorios importantes para `E:\MANUAIS_APPMAQ\_INVENTARIO`.
- Nao criar subpastas dentro dos modelos.
- Manter somente PDFs nas pastas finais dos modelos.
- Usar nomes de arquivos em maiusculas e descritivos.
- Tratar documentos genericos Valtra como biblioteca separada e aplicar somente quando fizer sentido.
- Criar pasta `MODELO NOVO - <MODELO>` se surgir modelo validado que nao estava na lista original.

## 15. Regras de negocio do projeto

- Nao misturar modelos diferentes.
- Validar documento pelo conteudo sempre que possivel.
- Priorizar documentos gratuitos, oficiais ou autorizados.
- Aceitar apenas portugues, espanhol e ingles.
- Ignorar idiomas pouco uteis no Brasil, salvo autorizacao.
- Separar por marca, lote e modelo.
- Nao trazer link vazio.
- Nao trazer documento que nao corresponda ao modelo ou familia correta.
- Informar quando o link nao for PDF direto.
- Nao aceitar apenas capa, preview inutil ou documento vazio.
- Manter padrao de organizacao definido pelo usuario.
- Nao deixar `.md`, `.csv`, `.json` ou inventario dentro das pastas dos modelos.
- Nao usar link pago externo.
- Login simples pode ser marcado; assinatura paga fora do Scribd autorizado deve ser marcada como `nao compensa`.

## 16. Fontes de busca usadas ou planejadas

Fontes usadas/planejadas:

- Scribd: autorizado pelo usuario usando conta paga dele; baixar apenas por botao oficial.
- Manualslib: planejado/consultado, mas pode bloquear conexao.
- Sites oficiais das marcas, principalmente Valtra/AGCO.
- JSAgro: fonte complementar; se exigir pagamento ou login pesado, marcar conforme regra.
- Bing/busca web: usado para coletar candidatos, com validacao posterior.
- Outras fontes gratuitas/publicas.

Fontes que nao devem ser usadas:

- lojas pagas de manual;
- marketplaces pagos;
- fontes com compra obrigatoria;
- arquivos sem validacao de modelo.

## 17. Criterios de validacao de documentos

Um documento e considerado util quando:

- o modelo exato aparece no conteudo; ou
- a familia/serie aparece claramente e inclui o modelo solicitado; e
- a marca esta correta; e
- o tipo documental e util; e
- o idioma e PT, ES ou EN; e
- o link esta ativo; e
- o arquivo nao esta vazio; e
- nao e apenas capa, propaganda inutil ou preview sem conteudo tecnico; e
- nao ha indicio de modelo parecido incorreto.

Quando o documento cobre varios modelos, aplicar somente aos modelos citados ou explicitamente cobertos.

## 18. Tipos de documentos aceitos

- Manual do Operador.
- Manual de Servico.
- Manual de Oficina.
- Catalogo de Pecas.
- Manual eletrico.
- Esquema eletrico.
- Manual hidraulico.
- Esquema hidraulico.
- Manual de diagnostico.
- Codigos de falhas.
- Boletim tecnico.
- Manual de manutencao.
- Ficha tecnica.
- Especificacoes tecnicas.
- Guia rapido.
- Manual de monitor, GPS, AFS, ISOBUS ou equivalente.
- Apostila de treinamento.
- Documento complementar util.
- Documento parcial util, desde que validado e nomeado claramente.

## 19. Arquivos que nao devem ser alterados sem cuidado

- `CONFIGURACAO_COLETA_USUARIO.md`
- `PROTOCOLO_PESQUISA_ECONOMICA_MANUAIS.md`
- `Inventario_APPMAQ\Pesquisa_Cache\manifesto_cache.json`
- `Inventario_APPMAQ\Pesquisa_Cache\*.csv`
- `Inventario_APPMAQ\appmaq_admin_*.json`
- `Inventario_APPMAQ\appmaq_admin_*.csv`
- `scripts\*.ps1`
- Qualquer futuro `.env`
- Pastas finais em `E:\MANUAIS_APPMAQ\...`

## 20. Pontos de atencao

- Consumo alto de creditos se pesquisar modelos em massa sem cache.
- Janela de contexto cheia.
- Leitura desnecessaria de arquivos grandes.
- Links falsos, quebrados ou pagos.
- Mistura de modelos parecidos.
- Documentos pagos ou com restricao de redistribuicao.
- Conteudo sem validacao interna.
- Risco de upload incorreto no AppMaq.
- Possiveis questoes de direitos autorais ao subir documentos de terceiros para o AppMaq; responsabilidade deve ser confirmada pelo usuario.
- Estado Git nao confirmado porque `git` nao estava disponivel no PATH.

## 21. Proximo passo recomendado

O proximo passo mais seguro e iniciar uma nova conversa lendo estes quatro arquivos de continuidade e, antes de qualquer alteracao, decidir com o usuario qual caminho seguir para o upload AppMaq:

1. preparar um manifest/CSV do modelo `A800C` com os 4 PDFs e nomes;
2. testar upload manual assistido no painel, se o usuario conseguir deixar o drawer visivel;
3. ou automatizar via API administrativa somente se o usuario fornecer/autoriziar uma forma segura de sessao/token temporario, sem expor credenciais em arquivos.

Nao continuar a pesquisa nem o upload automaticamente antes dessa confirmacao.

## 22. Resumo tecnico curto

Projeto PowerShell/CSV/JSON para coleta e organizacao de manuais AppMaq. Lotes Valtra 3 e Valtra 4 foram montados em `E:\MANUAIS_APPMAQ\Trator Agricola`, com PDFs diretos nas pastas dos modelos. Caches e relatorios ficam em `Inventario_APPMAQ`. Upload AppMaq foi estudado, mas nao executado; endpoint batch foi inferido do frontend e precisa validacao segura.

## 23. Resumo operacional para o usuario

O trabalho atual deixou os PDFs dos lotes Valtra organizados no HD `E:` do jeito combinado: cada modelo com PDFs direto dentro da pasta. Tambem ficou documentado como pesquisar sem gastar creditos a toa, quais fontes usar, como validar documentos e quais relatorios guardar.

O ponto que ainda precisa ser resolvido e a subida automatica para o AppMaq. O teste com A800C nao alterou nada no site porque o navegador interno nao conseguiu operar corretamente a janela de upload. A nova conversa pode continuar lendo estes arquivos, sem depender do historico antigo do chat.
