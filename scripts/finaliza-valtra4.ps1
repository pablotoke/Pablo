param(
  [string]$Workspace = "",
  [string]$Base = "E:\MANUAIS_APPMAQ\Trator Agricola\VALTRA 4"
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Workspace)) {
  $Workspace = (Resolve-Path -Path (Join-Path $PSScriptRoot "..")).Path
}

$tmp = Join-Path $Workspace "tmp\valtra4_oficiais"
$cache = Join-Path $Workspace "Inventario_APPMAQ\Pesquisa_Cache\downloads_documentos.csv"
$lotDir = Join-Path $Workspace "Inventario_APPMAQ\Lotes_Usuario"
New-Item -ItemType Directory -Force -Path $lotDir | Out-Null

$allModels = @(
  "Q265","Q285","Q305",
  "S263","S274","S324","S346","S353","S374","S376","S394","S396","S416",
  "T195 CVT","T210 CVT","T230 CVT","T250 CVT"
)

$docs = @(
  [pscustomobject]@{
    Source = Join-Path $tmp "q5_folheto_completo.pdf"
    FileName = "FOLHETO COMPLETO DOS TRATORES VALTRA SERIE Q5 Q265 Q285 Q305.pdf"
    Models = @("Q265","Q285","Q305")
    Tipo = "ficha_tecnica_folheto"
    Url = "https://www.valtra.com.br/content/dam/public/valtra/pt-br/produtos/tratores/serie-q5/folheto_TratorQ5_web_simples.pdf"
    Pages = 24
    Validation = "Texto interno cita Q265, Q285 e Q305."
  },
  [pscustomobject]@{
    Source = Join-Path $tmp "q5_folheto_resumido.pdf"
    FileName = "FOLHETO RESUMIDO DOS TRATORES VALTRA SERIE Q5 Q265 Q285 Q305.pdf"
    Models = @("Q265","Q285","Q305")
    Tipo = "ficha_tecnica_folheto"
    Url = "https://www.valtra.com.br/content/dam/public/valtra/pt-br/produtos/tratores/q5/AF_Folheto_SerieQ5%20A4-WEB.pdf"
    Pages = 2
    Validation = "Texto interno cita Q265, Q285 e Q305."
  },
  [pscustomobject]@{
    Source = Join-Path $tmp "s6_folheto_completo.pdf"
    FileName = "FOLHETO COMPLETO DOS TRATORES VALTRA SERIE S6 S346 S376 S416.pdf"
    Models = @("S346","S376","S416")
    Tipo = "ficha_tecnica_folheto"
    Url = "https://www.valtra.com.br/content/dam/public/valtra/pt-br/produtos/tratores/serie-s6/FOLHETAO_SERIE_S6.pdf"
    Pages = 20
    Validation = "Texto interno cita S346, S376 e S416."
  },
  [pscustomobject]@{
    Source = Join-Path $tmp "s6_folheto_resumido.pdf"
    FileName = "FOLHETO RESUMIDO DOS TRATORES VALTRA SERIE S6 S346 S376 S416.pdf"
    Models = @("S346","S376","S416")
    Tipo = "ficha_tecnica_folheto"
    Url = "https://www.valtra.com.br/content/dam/public/valtra/pt-br/produtos/tratores/serie-s6/AF_VAL_1947_3_FOLHETO%20S6%20-%2059,4x21cm%20web%20pg%20simples.pdf"
    Pages = 4
    Validation = "Texto interno cita S346, S376 e S416."
  },
  [pscustomobject]@{
    Source = Join-Path $tmp "t_cvt_folheto_2026.pdf"
    FileName = "FOLHETO DOS TRATORES VALTRA T195 CVT T210 CVT T230 CVT T250 CVT.pdf"
    Models = @("T195 CVT","T210 CVT","T230 CVT","T250 CVT")
    Tipo = "ficha_tecnica_folheto"
    Url = "https://www.valtra.com.br/content/dam/public/valtra/pt-br/produtos/tratores/tcvt/AF_Folheto%20TRATOR%20T%20CVT%20MAR%202026_29,7x21cm_WEB.pdf"
    Pages = 2
    Validation = "Texto interno cita T195 CVT, T210 CVT, T230 CVT e T250 CVT."
  }
)

foreach ($model in $allModels) {
  New-Item -ItemType Directory -Force -Path (Join-Path $Base $model) | Out-Null
}

$downloadRows = @()
foreach ($doc in $docs) {
  if (-not (Test-Path -Path $doc.Source -PathType Leaf)) {
    throw "Arquivo fonte ausente: $($doc.Source)"
  }

  $srcItem = Get-Item -Path $doc.Source
  $hash = (Get-FileHash -Path $doc.Source -Algorithm SHA256).Hash.ToLowerInvariant()

  foreach ($model in $doc.Models) {
    $destPath = Join-Path (Join-Path $Base $model) $doc.FileName
    Copy-Item -Path $doc.Source -Destination $destPath -Force

    $downloadRows += [pscustomobject]@{
      data_download = (Get-Date).ToString("s")
      batch_id = "valtra4_oficial_valtra_20260702"
      marca = "VALTRA"
      modelo = $model
      tipo_documento = $doc.Tipo
      fonte = "Site oficial Valtra"
      url = $doc.Url
      arquivo_local = $destPath
      tamanho_bytes = $srcItem.Length
      paginas = $doc.Pages
      sha256 = $hash
      status = "validado_conteudo"
      observacao = $doc.Validation
    }
  }
}

if ($downloadRows.Count -gt 0) {
  if (Test-Path -Path $cache -PathType Leaf) {
    $downloadRows | Export-Csv -Path $cache -NoTypeInformation -Encoding UTF8 -Append
  } else {
    $downloadRows | Export-Csv -Path $cache -NoTypeInformation -Encoding UTF8
  }
}

$statusRows = foreach ($model in $allModels) {
  $modelDir = Join-Path $Base $model
  $pdfCount = @(Get-ChildItem -Path $modelDir -File -Filter "*.pdf").Count
  $subfolderCount = @(Get-ChildItem -Path $modelDir -Directory).Count
  $nonPdfCount = @(Get-ChildItem -Path $modelDir -File | Where-Object { $_.Extension -ne ".pdf" }).Count
  $specificDocs = @($docs | Where-Object { $_.Models -contains $model } | ForEach-Object { $_.FileName })
  [pscustomobject]@{
    modelo = $model
    pasta = $modelDir
    total_pdfs = $pdfCount
    documentos_especificos_adicionados = ($specificDocs -join " | ")
    total_documentos_especificos_adicionados = $specificDocs.Count
    total_subpastas = $subfolderCount
    total_arquivos_nao_pdf = $nonPdfCount
  }
}

$csvOut = Join-Path $lotDir "status_lote_valtra_4_2026-07-02.csv"
$mdOut = Join-Path $lotDir "status_lote_valtra_4_2026-07-02.md"
$statusRows | Export-Csv -Path $csvOut -NoTypeInformation -Encoding UTF8

$lines = @()
$lines += "# Status do lote VALTRA 4 - 2026-07-02"
$lines += ""
$lines += "Pasta entregue: $Base"
$lines += ""
$lines += "| Modelo | Total PDFs | Especificos adicionados | Subpastas | Nao PDFs |"
$lines += "|---|---:|---|---:|---:|"
foreach ($row in $statusRows) {
  $specific = if ([string]::IsNullOrWhiteSpace($row.documentos_especificos_adicionados)) { "Somente genericos validados pelo usuario" } else { $row.documentos_especificos_adicionados }
  $lines += "| $($row.modelo) | $($row.total_pdfs) | $specific | $($row.total_subpastas) | $($row.total_arquivos_nao_pdf) |"
}
$lines += ""
$lines += "Observacao: os folhetos S6 oficiais foram aplicados somente em S346, S376 e S416 porque foram os modelos confirmados no texto dos PDFs."
Set-Content -Path $mdOut -Value $lines -Encoding UTF8

$inventoryDest = "E:\MANUAIS_APPMAQ\_INVENTARIO\Lotes_Usuario"
New-Item -ItemType Directory -Force -Path $inventoryDest | Out-Null
Copy-Item -Path $csvOut,$mdOut -Destination $inventoryDest -Force

$statusRows | Sort-Object modelo | Format-Table modelo,total_pdfs,total_documentos_especificos_adicionados,total_subpastas,total_arquivos_nao_pdf -AutoSize
