param(
  [string]$Workspace = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($Workspace)) {
  $Workspace = (Resolve-Path -Path (Join-Path $PSScriptRoot "..")).Path
}

$tmp = Join-Path $Workspace "tmp\bing_valtra4"
$outDir = Join-Path $Workspace "Inventario_APPMAQ\Lotes_Usuario"
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$queries = New-Object System.Collections.Generic.List[string]
$queries.Add("Valtra Q265 Q285 Q305 operator manual PDF")
$queries.Add("Valtra Q265 Q285 Q305 parts catalog PDF")
$queries.Add("Valtra Q265 Q285 Q305 workshop service manual PDF")
$queries.Add("Valtra Q5 electrical schematic diagnostic fault codes PDF")
$queries.Add("Valtra Q5 hydraulic schematic PDF")
$queries.Add("Valtra S346 S376 S416 operator manual PDF")
$queries.Add("Valtra S346 S376 S416 parts catalog PDF")
$queries.Add("Valtra S346 S376 S416 workshop service manual PDF")
$queries.Add("Valtra S6 electrical schematic diagnostic fault codes PDF")
$queries.Add("Valtra S6 hydraulic schematic PDF")
$queries.Add("Valtra T195 CVT T210 CVT T230 CVT T250 CVT operator manual PDF")
$queries.Add("Valtra T195 CVT T210 CVT T230 CVT T250 CVT parts catalog PDF")
$queries.Add("Valtra T195 CVT T210 CVT T230 CVT T250 CVT workshop service manual PDF")
$queries.Add("Valtra T CVT electrical schematic diagnostic fault codes PDF")
$queries.Add("Valtra T CVT hydraulic schematic PDF")
$queries.Add("site:scribd.com Valtra Q5 Q265 manual")
$queries.Add("site:scribd.com Valtra S6 S346 manual")
$queries.Add("site:scribd.com Valtra T CVT T195 manual")
$queries.Add("site:manualslib.com Valtra Q265 manual")
$queries.Add("site:manualslib.com Valtra S346 manual")
$queries.Add("site:manualslib.com Valtra T195 CVT manual")

$rows = New-Object System.Collections.Generic.List[object]
$ua = "Mozilla/5.0 manual-research"

foreach ($query in $queries) {
  $url = "https://www.bing.com/search?q=$([System.Uri]::EscapeDataString($query))"
  $safe = ($query -replace "[^A-Za-z0-9]+", "_").Trim("_")
  if ($safe.Length -gt 80) { $safe = $safe.Substring(0, 80) }
  $htmlPath = Join-Path $tmp "$safe.html"
  try {
    Invoke-WebRequest -Uri $url -UseBasicParsing -Headers @{ "User-Agent" = $ua } -OutFile $htmlPath
    $html = Get-Content -Raw -Path $htmlPath
    $matches = [regex]::Matches($html, '<li class="b_algo".*?</li>', "Singleline")
    $rank = 0
    foreach ($m in $matches) {
      $rank++
      $block = $m.Value
      $link = [regex]::Match($block, '<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', "Singleline")
      if (-not $link.Success) { continue }
      $snippet = [regex]::Match($block, '<p>(.*?)</p>', "Singleline")
      $title = [System.Net.WebUtility]::HtmlDecode(([regex]::Replace($link.Groups[2].Value, '<.*?>', '')).Trim())
      $href = [System.Net.WebUtility]::HtmlDecode($link.Groups[1].Value)
      $text = if ($snippet.Success) { [System.Net.WebUtility]::HtmlDecode(([regex]::Replace($snippet.Groups[1].Value, '<.*?>', '')).Trim()) } else { "" }
      $rows.Add([pscustomobject]@{
        data_pesquisa = (Get-Date).ToString("s")
        lote = "VALTRA 4"
        consulta = $query
        rank = $rank
        titulo = $title
        url = $href
        resumo = $text
        status = "candidato_nao_validado"
      })
    }
    if ($matches.Count -eq 0) {
      $rows.Add([pscustomobject]@{
        data_pesquisa = (Get-Date).ToString("s")
        lote = "VALTRA 4"
        consulta = $query
        rank = 0
        titulo = "SEM RESULTADO EXTRAIDO"
        url = $htmlPath
        resumo = ""
        status = "sem_resultado_extraido"
      })
    }
    Start-Sleep -Milliseconds 500
  } catch {
    $rows.Add([pscustomobject]@{
      data_pesquisa = (Get-Date).ToString("s")
      lote = "VALTRA 4"
      consulta = $query
      rank = 0
      titulo = "ERRO NA BUSCA"
      url = $_.Exception.Message
      resumo = ""
      status = "erro_busca"
    })
  }
}

$csv = Join-Path $outDir "candidatos_valtra4_bing_busca_ampliada_2026-07-02.csv"
$rows | Export-Csv -Path $csv -NoTypeInformation -Encoding UTF8

$rows |
  Where-Object { $_.status -eq "candidato_nao_validado" } |
  Sort-Object consulta,rank |
  Select-Object consulta,rank,titulo,url |
  Format-Table -AutoSize

Write-Host "CSV: $csv"
