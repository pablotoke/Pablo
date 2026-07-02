# AGENTS.md

Instrucoes permanentes para futuras sessoes do Codex neste projeto.

## Objetivo geral

Este projeto organiza a coleta, validacao, renomeacao e separacao de manuais tecnicos de maquinas agricolas para posterior cadastro no AppMaq.

O foco atual e trabalhar com tratores agricolas, principalmente Valtra, criando pastas por marca/lote/modelo e colocando dentro de cada modelo apenas PDFs validados e renomeados em padrao adequado para anexar no AppMaq.

## Como o Codex deve trabalhar neste repositorio

- Antes de alterar qualquer coisa, ler primeiro estes arquivos de continuidade:
  1. `AGENTS.md`
  2. `CHECKPOINT_Codex.md`
  3. `TODO_Codex.md`
  4. `CONTINUIDADE_NOVA_SESSAO.md`
- Depois disso, ler somente os arquivos principais citados no checkpoint e apenas as partes necessarias.
- Preservar a logica que ja esta funcionando.
- Manter o padrao atual do projeto, dos scripts, inventarios e nomes de pastas.
- Verificar os arquivos principais antes de alterar scripts, configuracoes ou inventarios.
- Explicar antes de fazer mudancas grandes.
- Nao remover codigo funcional sem justificativa clara.
- Nao apagar arquivos, nao resetar historico e nao reorganizar estrutura sem autorizacao do usuario.
- Informar claramente quais arquivos foram criados ou alterados.
- Registrar decisoes importantes no `CHECKPOINT_Codex.md`.
- Atualizar o `TODO_Codex.md` quando concluir uma tarefa.

## Economia de creditos

- Trabalhar em lotes pequenos.
- Antes de pesquisar na internet, consultar caches locais JSON/CSV.
- Nao abrir todos os links encontrados; primeiro coletar candidatos provaveis.
- Validar somente os melhores candidatos.
- Priorizar fontes ja conhecidas e relatorios locais.
- Nao repetir pesquisas ja registradas em inventario.
- Evitar leitura de arquivos grandes quando uma amostra ou resumo resolver.

## Economia de janela de contexto

- Nao reler o projeto inteiro sem necessidade.
- Preferir `rg --files`, `rg`, `Get-ChildItem` e consultas pontuais.
- Ler arquivos grandes em partes relevantes.
- Resumir resultados operacionais em inventarios e checkpoints.
- Se algo nao puder ser confirmado, marcar como `nao confirmado`.

## Seguranca e dados sensiveis

- Nao expor chaves, tokens, cookies, senhas ou valores reais de `.env`.
- Se for necessario falar de variaveis de ambiente, mostrar apenas o nome e marcar o valor como oculto.
- Usar a conta do usuario somente quando ele autorizar explicitamente.
- Nao burlar paywall, protecao tecnica, DRM ou restricao de acesso.
- Downloads do Scribd devem ocorrer apenas por botoes oficiais e conta autorizada do usuario.

## Regras de negocio importantes

- Nao misturar modelos diferentes.
- Validar documento pelo conteudo sempre que possivel, nao apenas pelo nome do arquivo.
- Aceitar somente PT, ES e EN.
- Ignorar idiomas pouco uteis no Brasil, como russo, arabe, chines e polones, salvo autorizacao.
- Priorizar documentos gratuitos, oficiais ou de fontes autorizadas pelo usuario.
- Dentro da pasta de cada modelo deve haver somente PDFs diretos, sem subpastas, Markdown, CSV, JSON ou inventario.
- PDFs devem ser renomeados em maiusculas, com nome descritivo.
- Relatorios, fontes, links e rastreabilidade ficam no inventario central, nao dentro da pasta do modelo.

## Como iniciar uma nova sessao

Uma nova sessao deve ler primeiro:

1. `AGENTS.md`
2. `CHECKPOINT_Codex.md`
3. `TODO_Codex.md`
4. `CONTINUIDADE_NOVA_SESSAO.md`
5. Somente depois os arquivos principais citados no checkpoint

Depois de ler, a nova sessao deve responder com:

- o que entendeu do projeto;
- o estado atual;
- o proximo passo mais seguro;
- quais arquivos precisam ser analisados antes de continuar;
- sem alterar nada automaticamente.

