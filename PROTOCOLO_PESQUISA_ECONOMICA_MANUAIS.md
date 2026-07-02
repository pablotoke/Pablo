# Protocolo de pesquisa economica de manuais

Objetivo: coletar documentacao tecnica de maquinas agricolas economizando buscas, cliques e retrabalho.

## Tipos de documentos prioritarios

Procurar, quando existirem na internet, os seguintes tipos de documentos:

- catalogo de pecas;
- manual de servicos / oficina;
- manual de operador;
- esquemas eletricos;
- manual de diagnosticos;
- especificacoes tecnicas;
- esquemas hidraulicos;
- codigos de falhas;
- manual de manutencao;
- boletim tecnico, treinamento ou documento complementar util.

## Regras obrigatorias

1. Trabalhar em lotes pequenos.
2. Antes de pesquisar, verificar cache local em JSON/CSV.
3. Nao abrir todos os links encontrados.
4. Primeiro salvar apenas candidatos provaveis.
5. Validar somente os melhores links.
6. Pesquisar primeiro em Scribd e ManualsLib.
7. Depois usar sites oficiais da marca, JSAgro e outras fontes gratuitas.
8. Nao usar links pagos.
9. Login simples pode ser marcado como aceitavel; assinatura paga deve ser marcada como "nao compensa".
10. Aceitar somente PT, ES e EN.
11. Ignorar russo, arabe, chines, polones e idiomas pouco uteis no Brasil.
12. Validar pelo conteudo do documento, nao so pelo nome do arquivo.
13. Nao misturar modelos parecidos.
14. Salvar todos os candidatos, validacoes, rejeicoes e downloads em arquivo local.

## Ordem de trabalho por lote

1. Selecionar lote pequeno da fila central.
2. Verificar se o item ja existe em:
   - `Inventario_APPMAQ\Pesquisa_Cache\candidatos_documentos.csv`
   - `Inventario_APPMAQ\Pesquisa_Cache\validacoes_documentos.csv`
   - `Inventario_APPMAQ\Pesquisa_Cache\downloads_documentos.csv`
   - `Inventario_APPMAQ\Pesquisa_Cache\rejeitados_documentos.csv`
3. Se ja existir resultado util, nao pesquisar de novo.
4. Buscar candidatos primeiro em Scribd e ManualsLib.
5. Salvar candidatos sem abrir todos os links.
6. Pontuar candidatos por aderencia de modelo, tipo de documento, idioma e fonte.
7. Abrir somente os melhores candidatos.
8. Validar o conteudo interno do documento:
   - marca correta;
   - modelo exato ou serie explicitamente compatível;
   - tipo documental correto;
   - idioma aceito;
   - acesso gratuito, login simples ou Scribd permitido;
   - sem paywall pago externo.
9. Baixar somente por botao/link oficial da fonte.
10. Salvar dentro da pasta do modelo apenas quando houver documento real ou link forte.
11. Registrar download, hash, paginas, fonte e observacao.

## Modelos relacionados nao solicitados

Se a pesquisa encontrar documento validado para modelo relacionado que nao estava na lista original do lote:

- criar pasta no lote com o padrao `MODELO NOVO - <MODELO>`;
- copiar apenas PDFs validados diretamente nessa pasta;
- nao criar subpastas nem arquivos auxiliares dentro dela;
- registrar no inventario que o modelo foi encontrado na pesquisa e nao constava na lista original;
- nao aplicar essa regra quando houver apenas semelhanca de nome, numero ou serie sem confirmacao no conteudo do documento.

## Status padrao

- `pendente`: item ainda sem pesquisa.
- `candidato`: link salvo, ainda nao validado.
- `validado`: conteudo conferido e aprovado.
- `baixado`: arquivo salvo e validado localmente.
- `rejeitado`: link descartado por idioma, modelo errado, pago, ruim ou duplicado.
- `nao_compensa`: fonte exige assinatura/compra fora do que foi autorizado.

## Idiomas

Aceitar:
- PT
- ES
- EN

Rejeitar:
- RU
- AR
- ZH
- PL
- outros idiomas pouco uteis no Brasil, exceto se o usuario pedir.

## Fontes

Prioridade:
1. Scribd
2. ManualsLib
3. Site oficial da marca
4. JSAgro
5. Outras fontes gratuitas/publicas

Nao usar:
- loja paga de manual;
- marketplace pago;
- link que exige compra;
- assinatura paga fora do Scribd ja autorizado;
- arquivo sem modelo validavel.

## Pastas dos modelos

Nao criar subpasta vazia.

Criar subpasta somente quando existir:
- PDF baixado;
- link forte validado;
- documento complementar util;
- ficha tecnica relevante.

Relatorios gerais, candidatos ainda nao validados e fontes pendentes ficam no inventario central.
