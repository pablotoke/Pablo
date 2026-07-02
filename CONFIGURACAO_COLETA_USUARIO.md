# Configuracao de coleta - AppMaq manuais

## Regra atual do usuario

Data: 2026-07-01

O pacote enviado `TRATORES AGRICOLAS VALTRA 2-20260701T123625Z-3-001.zip` deve ser tratado como exemplo de organizacao, nomes de arquivos e padrao de classificacao.

Os modelos desse exemplo, da serie A52S ate M205, ja foram feitos pelo usuario.

## Regra para proximos modelos Valtra

- Nao misturar novos arquivos dentro da pasta existente:
  - `E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA`
- Criar/usar uma pasta separada para o novo lote:
  - `E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA 3`
- Dentro de `VALTRA 3`, criar pasta do modelo quando o usuario enviar a lista do lote e pedir os genericos em todos os modelos.
- Nao criar subpastas vazias.
- Dentro da pasta de cada modelo, deixar os PDFs diretamente na raiz do modelo.
- Nao criar subpastas por tipo de documento como `01_manual_operador`, `02_manual_servico_oficina` ou `06_boletim_treinamento_diagnostico` nos proximos lotes, salvo se o usuario pedir explicitamente.
- Nao deixar arquivos Markdown (`.md`) dentro das pastas dos modelos.
- As pastas dos modelos devem conter somente PDFs encontrados/validados. Links, fontes, observacoes e rastreabilidade ficam apenas no cache/inventario.
- Renomear todos os PDFs antes de colocar na pasta do modelo.
- O nome do PDF deve ficar em letras maiusculas, descritivo e pronto para cadastro no AppMaq.
- Nao usar nomes baixados automaticamente com `_`, codigo solto, fonte/site (`Scribd`, `Manualslib`, etc.) ou texto baguncado.
- Exemplos de padrao:
  - `MANUAL DO OPERADOR DOS TRATORES VALTRA BT150 BT170 BT190 BT210.pdf`
  - `MANUAL DE SERVIÇO DOS TRATORES VALTRA A800R A850R A950R A990R.pdf`
  - `CATÁLOGO DE PEÇAS DO SISTEMA ELÉTRICO DO TRATOR VALTRA BT210.pdf`
- Usar os nomes e classificacoes do ZIP enviado como referencia de padrao.
- Nao misturar modelos parecidos.
- Manter cache local antes de pesquisar.

## Modelos encontrados que nao estavam na lista

Durante a pesquisa, pode aparecer documento que cobre modelos relacionados que o usuario nao enviou na lista inicial ou que podem nao estar cadastrados no AppMaq.

Regra:

- Se o documento validar claramente um modelo novo da mesma familia/serie, criar pasta separada para esse modelo dentro do lote atual.
- O nome da pasta deve indicar que nao foi solicitado originalmente:
  - `MODELO NOVO - <MODELO>`
- Exemplo:
  - se o usuario pediu `T210 CVT`, mas o documento tambem cobre `T230 CVT` e `T250 CVT`, criar:
    - `MODELO NOVO - T230 CVT`
    - `MODELO NOVO - T250 CVT`
- Dentro dessas pastas, manter o mesmo padrao dos demais modelos:
  - somente PDFs diretamente na raiz da pasta;
  - sem subpastas;
  - sem Markdown, CSV, JSON ou inventario;
  - PDFs renomeados em letras maiusculas e descritivos.
- Registrar no inventario que o modelo foi encontrado durante a pesquisa e nao veio na lista original.
- Nao criar pasta de modelo novo quando o documento apenas menciona numero parecido ou familia parecida sem confirmar o modelo.

## Tipos de documentos solicitados

Pesquisar e aceitar, quando houver documento validavel para o modelo ou serie correta:

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

## Documentos genericos Valtra aprovados pelo usuario

Data: 2026-07-01

O usuario informou que alguns PDFs genericos Valtra/Valmet podem ser acrescentados em todos os modelos Valtra quando fizer sentido, principalmente catalogos/folhetos/manuais gerais de tratores Valtra.

Biblioteca local:

- `E:\MANUAIS_APPMAQ\_GENERICOS\VALTRA`

Arquivos genericos atuais:

- `CATALOGO DE PEÇAS DOS TRATORES VALTRA-VALMET.pdf`
- `FOLHETO COM  INFORMAÇÕES SOBRE ECONOMIA DE COMBUSTÍVEL, CONFORTO, VERSATILIDADE E TECNOLOGIA AVANÇADA DE TODOS TRATORES VALTRA..pdf`
- `MANUAL COM INSTRUÇÕES PARA TRATORES VALTRA.pdf`
- `MANUAL COM INSTRUÇÕES SOBRE OPERAÇÃO, MANUTENÇÃO E SEGURANÇA PARA TRATORES VALTRA.pdf`

Regra de uso:

- Nos proximos lotes Valtra, copiar esses PDFs genericos diretamente para a raiz da pasta de cada modelo, junto com os PDFs especificos encontrados.
- Nao criar subpastas por tipo de documento.
- Nao copiar arquivos Markdown para a pasta do modelo.
- Quando encontrar outros documentos genericos Valtra durante a pesquisa, validar pelo conteudo e registrar como generico antes de aplicar aos modelos.
- Se o documento generico for muito amplo ou duvidoso para uma serie especifica, manter na biblioteca generica e registrar como candidato, sem aplicar automaticamente.

## Observacao

Nao mover, apagar ou reorganizar arquivos ja existentes na pasta `VALTRA` sem confirmacao explicita do usuario.
