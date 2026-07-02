param(
  [string]$Workspace = "",
  [string]$Downloads = "C:\Users\Pablo Henrique\Downloads",
  [string]$Base = "E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA 4"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Workspace)) {
  $Workspace = (Resolve-Path -Path (Join-Path $PSScriptRoot "..")).Path
}

$cache = Join-Path $Workspace "Inventario_APPMAQ\Pesquisa_Cache\downloads_documentos.csv"
$lotDir = Join-Path $Workspace "Inventario_APPMAQ\Lotes_Usuario"
New-Item -ItemType Directory -Force -Path $lotDir | Out-Null

$allTcvtModels = @("T195 CVT", "T210 CVT", "T230 CVT", "T250 CVT")
$tcvtExceptT195 = @("T210 CVT", "T230 CVT", "T250 CVT")

$docs = @(
  [pscustomobject]@{
    Source = Join-Path $Downloads "665109210-Valtra-t-Cvt.pdf"
    FileName = "MANUAL DE SERVICO DOS TRATORES VALTRA T195 CVT T210 CVT T230 CVT T250 CVT.pdf"
    Models = $allTcvtModels
    Tipo = "manual_servico"
    Url = "https://pt.scribd.com/document/665109210/Valtra-t-Cvt"
    Pages = 41
    Observacao = "Validado localmente: capa e conteudo citam T195 CVT, T210 CVT, T230 CVT e T250 CVT."
  },
  [pscustomobject]@{
    Source = Join-Path $Downloads "604697701-Sistema-Eletrico-Serie-T-CVT.pdf"
    FileName = "TREINAMENTO DO SISTEMA ELETRICO DOS TRATORES VALTRA SERIE T CVT.pdf"
    Models = $allTcvtModels
    Tipo = "esquema_eletrico_treinamento"
    Url = "https://pt.scribd.com/document/604697701/Sistema-Eletrico-Serie-T-CVT"
    Pages = 404
    Observacao = "Validado localmente: documento cita Treinamento Sistema Eletrico Serie T CVT."
  },
  [pscustomobject]@{
    Source = Join-Path $Downloads "724320652-Apostila-Sistema-Eletrico-Serie-T-CVT-Rev01-23102017.pdf"
    FileName = "APOSTILA DO SISTEMA ELETRICO DOS TRATORES VALTRA SERIE T CVT.pdf"
    Models = $allTcvtModels
    Tipo = "esquema_eletrico_treinamento"
    Url = "https://pt.scribd.com/document/724320652/Apostila-Sistema-Eletrico-Serie-T-CVT-Rev01-23102017"
    Pages = 372
    Observacao = "Validado localmente: apostila cita Sistemas Eletricos Trator Serie T CVT."
  },
  [pscustomobject]@{
    Source = Join-Path $Downloads "665108506-VALTRA-T-CVT-livro-de-servico.pdf"
    FileName = "LIVRO DE SERVICO TECNICO COM CODIGOS DE ERRO E DIAGRAMAS DOS TRATORES VALTRA T195 CVT T210 CVT T230 CVT T250 CVT.pdf"
    Models = $allTcvtModels
    Tipo = "manual_diagnostico_esquemas"
    Url = "https://pt.scribd.com/document/665108506/VALTRA-T-CVT-livro-de-servico"
    Pages = 41
    Observacao = "Validado localmente: cita T195 CVT, T210 CVT, T230 CVT e T250 CVT; inclui codigos de erro, diagramas eletricos, hidraulicos e pneumaticos."
  },
  [pscustomobject]@{
    Source = Join-Path $Downloads "461042812-FALHAS-CVT.pdf"
    FileName = "CODIGOS DE FALHAS DOS TRATORES VALTRA SERIE T CVT T190 T210 T230 T250.pdf"
    Models = $tcvtExceptT195
    Tipo = "codigos_falhas"
    Url = "https://pt.scribd.com/document/461042812/FALHAS-CVT"
    Pages = 48
    Observacao = "Validado localmente: documento cita Trator Serie T CVT T190, T210, T230 e T250. Nao aplicado ao T195 CVT por nao citar esse modelo."
  },
  [pscustomobject]@{
    Source = Join-Path $Downloads "635020696-VALTRA-CVT.pdf"
    FileName = "TREINAMENTO DE COMPONENTES ELETRICOS DO SISTEMA CVT DOS TRATORES VALTRA SERIE T CVT.pdf"
    Models = $allTcvtModels
    Tipo = "esquema_eletrico_diagnostico"
    Url = "https://pt.scribd.com/document/635020696/VALTRA-CVT"
    Pages = 287
    Observacao = "Validado localmente: documento cita Componentes Eletricos e Treinamento Sistema Eletrico Serie T CVT."
  },
  [pscustomobject]@{
    Source = Join-Path $Downloads "518804997-T195-T210-T230-T250-SERIE-T-CVT.pdf"
    FileName = "PLANO DE MANUTENCAO DOS TRATORES VALTRA T195 CVT T210 CVT T230 CVT T250 CVT.pdf"
    Models = $allTcvtModels
    Tipo = "manual_manutencao"
    Url = "https://pt.scribd.com/document/518804997/T195-T210-T230-T250-SERIE-T-CVT"
    Pages = 2
    Observacao = "Validado localmente: documento cita T195, T210, T230 e T250 Serie T CVT."
  }
)

$rows = @()
foreach ($doc in $docs) {
  if (-not (Test-Path -Path $doc.Source -PathType Leaf)) {
    throw "Arquivo fonte ausente: $($doc.Source)"
  }
  $item = Get-Item -Path $doc.Source
  $hash = (Get-FileHash -Path $doc.Source -Algorithm SHA256).Hash.ToLowerInvariant()

  foreach ($model in $doc.Models) {
    $destDir = Join-Path $Base $model
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    $dest = Join-Path $destDir $doc.FileName
    Copy-Item -Path $doc.Source -Destination $dest -Force
    $rows += [pscustomobject]@{
      data_download = (Get-Date).ToString("s")
      batch_id = "valtra4_scribd_t_cvt_busca_ampliada_20260702"
      marca = "VALTRA"
      modelo = $model
      tipo_documento = $doc.Tipo
      fonte = "Scribd"
      url = $doc.Url
      arquivo_local = $dest
      tamanho_bytes = $item.Length
      paginas = $doc.Pages
      sha256 = $hash
      status = "validado_conteudo"
      observacao = $doc.Observacao
    }
  }
}

if ($rows.Count -gt 0) {
  if (Test-Path -Path $cache -PathType Leaf) {
    $rows | Export-Csv -Path $cache -NoTypeInformation -Encoding UTF8 -Append
  } else {
    $rows | Export-Csv -Path $cache -NoTypeInformation -Encoding UTF8
  }
}

$models = @(
  "Q265","Q285","Q305",
  "S263","S274","S324","S346","S353","S374","S376","S394","S396","S416",
  "T195 CVT","T210 CVT","T230 CVT","T250 CVT"
)

$statusRows = foreach ($model in $models) {
  $dir = Join-Path $Base $model
  [pscustomobject]@{
    modelo = $model
    total_pdfs = @(Get-ChildItem -Path $dir -File -Filter "*.pdf").Count
    total_subpastas = @(Get-ChildItem -Path $dir -Directory).Count
    total_arquivos_nao_pdf = @(Get-ChildItem -Path $dir -File | Where-Object { $_.Extension -ne ".pdf" }).Count
  }
}

$deltaCsv = Join-Path $lotDir "valtra4_t_cvt_documentos_scribd_adicionados_2026-07-02.csv"
$statusCsv = Join-Path $lotDir "status_lote_valtra_4_atualizado_2026-07-02.csv"
$rows | Export-Csv -Path $deltaCsv -NoTypeInformation -Encoding UTF8
$statusRows | Export-Csv -Path $statusCsv -NoTypeInformation -Encoding UTF8

$inventoryDest = "E:\MANUAIS_APPMAQ\_INVENTARIO\Lotes_Usuario"
New-Item -ItemType Directory -Force -Path $inventoryDest | Out-Null
Copy-Item -Path $deltaCsv,$statusCsv -Destination $inventoryDest -Force

$statusRows | Sort-Object modelo | Format-Table -AutoSize
